# Kairos 执行计划

## 一、任务依赖分析

### 依赖关系图

```
L1 项目基础设施
 ├──▶ L2 授权与应用选择
 ├──▶ L3 睡眠专注模式
 ├──▶ L4 地理围栏
 └──▶ L5 模式判定引擎（需要 L1 定义的共享数据格式）
       ├──▶ L6 DeviceActivityMonitor（还依赖 L2 的 app tokens）
       └──▶ L7 Shield 扩展
            
L2 + L3 + L4 ──▶ L8 主 App UI（引导流程串联所有设置步骤）

L6 + L7 + L8 ──▶ L9 联调与调试
```

### 依赖矩阵

| 任务 | 前置依赖 | 被谁依赖 |
|------|----------|----------|
| L1 项目基础设施 | 无 | 所有 |
| L2 授权与应用选择 | L1 | L6, L8 |
| L3 睡眠专注模式 | L1 | L5(数据格式), L8 |
| L4 地理围栏 | L1 | L5(数据格式), L8 |
| L5 模式判定引擎 | L1 | L6, L7 |
| L6 DeviceActivityMonitor | L2, L5 | L9 |
| L7 Shield 扩展 | L5 | L9 |
| L8 主 App UI | L2, L3, L4 | L9 |
| L9 联调与调试 | 全部 | 无 |

### 可并行分组

```
          ┌── L2 授权与应用选择 (0.5d)
L1 (1d) ──┼── L3 睡眠专注模式   (0.5d)   ← 这四个互不依赖，可并行
          ├── L4 地理围栏       (0.5d)
          └── L5 模式判定引擎   (1.5d)

          ┌── L6 Monitor  (1d)  ← 依赖 L2+L5
L2+L5 ───┤                       这两个互不依赖，可并行
          └── L7 Shield   (1.5d) ← 依赖 L5

L2+L3+L4 ──── L8 主 App UI (1d)  ← 与 L6/L7 也可并行

全部完成 ──── L9 联调调试  (2d)
```

**理论最短路径**（多人并行）：L1(1d) → L5(1.5d) → L7(1.5d) → L9(2d) = **6 天**

---

## 二、单人执行计划

### Phase 1：地基 ✅ 完成

**目标**：所有 Target 和共享基础设施就绪

- [x] 创建 App Group `group.org.blance.kairos`
- [x] 创建 3 个 Extension Target（Monitor / ShieldConfig / ShieldAction）
  - *变更*：FocusFilter 不需要单独 Target，`SetFocusFilterIntent` 直接在主 App 中实现
- [x] 所有 Target 添加 Family Controls capability 和 App Group
- [x] 实现 `KairosSharedState`：App Group UserDefaults 的类型安全封装
  - 所有共享 key 定义（模式状态、时间戳、app tokens、isAtHome 等）
  - 编码/解码 `FamilyActivitySelection`
  - 被所有 Target 引用
- [x] 创建 `KairosKit` 本地 Swift Package 用于跨 Target 共享代码

**实际架构决策**：
- 共享代码通过本地 Swift Package `KairosKit` 实现，所有 Target 添加为依赖
- `KairosSharedState` 声明为 `Sendable`，`UserDefaults` 用 `nonisolated(unsafe)` 标注
- Apple 非 Sendable 类型（`DeviceActivityName` 等）的静态属性用 `nonisolated(unsafe)`

### Phase 2：数据输入层 ✅ 完成（并行 4 个 TDD Agent）

#### L2 授权与应用选择 ✅（13 个测试）

- [x] 实现授权流程 `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
- [x] 实现 `FamilyActivityPicker` 页面（通用组 + 小说组）
- [x] 选择结果持久化到 App Group
- [x] `AuthorizationStatus` 枚举、`KairosSharedStateProtocol` 协议实现 DI

**实际架构决策**：
- `FamilyActivityPicker` 使用 `.familyActivityPicker(isPresented:selection:)` modifier 弹出系统全屏选择器，而非直接嵌入 Form（嵌入会导致布局挤压和交互问题）
- `AuthorizationManager` 和 `AppSelectionManager` 通过 `KairosSharedStateProtocol` 注入依赖，可用 `FakeSharedState` 测试

#### L3 睡眠专注模式 ✅（9 个测试）

- [x] 实现 `SleepFocusFilter: SetFocusFilterIntent`
  - `perform()` → 写入 App Group（sleepFocusActive + timestamp）
- [x] 实现引导提示 UI（`SleepFocusGuideView`）

**实际架构决策**：
- 提取 `SleepFocusTransition` 纯结构体，可注入时钟 `now: () -> Date`
- `SleepFocusStoring` 协议 + retroactive conformance

#### L4 地理围栏 ✅（19 个测试）

- [x] 家的位置设置 UI（"使用当前位置"按钮 + 地图点选）
- [x] 坐标持久化到 App Group
- [x] `CLMonitor` + `CLMonitor.CircularGeographicCondition` 初始化
  - *变更*：API 为 `CLMonitor.CircularGeographicCondition`，非 `CLCircularGeographicCondition`
- [x] 进入/离开回调 → 写入 App Group `isAtHome`

**实际架构决策**：
- `GeofenceEventHandler` 纯无状态结构体 + `GeofenceAction` 值类型
- `GeofenceStore` 协议 + `MockGeofenceStore` 测试替身
- `CLMonitor` 是 actor，`events` 属性需 `await` 访问，`for try await` 遍历

#### L5 模式判定引擎 ✅（30 个测试，含参数化）

- [x] 定义模式枚举：`morning` / `normal` / `nightCooldown` / `nightQuota` / `nightExhausted`
- [x] 实现 `ModeResolver.resolve(_:) -> KairosMode`，纯静态函数
- [x] 单元测试覆盖所有模式切换路径、边界条件、午夜跨天

**实际架构决策**：
- 夜间窗口定义为 `hour >= 22 || hour < 6`（正确处理午夜跨天）
- `ModeResolverInput` 包含 `nightQuotaExhausted: Bool` 字段
- 优先级：sleepFocusActive → morning → nightExhausted → nightQuota → nightCooldown → normal

### Phase 3：核心逻辑层 ✅ 完成（并行 2 个 TDD Agent）

#### L6 DeviceActivityMonitor ✅（23 个测试）

- [x] `ActivityScheduleBuilder` 纯函数构建 Schedule + Events
- [x] `MonitorManager` 主 App 编排器
- [x] DeviceActivityMonitor 扩展完整实现
  - `eventDidReachThreshold` 处理 `.usageThreshold` / `.generalQuota` / `.novelQuota`
  - `intervalDidEnd` 清除对应 ManagedSettingsStore

#### L7 Shield 扩展 ✅（52 个测试：25 + 27）

- [x] **ShieldTextBuilder**（锁屏文案）— 纯函数，5 种模式文案 + 倒计时
- [x] **ShieldUnlockResolver**（解锁判定）— 纯函数，deny/unlock/switchToQuota
- [x] ShieldConfiguration 扩展：读共享状态 → 构建 ShieldConfiguration
- [x] ShieldAction 扩展：Primary .close / Secondary 调用 ShieldUnlockResolver

### Phase 4：UI 整合 ✅ 完成（并行 2 个 TDD Agent）

#### L8 主 App UI ✅（36 个测试：26 + 16 - 含参数化）

- [x] **引导流程**（首次启动）
  1. 欢迎页 → 说明 App 用途
  2. 授权页 → Family Controls 授权
  3. 选择应用页 → `.familyActivityPicker` modifier 弹出系统选择器
  4. 设置家的位置页 → 地图点选 + "使用当前位置"按钮
  5. Focus Filter 引导页 → 提示去系统设置
  6. 完成页
- [x] **主界面（仪表盘）**
  - 当前模式卡片（图标 + 渐变背景 + 状态文字）
  - 距下次状态变化的时间
- [x] **设置页**
  - 重新选择管控应用
  - 修改家的位置
  - 查看 Focus Filter 配置状态
- [x] `KairosApp.swift` 重写：移除 SwiftData，根据 `onboardingCompleted` 路由
- [x] 删除 `Item.swift`（SwiftData 模板）

**实际架构决策**：
- `OnboardingViewModel` 支持 `forceStep()` 测试逃生舱
- `DashboardDisplayBuilder` 纯函数生成状态文案，ViewModel 只做编排
- `OnboardingContainerView` init 不使用 `@MainActor` 默认参数（Swift 6 限制）

### Phase 5：联调与调试 ⏳ 进行中

#### Day 7：功能联调

- [ ] 真机部署全部 Target
- [ ] 端到端流程测试：
  - 首次引导 → 授权 → 选应用 → 全流程走通
  - 睡眠专注模式开/关 → 早晨模式触发/解除
  - 应用使用 15min → 冷却锁定 → 30min 后解锁
  - 晚上到家 + 22:00 后 → 晚上模式 → 额度激活 → 额度耗尽
- [ ] 扩展间数据一致性验证
- [ ] 修复发现的问题

#### Day 8：边界与稳定性

- [ ] 边界情况测试：
  - 跨午夜：23:50 开始使用 → 00:10 额度状态
  - 离开家又回来 → 模式切换
  - App 被杀 → 重新启动后状态恢复
  - 设备重启 → CLMonitor 和 DeviceActivity 恢复
- [ ] Shield 显示效果微调
- [ ] 内存和电量影响观察

---

## 三、关键里程碑

| 节点 | 完成标志 | 状态 |
|------|----------|------|
| M1 骨架就绪 | 所有 Target 编译通过，App Group 数据可读写 | ✅ |
| M2 数据层就绪 | 授权/选App/Focus Filter/地理围栏 全部能写入状态 | ✅ |
| M3 核心逻辑就绪 | Monitor 能监控使用时长并触发 Shield，Shield 能正确判定模式并展示 | ✅ |
| M4 可用版本 | 完整引导流程 + 仪表盘 + 全部模式可运行 | ✅ |
| M5 稳定版本 | 边界情况修复，日常可用 | ⏳ |

---

## 四、测试统计

| 模块 | 测试数 | 框架 |
|------|--------|------|
| L2 授权 & 选择 | 17 | Swift Testing |
| L3 睡眠专注 | 9 | Swift Testing |
| L4 地理围栏 | 19 | Swift Testing |
| L5 模式引擎 | 52 | Swift Testing |
| L6 Schedule Builder | 23 | Swift Testing |
| L7 Shield Text/Unlock | 52 | Swift Testing |
| L8 Onboarding/Dashboard | 42 | Swift Testing |
| UI Tests | 3 | XCUITest |
| **总计** | **218** | **全部通过** |

---

## 五、风险缓冲

| 风险 | 影响 | 缓冲 |
|------|------|------|
| Screen Time API 调试困难（只能真机、日志少） | +1~2d | 优先实现 Monitor + Shield，留足调试时间 |
| 扩展沙盒限制导致逻辑需重构 | +1d | Phase 3 发现后立即调整 |
| SetFocusFilterIntent.current 行为与预期不符 | +0.5d | 保留 perform() 写 App Group 作为备选 |

**保守总估计：8 ~ 10 天**

---

## 六、项目结构（当前）

```
Kairos/
├── KairosKit/                          # 本地 Swift Package（共享代码）
│   └── Sources/KairosKit/
│       ├── KairosSharedState.swift      # App Group UserDefaults 封装
│       ├── KairosMode.swift             # 5 种模式枚举
│       ├── KairosConstants.swift        # DeviceActivityName/Event/Store 常量
│       ├── ModeResolver.swift           # 模式判定纯函数
│       ├── ActivityScheduleBuilder.swift # Schedule/Event 构建器
│       ├── ShieldTextBuilder.swift      # 锁屏文案生成器
│       └── ShieldUnlockResolver.swift   # 解锁判定逻辑
├── Kairos/                             # 主 App Target
│   ├── KairosApp.swift                 # 入口（onboarding vs dashboard 路由）
│   ├── Authorization/                  # 授权 & 应用选择
│   ├── FocusFilter/                    # 睡眠专注模式
│   ├── Geofence/                       # 地理围栏
│   ├── Monitor/                        # MonitorManager
│   ├── Onboarding/                     # 引导流程（6 步）
│   ├── Dashboard/                      # 仪表盘 & 模式卡片
│   └── Settings/                       # 设置页
├── KairosMonitor/                      # DeviceActivity Monitor 扩展
├── KairosShieldConfig/                 # Shield Configuration 扩展
├── KairosShieldAction/                 # Shield Action 扩展
├── KairosTests/                        # 218 个单元测试
└── KairosUITests/                      # UI 测试
```
