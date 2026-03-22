# MiniMaxMenuBar 开发进度

**最后更新**: 2026-03-22
**当前版本**: 1.1.0

---

## 总体进度

| 类别 | 完成 | 进行中 | 待开始 | 完成率 |
|------|------|--------|--------|--------|
| 核心功能 | 6 | 0 | 0 | 100% |

---

## 功能模块状态

### ✅ 已完成

#### F1: 状态栏显示
- ✅ 显示剩余配额百分比
- ✅ 未配置显示 N/A
- ✅ 请求失败显示 ⚠️
- ✅ 颜色指示 (🟢🟡🔴)

#### F2: 配额详情弹窗
- ✅ Popover 弹窗
- ✅ 显示模型名称
- ✅ 显示时间窗口
- ✅ 显示剩余时间
- ✅ 显示已用/总配额

#### F3: 配置管理
- ✅ API Key 输入
- ✅ Group ID 输入 (可选)
- ✅ 保存到 UserDefaults
- ✅ 加载已保存的配置

#### F4: 数据刷新
- ✅ 启动时自动刷新
- ✅ 每 5 分钟自动刷新
- ✅ 手动刷新按钮
- ✅ 打开弹窗时刷新

#### F5: 退出应用
- ✅ 退出按钮
- ✅ 完全退出应用

#### F6: 每日/每周使用统计
- ✅ 数据模型 DailySnapshot | `Shared/QuotaModels.swift`
- ✅ 使用量追踪服务 | `Sources/UsageTracker.swift`
- ✅ 统计视图 StatsView | `Sources/App.swift`
- ✅ 集成到 StatusBarViewModel | `Sources/StatusBarViewModel.swift`
- ✅ UI 入口按钮 | 主界面添加"统计"按钮

---

## 实现步骤对照

| 步骤 | 文件 | 状态 |
|------|------|------|
| 1. XcodeGen 配置 | `project.yml` | ✅ 完成 |
| 2. Info.plist | `Resources/Info.plist` | ✅ 完成 |
| 3. 数据模型 | `Shared/QuotaModels.swift` | ✅ 完成 |
| 4. 配置服务 | `Sources/ConfigService.swift` | ✅ 完成 |
| 5. API 请求 | `Sources/QuotaService.swift` | ✅ 完成 |
| 6. 主视图 | `Sources/App.swift` (ContentView) | ✅ 完成 |
| 7. 状态栏 ViewModel | `Sources/StatusBarViewModel.swift` | ✅ 完成 |
| 8. AppDelegate | `Sources/AppDelegate.swift` | ✅ 完成 |
| 9. 应用入口 | `Sources/main.swift` | ✅ 完成 |

---

## 项目文件清单

```
MiniMaxMenuBar/
├── Sources/
│   ├── main.swift                    ✅
│   ├── App.swift                     ✅ (包含 ContentView, StatsView)
│   ├── AppDelegate.swift             ✅
│   ├── StatusBarViewModel.swift     ✅ (集成 UsageTracker)
│   ├── QuotaService.swift           ✅
│   ├── ConfigService.swift          ✅
│   └── UsageTracker.swift           ✅ (新增)
├── Shared/
│   └── QuotaModels.swift             ✅ (添加 DailySnapshot)
├── Resources/
│   ├── Info.plist                    ✅
│   └── MiniMaxMenuBar.entitlements   ✅
├── project.yml                        ✅
├── .prd/                            ✅
│   └── F6-Usage-Stats-20260322.prd ✅ (详细需求文档)
└── scripts/
    └── build_dmg.sh                  ✅
```

---

## 构建状态

| 配置 | 状态 |
|------|------|
| Debug Build | ✅ 通过 |
| Release Build | ✅ 通过 |
| 本地运行 | ✅ 正常 |

---

## 待优化项 (可选)

- [ ] 添加本地通知功能 (配额用尽警告)
- [ ] 多模型支持
- [ ] 配额历史图表
- [ ] 自定义刷新间隔设置
- [ ] DMG 打包分发

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-03-22 | 初始版本，完成核心功能 |
| 1.1.0 | 2026-03-22 | 添加每日/每周使用统计功能 (F6) |

