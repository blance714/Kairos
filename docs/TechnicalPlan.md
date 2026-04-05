# Kairos 技术可行性方案

## 一、核心框架选型

| 需求 | 框架 | 可行性 |
|------|------|--------|
| 屏蔽/锁定应用 | ManagedSettings (`ShieldSettings`) | ✅ 可行 |
| 监控应用使用时长 | DeviceActivity (`DeviceActivityCenter`) | ✅ 可行 |
| 自定义锁定界面 | ManagedSettingsUI (`ShieldConfigurationDataSource`) | ✅ 可行 |
| 授权 | FamilyControls (`AuthorizationCenter`) | ✅ 可行 |
| 地理围栏(回家检测) | CoreLocation (`CLMonitor`) | ✅ 可行 |
| 睡眠专注模式检测 | AppIntents (`SetFocusFilterIntent`) | ✅ 可行 |
| 后台运行 | DeviceActivity Extension + BGTaskScheduler | ⚠️ 有限制 |

---

## 二、各技术点详细分析

### 1. 应用屏蔽/解锁 — ✅ 完全可行

**API**: `ManagedSettingsStore.shield.applications`

```swift
let store = ManagedSettingsStore(named: .init("morningLock"))
store.shield.applications = selectedAppTokens  // 锁定
store.shield.applications = nil                 // 解锁
```

**关键发现**:
- 支持**命名 Store**（`ManagedSettingsStore.Name`），可为不同模式创建独立 Store，互不干扰
- 最多同时屏蔽 **50 个** application token
- 自定义锁屏外观通过 `ShieldConfigurationDataSource` 扩展实现（可显示"冷却中，还剩 XX 分钟"）
- 用户点击 Shield 按钮时通过 `ShieldActionExtension` 处理

**用于 Kairos 的设计**:
- `morningLock` Store → 早晨模式完全锁定
- `cooldownLock` Store → 普通/晚上模式冷却期锁定
- `quotaLock` Store → 晚上模式额度用完锁定
- 各 Store 独立启停，模式切换时只操作对应 Store

### 2. 使用时长监控 — ✅ 可行，有约束

**API**: `DeviceActivityCenter.startMonitoring(_:during:events:)`

```swift
let center = DeviceActivityCenter()
let event = DeviceActivityEvent(
    applications: selectedAppTokens,
    threshold: DateComponents(minute: 15)  // 15分钟阈值
)
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 8),
    intervalEnd: DateComponents(hour: 22),
    repeats: true
)
try center.startMonitoring(.normalMode, during: schedule, events: [.usageLimit: event])
```

**关键约束**:
- 监控间隔最短 **15 分钟**，最长 **1 周**
- 最多同时监控 **20 个** Activity
- 所有回调在 **DeviceActivityMonitor 扩展** 中执行（不是主 App）
- 扩展与主 App 通过 **App Group** 共享数据

**回调方法**:

| 回调 | 用途 |
|------|------|
| `intervalDidStart(for:)` | 时间段开始（如进入普通模式时段） |
| `intervalDidEnd(for:)` | 时间段结束 |
| `eventDidReachThreshold(_:activity:)` | **使用达到阈值 → 触发锁定** |
| `eventWillReachThresholdWarning(_:activity:)` | 即将达到阈值（可提前警告） |

### 3. 睡眠专注模式检测 — ✅ 通过 Focus Filter 实现

**API**: `SetFocusFilterIntent`（AppIntents 框架）

系统在 Focus 模式开启/关闭时**自动调用** App 定义的 `SetFocusFilterIntent.perform()`，且支持通过 `SetFocusFilterIntent.current` **实时查询**当前状态。每个 Focus 模式（睡眠/勿扰/工作等）独立配置，可精确区分。

```swift
struct SleepFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "睡眠模式管控"
    
    @Parameter(title: "启用睡眠管控", default: true)
    var enableSleepControl: Bool
    
    // 系统在睡眠专注模式开启/关闭时自动调用
    func perform() async throws -> some IntentResult {
        let store = UserDefaults(suiteName: "group.kairos")!
        store.set(enableSleepControl, forKey: "sleepFocusActive")
        store.set(Date().timeIntervalSince1970, forKey: "sleepFocusTimestamp")
        return .result()
    }
}
```

**用户配置**：设置 → 专注模式 → 睡眠 → 专注模式过滤条件 → 添加 Kairos（一次配置，永久生效）

**实时查询**（在 Shield 扩展中判断当前是否处于睡眠模式）：

```swift
let current = try? await SleepFocusFilter.current
let isSleeping = current?.enableSleepControl ?? false
```

**优势**:
- ✅ 系统级集成，**精确区分**睡眠/勿扰/工作等不同 Focus 模式
- ✅ 支持事件回调（`perform()`）和实时查询（`.current`）
- ✅ 用户只需在系统设置中勾选一次，无需配置快捷指令
- ✅ 不会被误删，不需要确认弹窗

### 4. GPS 地理围栏（回家检测） — ✅ 可行

**API**: `CLMonitor` + `CLCircularGeographicCondition`（现代 async API）

```swift
let monitor = await CLMonitor("home_monitor")
let homeCondition = CLCircularGeographicCondition(
    center: CLLocationCoordinate2D(latitude: xx, longitude: xx),
    radius: 100  // 100米
)
monitor.add(homeCondition, identifier: "at_home")

for try await event in monitor.events {
    if event.state == .satisfied {
        // 用户进入家的范围
    } else {
        // 用户离开家的范围
    }
}
```

**关键特性**:
- ✅ 即使 App 未运行，系统也会**唤醒 App**
- ✅ 最多 20 个区域（只需 1 个就够）
- ✅ `When In Use` 权限 + Background Location Mode 即可
- ⚠️ 进出区域通知延迟通常 3-5 分钟（可接受）
- ⚠️ 设备重启后需解锁才能恢复监控

### 5. 后台运行与计时器 — ⚠️ 最大挑战

**核心问题**: iOS 不允许普通 App 在后台持续运行计时器。

**解决方案 — 不用计时器，用系统机制驱动**:

| 需求 | 方案 |
|------|------|
| 15分钟后锁定 | `DeviceActivityEvent` threshold=15min → 系统回调锁定 |
| 30分钟冷却后解锁 | 记录锁定时间戳 → 下次用户打开被锁App时，Shield扩展检查是否已过30分钟 → 是则解锁 |
| 晚上30分钟未使用检测 | 见下方详解 |
| 额度计时 | `DeviceActivityEvent` 设置对应阈值（20min/45min） |

**30分钟冷却的实现**:

```
用户使用15分钟 → eventDidReachThreshold → Shield 应用 →
用户点击 Shield → ShieldAction 扩展检查时间戳:
  - 不足30分钟 → 显示"冷却中，还剩 XX 分钟"（返回 .close）
  - 已过30分钟 → 移除 Shield（返回 .close + 清除设置）
                → 重新开始监控新的15分钟周期
```

**"连续30分钟未使用"检测（晚上模式激活）— 与冷却解锁同一机制**:

采用与冷却解锁相同的"懒检测"思路，无需后台监控"非使用"：

```
用户打开管控 App → Shield 拦截 → ShieldAction 检查"上次使用时间戳":
  - 距上次使用 < 30 分钟 → 仍在冷却循环，显示"冷却中"
  - 距上次使用 ≥ 30 分钟 → 激活额度模式，切换到额度制逻辑
```

本质上和冷却解锁是同一个机制，只是后续行为不同（冷却解锁 → 重新开始 15 分钟周期；晚间激活 → 切换到额度制）。完全不依赖后台计时器，100% 可靠。

### 6. 权限与分发 — ✅ 个人使用完全可行

| 项目 | 结论 |
|------|------|
| 是否需要 MDM | ❌ 不需要 |
| 普通开发者账号 | ✅ 足够 |
| 企业签名 | ❌ 不需要 |
| Family Controls 权限 | Development 版可直接用；分发需 Apple 审批 |
| 个人使用方案 | 用 **Individual 授权**（非家长-儿童模式），设备所有者用生物识别确认即可 |

**授权流程**:

```swift
try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
// 系统弹出生物识别（Face ID/Touch ID）确认
```

---

## 三、整体架构

```
┌─────────────────────────────────────────┐
│              Kairos 主 App               │
│  - 首次设置/授权                          │
│  - FamilyActivityPicker 选择要管控的 App   │
│  - 设置家的 GPS 坐标                      │
│  - 状态展示 Widget                        │
└──────────┬──────────────────────────────┘
           │ App Group (共享数据)
           │
┌──────────┴──────────────────────────────┐
│        DeviceActivityMonitor 扩展        │
│  - intervalDidStart → 模式激活           │
│  - eventDidReachThreshold → 触发锁定     │
│  - intervalDidEnd → 重置状态             │
└──────────┬──────────────────────────────┘
           │
┌──────────┴──────────┐  ┌────────────────┐
│ ShieldConfiguration  │  │ ShieldAction   │
│ 扩展（自定义锁屏UI） │  │ 扩展（处理按钮）│
└─────────────────────┘  └────────────────┘

外部数据源:
  - CLMonitor → 地理围栏 (在家/不在家)
  - SetFocusFilterIntent → 睡眠专注模式状态（系统自动回调 + 实时查询）
  - App Group UserDefaults → 跨组件共享状态
```

**需要创建的 Target**:
1. **Kairos** (主 App)
2. **KairosMonitor** (Device Activity Monitor Extension)
3. **KairosShieldConfig** (Shield Configuration Extension)
4. **KairosShieldAction** (Shield Action Extension)
5. **KairosWidget** (Widget Extension，可选)

---

## 四、模式实现映射

### 早晨模式（morning）

```
前提: 必须从晚上模式经过睡眠专注进入
触发: 晚上模式中 → 睡眠专注开启 → 睡眠专注关闭
      → SleepFocusFilter.perform() 写入 App Group: sleepFocusOff + timestamp
      → 距关闭 < 1h → morningLock Store 锁定管控应用
解除: Shield 点击时检查距睡眠专注关闭已 ≥ 1h → 解锁
      → 根据条件进入普通模式或恢复晚上模式
误触: 早晨模式期间重新开启睡眠专注 → sleepFocusActive=true → 暂停管控
      → 再次关闭 → 新的 sleepFocusOffTimestamp → 重新计时
```

### 普通模式（normal）

```
触发: 默认状态（不满足早晨/晚上条件）
监控: DeviceActivityEvent(apps, threshold: 15min)
      → eventDidReachThreshold → shield 应用
冷却: ShieldAction 检查锁定 timestamp
      → ≥30min → 解除 shield, 重新开始监控
```

### 晚上模式（night）

```
触发: CLMonitor(at_home) + time >= 22:00 + 距上次使用管控应用 ≥ 30min
额度: DeviceActivityEvent(小说, threshold: 45min)
      DeviceActivityEvent(通用组, threshold: 20min)
      → eventDidReachThreshold → 对应 Store 锁定（用完哪个锁哪个）
额度保持: 额度通过各自的 ManagedSettingsStore 独立管理，当日有效
```

---

## 五、风险与注意事项

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| Sleep Focus 检测 | 低 | 已通过 SetFocusFilterIntent 解决，系统级集成 |
| 30分钟冷却不精确 | 中 | 用 Shield 点击时检查时间戳，误差可控 |
| DeviceActivityMonitor 扩展内存限制 | 中 | 保持扩展逻辑简单，复杂逻辑用 App Group |
| App 被系统杀死后状态丢失 | 低 | 所有状态持久化到 App Group UserDefaults |
| Family Controls 分发审批 | 低 | 个人使用 Development Profile 即可，不上架 |
| Shield 上的倒计时无法实时刷新 | 低 | 显示"XX:XX 后可用"的绝对时间而非倒计时 |

---

## 六、结论

**项目整体可行**，核心功能都有对应 API 支持。主要调整建议：

1. **睡眠专注模式**: 通过 `SetFocusFilterIntent` 实现系统级集成，支持事件回调和实时查询
2. **30分钟未使用检测**: 与冷却解锁复用同一机制（Shield 点击时懒检测），无需后台监控
3. **冷却计时**: 不用后台计时器，改为 Shield 点击时懒计算
