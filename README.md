# 桌面薪资宠物 (Desktop Salary Pet)

一个有趣的 Flutter 桌面应用，实时显示你的工作收入，配有可爱的恐龙跑步游戏！

![Desktop Pet Demo](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-blue?style=for-the-badge)

## ✨ 功能特色

- 🦕 **Chrome 恐龙风格游戏** - 自动跳跃收集金币的横版跑步游戏
- 💰 **实时薪资计算** - 基于真实时间计算当前工作收入
- ⚙️ **个性化设置** - 自定义月薪、工作时长、上班时间和工作日
- 🎮 **平滑动画** - 流畅的数字增长动画和游戏物理效果
- 🌟 **桌面宠物** - 透明背景、置顶显示、可拖拽窗口（桌面版）
- 🕐 **实时时钟** - 显示当前日期和时间

## 🎯 游戏玩法

- 恐龙会自动奔跑并跳跃避开障碍物
- 背景有仙人掌、云朵、岩石等元素营造沙漠氛围
- 实时显示基于工作时间计算的收入增长
- 点击右上角设置按钮可调整薪资参数

## 🚀 快速开始

### 环境要求

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 2.17.0)
- 对于 macOS: Xcode 和 CocoaPods
- 对于 Windows: Visual Studio 2022
- 对于 Linux: GTK 开发库

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/YOUR_USERNAME/get_money.git
   cd get_money
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   
   桌面版 (推荐):
   ```bash
   # macOS
   flutter run -d macos
   
   # Windows
   flutter run -d windows
   
   # Linux
   flutter run -d linux
   ```
   
   Web 版 (测试用):
   ```bash
   flutter run -d chrome
   ```

## ⚙️ 配置说明

首次运行时，可以通过右上角的"设置"按钮配置：

- **月薪** - 你的月薪金额（默认 10000 元）
- **每日工作时长** - 每天工作小时数（默认 8 小时）
- **上班时间** - 每天开始工作的时间（默认 09:00）
- **工作日** - 选择哪些天是工作日（默认周一到周五）

## 🛠️ 技术栈

- **Flutter** - 跨平台 UI 框架
- **window_manager** - 桌面窗口管理（透明、置顶、拖拽）
- **shared_preferences** - 本地设置存储
- **CustomPainter** - 自定义游戏图形绘制
- **AnimationController** - 平滑动画控制

## 📱 平台支持

| 平台 | 状态 | 特性 |
|------|------|------|
| macOS | ✅ 完全支持 | 透明窗口、置顶、拖拽 |
| Windows | ✅ 完全支持 | 透明窗口、置顶、拖拽 |
| Linux | ✅ 完全支持 | 透明窗口、置顶、拖拽 |
| Web | ⚠️ 部分支持 | 基础功能，无窗口特效 |

## 🎨 自定义开发

项目结构清晰，易于扩展：

```
lib/
├── main.dart              # 主应用文件
├── models/               # 数据模型（待扩展）
├── widgets/              # 自定义组件（待扩展）
└── utils/                # 工具类（待扩展）
```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 灵感来源于 Chrome 离线恐龙游戏
- Flutter 社区提供的优秀插件支持

---

**享受工作，享受收入增长的乐趣！** 🎉