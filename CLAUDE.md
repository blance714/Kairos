# Kairos

iOS Screen Time 自我管控应用，使用 FamilyControls / ManagedSettings / DeviceActivity 框架实现基于时间和地理位置的应用锁定。

## 开始之前

改动代码前，请先阅读以下文档了解项目背景：

- [docs/TechnicalPlan.md](docs/TechnicalPlan.md) — 技术可行性分析、框架选型、模式实现映射
- [docs/ExecutionPlan.md](docs/ExecutionPlan.md) — 执行计划、依赖关系、当前进度、测试统计

## 项目结构

```
Kairos/              # 主 App Target
KairosKit/           # 本地 Swift Package（跨 Target 共享代码）
KairosMonitor/       # DeviceActivity Monitor 扩展
KairosShieldConfig/  # Shield Configuration 扩展
KairosShieldAction/  # Shield Action 扩展
KairosTests/         # 单元测试（218 个，Swift Testing 框架）
KairosUITests/       # UI 测试
docs/                # 技术文档
```

## 技术要点

- **Swift 6 严格并发**：Apple 框架类型（`DeviceActivityName` 等）非 Sendable，静态属性用 `nonisolated(unsafe)` 标注
- **跨 Target 共享**：通过 `KairosKit` 本地 Swift Package + App Group UserDefaults
- **测试文件导入**：由于 `MEMBER_IMPORT_VISIBILITY`，测试文件需显式 `import Foundation` 和 `import KairosKit`
- **FamilyActivityPicker**：必须用 `.familyActivityPicker(isPresented:selection:)` modifier，不能直接嵌入 Form
- **纯函数优先**：`ModeResolver`、`ShieldTextBuilder`、`ShieldUnlockResolver`、`ActivityScheduleBuilder`、`DashboardDisplayBuilder` 均为纯函数，方便测试
- **Swift API 文档查询**：Apple API 经常变化，不要依赖训练数据。用 `general-purpose` subAgent + Xcode MCP `DocumentationSearch` 搜索文档，避免在主会话搜索占用上下文

## 3 种模式

| 模式 | 触发条件 |
|------|----------|
| morning | 晚上模式经睡眠专注后关闭，1 小时内锁定 |
| normal | 默认状态，15 分钟使用 + 30 分钟冷却循环 |
| night | 在家 + 22:00 后 + 30 分钟未使用，额度制（通用 20 分钟 / 小说 45 分钟） |

## 构建与测试

```bash
# 通过 Xcode 构建（需要 Xcode 和 iOS 模拟器）
xcodebuild -project Kairos.xcodeproj -scheme Kairos -destination 'platform=iOS Simulator,name=iPhone 16' build

# 运行测试
xcodebuild -project Kairos.xcodeproj -scheme Kairos -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## 当前状态

Phase 1-4 已完成（基础设施、数据层、核心逻辑、UI），Phase 5（真机联调）等待 Apple 开发者会员批准。
