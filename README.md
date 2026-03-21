# MiniMax Tools

MiniMax API 相关工具集，包含 macOS 菜单栏应用和命令行查询工具。

## 项目结构

```
minimax/
├── MiniMaxMenuBar/     # macOS 菜单栏应用
└── minimax-cp-query/   # 命令行查询工具
    ├── main.go              # Go 版本
    └── query_coding_plan.py # Python 版本
```

## 三种工具对比

| 工具 | 语言 | 平台 | 配置方式 | 特点 |
|------|------|------|----------|------|
| **MiniMaxMenuBar** | Swift/SwiftUI | macOS | 环境变量 | GUI 菜单栏，实时显示配额 |
| **minimax-cp-query** | Go | 跨平台 | config.json / 环境变量 | CLI，带调试模式 |
| **query_coding_plan.py** | Python | 跨平台 | 命令行参数 | CLI，轻量简单，支持 cn/intl 区域 |

## MiniMaxMenuBar

macOS 菜单栏应用，在状态栏显示 MiniMax API 剩余配额。

### 功能

- 实时显示配额剩余百分比
- 窗口重置时间倒计时
- 支持刷新和配置
- 深色主题 UI

### 技术栈

- SwiftUI (macOS 14+)
- XcodeGen

### 构建

```bash
cd MiniMaxMenuBar
xcodegen generate
open MiniMaxMenuBar.xcodeproj
```

### 生成 DMG

本地生成安装包：

```bash
cd MiniMaxMenuBar
./scripts/build_dmg.sh
```

或手动构建：

```bash
xcodebuild -project MiniMaxMenuBar.xcodeproj -scheme MiniMaxMenuBar \
  -configuration Release build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

### 配置

在 Xcode 中设置环境变量：
- `MINIMAX_API_KEY`: MiniMax API Key
- `MINIMAX_GROUP_ID`: Group ID (可选)

### minimax-cp-query (Go)

命令行工具，支持调试模式。

```bash
cd minimax-cp-query
go build -o minimax-cp-query
./minimax-cp-query          # 查询配额
./minimax-cp-query -v       # 调试模式
```

### query_coding_plan.py (Python)

轻量级 Python 脚本，直接传入 API Key：

```bash
python query_coding_plan.py <api_key> [--group-id ID] [--region cn|intl]
```

支持 `--region` 选择国内(cn)或国际(intl)节点。

## API 信息

| 项目 | 值 |
|------|-----|
| URL | `https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains` |
| 方法 | GET |
| 认证 | Bearer Token |

## CI/CD

推送 tag 后自动构建并发布 DMG：

```bash
git tag v1.0.0
git push origin v1.0.0
```

 Workflow 文件：`.github/workflows/build.yml`

## License

MIT
