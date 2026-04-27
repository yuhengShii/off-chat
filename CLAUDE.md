# Project Overview

OffChat - 基于蓝牙的离线聊天应用，支持安卓/iOS。

## 技术栈

- **框架**: Flutter + flutter_blue_plus
- **状态管理**: Provider
- **蓝牙协议**: Nordic UART Service (BLE)

## Build Commands

```bash
flutter pub get        # 获取依赖
flutter run           # 运行
flutter analyze       # lint 检查
```

## Code Style

- 使用 ES modules import/export 语法
- 使用 2-space 缩进
- 使用 Material Design 3

## Workflow

1. **每次只做一个功能点**，不并行开发多个功能
2. **当前功能点端到端验证通过后，才能开始下一个**（必须实际运行验证）
3. **不借机顺手重构其他功能**（功能开发与重构分开）
4. **代码完成后必须通过 lint 检查**，后才能提交
5. **每次代码完成后，必须先验证再提交**：单元测试 + 功能验证 + lint 通过

## 开发计划

### Phase 1: 项目初始化
- [x] 创建目录结构
- [x] 创建数据模型
- [x] 创建核心服务
- [x] 创建 Provider 状态管理
- [x] 创建 UI 界面
- [x] 预留语音消息接口
- [x] 初始化 Flutter 项目
- [x] 配置 Android/iOS 蓝牙权限
- [x] Lint 检查通过
- [x] 单元测试通过（6个）
- [ ] 端到端验证（真机测试）

### Phase 2: 核心 BLE 功能
- [ ] 蓝牙设备扫描
- [ ] 设备连接/断开
- [ ] 消息发送/接收
- [ ] 连接状态管理
- [ ] 端到端验证

### Phase 3: UI 完善
- [ ] 聊天界面优化
- [ ] 消息气泡样式
- [ ] 连接状态指示
- [ ] 错误处理和提示
- [ ] 端到端验证

### Phase 4: 语音消息预留
- [ ] VoiceMessageService 接口
- [ ] 语音消息模型
- [ ] 预留 UI 组件
- [ ] 端到端验证

## BLE 协议定义

```
Service UUID: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
TX (Write):   6E400002-B5A3-F393-E0A9-E50E24DCCA9E
RX (Notify):  6E400003-B5A3-F393-E0A9-E50E24DCCA9E
```

## 目录结构

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── ble_constants.dart
│   └── theme/
│       └── app_theme.dart
├── models/
│   ├── ble_connection_state.dart
│   ├── chat_message.dart
│   └── device_info.dart
├── providers/
│   ├── ble_provider.dart
│   ├── chat_provider.dart
│   └── device_list_provider.dart
├── screens/
│   ├── chat_screen.dart
│   ├── home_screen.dart
│   ├── scan_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── ble_service.dart
│   ├── ble_device_service.dart
│   ├── message_service.dart
│   └── voice_message_service.dart    # 预留
└── widgets/
    ├── message_bubble.dart
    └── message_input.dart
```

## Common Gotchas

- Android 蓝牙权限需要正确配置
- iOS 需要配置 Info.plist
- 设备需要手动配对后才能连接
