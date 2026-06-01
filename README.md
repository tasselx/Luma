# Luma Browser

一个轻量、注重隐私的移动端浏览器，支持原生视频播放。

## 功能特性

### 网页浏览
- 基于 WebView 的完整浏览体验，支持 JavaScript
- 智能地址栏：自动识别 URL 与搜索关键词（支持裸域名、localhost、IPv4、中日韩文字）
- 前进/后退、刷新、停止加载
- 桌面模式（自定义 User-Agent）
- 页内文字搜索（`window.find`）
- 错误页面支持重试、复制链接、外部打开

### 标签页管理
- 多标签页：新建、关闭、切换、关闭其他、关闭全部普通标签
- 隐私/无痕模式（不记录历史和搜索记录，不持久化标签）
- 最近关闭标签页（最多 10 个，可恢复）
- 可选的标签页跨会话持久化

### 书签与历史
- 添加/移除/切换书签，书签列表支持搜索过滤
- 浏览历史按日期分组（今天/昨天/日期），单条删除与批量清除
- 历史上限 500 条，搜索历史上限 50 条

### 搜索引擎
- 内置 Google、Bing、DuckDuckGo、百度
- 设置中可切换默认搜索引擎
- 搜索历史自动补全

### 原生视频播放
- 自动检测直链视频（mp4、m4v、mov、webm、m3u8）
- 拦截对话框：原生播放 / 网页打开 / 取消
- 全屏播放器：播放/暂停、进度条、时长显示
- 可下载格式提供下载按钮（排除 m3u8）

### 下载管理
- 下载确认对话框（文件名、类型、来源域名、URL）
- 委托系统浏览器/下载管理器处理
- 下载历史记录

### 主页
- 快捷站点网格（Google、YouTube、GitHub、Reddit、X、Wikipedia、Stack Overflow、Flutter）
- 最近历史与书签展示
- 隐私模式状态提示

### 设置
- 默认搜索引擎、快捷站点显隐、标签持久化、桌面模式
- 原生视频播放开关、播放前询问开关、下载按钮开关
- 清除历史/书签/搜索历史/全部浏览数据

### 隐私
- 所有数据本地存储（SharedPreferences），无网络上传
- 隐私模式不记录任何历史
- 支持一键清除全部浏览数据

## 技术栈

| 项目 | 说明 |
|------|------|
| 语言 | Dart |
| 框架 | Flutter (`^3.5.4`) |
| 状态管理 | Provider (ChangeNotifier) |
| 平台 | Android / iOS |
| 设计语言 | Material 3（亮色 + 暗色主题） |
| 持久化 | SharedPreferences |

### 主要依赖

- `webview_flutter` — WebView 渲染
- `provider` — 状态管理
- `shared_preferences` — 本地持久化
- `video_player` — 原生视频播放
- `url_launcher` — 外部链接/下载
- `path_provider` — 文件路径

## 快速开始

### 环境要求

- Flutter SDK（stable，`^3.5.4`）
- Android Studio / Xcode（对应平台工具链）

### 运行

```bash
flutter pub get
flutter run
```

### 构建

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

无需 API Key 或后端服务，应用完全自包含。

## 项目结构

```
lib/
├── main.dart                           # 入口
├── app.dart                            # MaterialApp + Provider 配置
├── core/
│   ├── app_theme.dart                  # Material 3 主题（seed: #3B6EF6）
│   └── ui_helpers.dart                 # 通用 UI 工具函数
└── features/browser/
    ├── controllers/
    │   └── browser_controller.dart     # 核心状态控制器（标签、历史、书签、设置、下载）
    ├── models/                         # 数据模型（标签、书签、历史、搜索引擎、设置、下载、视频源）
    ├── services/
    │   ├── browser_storage_service.dart    # SharedPreferences 持久化
    │   ├── browser_url_service.dart        # URL 解析与搜索构建
    │   ├── video_source_detector.dart      # 视频链接检测
    │   └── video_download_service.dart     # 下载服务
    ├── pages/                          # 页面（主页、浏览器、标签、书签、历史、设置、关于、视频播放器）
    └── widgets/                        # 可复用组件（地址栏、工具栏、菜单、对话框等）
```

架构采用 Feature-based 分层：`controllers`（业务逻辑）、`models`（数据）、`services`（工具）、`pages`（页面）、`widgets`（组件），状态通过单一 `BrowserController` 经由 `provider` 分发。

## 测试

```bash
flutter test
```

测试覆盖 `BrowserUrlService`（URL 解析、搜索识别、CJK 处理）和 `VideoSourceDetector`（直链检测、blob/data 过滤、m3u8 处理）。

## 许可证

[MIT License](LICENSE) — Copyright (c) 2026 Tassel
