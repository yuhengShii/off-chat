# Project Overview

OffChat - 基于 BLE 的离线聊天应用，支持安卓/iOS。

## 技术栈

- **框架**: Flutter + flutter_blue_plus
- **状态管理**: Provider
- **蓝牙协议**: BLE (Nordic UART Service, NUS)
- **GATT 服务端**: Kotlin (BluetoothGattServer) / Swift (CBPeripheralManager)
- **消息格式**: JSON over BLE (UTF-8 编码)

## Build Commands

```bash
flutter pub get        # 获取依赖
flutter run            # 运行
flutter analyze        # lint 检查
flutter test           # 运行所有测试（86 tests）
flutter build apk --debug --target-platform android-arm64  # BKQ AN10 (arm64) debug APK
flutter build apk --debug --target-platform android-arm    # Redmi 3 (arm) debug APK
```

## Code Style

- 使用 ES modules import/export 语法
- 使用 2-space 缩进
- 使用 Material Design 3
- 编码/解码统一使用 UTF-8（禁止 `String.codeUnits` + `Uint8List.fromList`，会截断非 ASCII 字符）

## Workflow

1. **每次只做一个功能点**，不并行开发多个功能
2. **当前功能点端到端验证通过后，才能开始下一个**（必须实际运行验证）
3. **不借机顺手重构其他功能**（功能开发与重构分开）
4. **代码完成后必须通过 lint 检查和单元测试**，后才能提交
5. **每次代码完成后，必须先验证再提交**：单元测试 + 功能验证 + lint 通过
6. **每次 debug 都要记录过程和结果**：记录到 `DEBUG_LOG.md` 文件，包括修改内容、测试步骤、结果（通过/没通过）

## 开发计划

### Phase 1: 项目初始化 ✅
- [x] 创建目录结构、数据模型、核心服务、Provider 状态管理、UI 界面
- [x] 预留语音消息接口
- [x] 配置 Android/iOS 蓝牙权限
- [x] Lint 检查通过（86 个单元测试通过）

### Phase 2: 核心蓝牙功能 ✅
- [x] BLE 设备扫描（flutter_blue_plus + NUS UUID 过滤）
- [x] BLE 设备连接/断开（GATT client）
- [x] BLE Advertising/扫描（GATT server，Kotlin/Swift）
- [x] 连接握手协议（connection_request/accepted/rejected）
- [x] 消息发送/接收（Write Request + Notification）

### Phase 3: UI 完善 ✅
- [x] 聊天界面优化（断连警告横幅、消息气泡样式）
- [x] 连接状态指示（首页 + 聊天页）
- [x] 错误处理和提示
- [x] 全局连接请求对话框（_HandshakeHandler）
- [x] Debug 日志面板（底部 160px + 展开全屏）

### Phase 4: 语音消息预留
- [ ] VoiceMessageService 接口
- [ ] 语音消息模型
- [ ] 预留 UI 组件
- [ ] 端到端验证

## BLE 协议

- **协议**: BLE (Bluetooth Low Energy)
- **Service**: Nordic UART Service (`6e400001-b5a3-f393-e0a9-e50e24dcca9e`)
  - TX Characteristic (`6e400002`): Write/WriteWithoutResponse — 接收数据
  - RX Characteristic (`6e400003`): Notify — 发送数据
- **连接模型**: 双方均运行 GATT Server + Client
  - 发起方 (Central): 扫描 → 连接 → GATT Write
  - 接收方 (Peripheral): Advertising → GATT Server → Notification
- **握手协议**: JSON 格式
  ```json
  {"type":"connection_request","name":"设备名"}
  {"type":"connection_accepted","name":"设备名"}
  {"type":"connection_rejected"}
  ```
- **消息编码**: ChatMessage → JSON → UTF-8 字节 → BLE 传输

## 目录结构

```
lib/
├── main.dart
├── app.dart                           # MaterialApp + _HandshakeHandler
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── ble_constants.dart         # NUS UUID、扫描/连接参数
│   └── theme/
│       └── app_theme.dart
├── models/
│   ├── ble_connection_state.dart      # 连接状态枚举 + 扩展方法
│   ├── chat_message.dart              # 消息模型（text/voice/system）
│   └── device_info.dart               # 扫描到的设备信息
├── providers/
│   ├── ble_provider.dart              # 核心蓝牙状态管理（扫描/连接/握手/收发）
│   ├── chat_provider.dart             # 聊天消息列表 + 数据流订阅
│   └── device_list_provider.dart      # 扫描设备列表
├── screens/
│   ├── chat_screen.dart               # 聊天窗口
│   ├── home_screen.dart               # 首页（设为可见/连接状态）
│   ├── scan_screen.dart               # 扫描设备列表
│   └── settings_screen.dart           # 设置
├── services/
│   ├── bluetooth_service.dart         # BLE 扫描（flutter_blue_plus）
│   ├── bluetooth_device_service.dart  # GATT 连接/收发
│   ├── ble_peripheral_service.dart    # GATT Server (EventChannel)
│   ├── message_service.dart           # 消息编解码
│   └── voice_message_service.dart     # 预留
└── widgets/
    ├── message_bubble.dart            # 消息气泡组件
    └── message_input.dart             # 消息输入框
```

## Common Gotchas

### BLE 连接
- `connect()` 首次可能失败（BLE 控制器状态切换），使用 `retryCount: 2` 重试
- 连接时需先 `stopScan()` 避免扫描与连接冲突
- GATT 写入使用 `withoutResponse: false`（Write Request），支持长数据

### EventChannel (GATT Server → Dart)
- `BluetoothGattServerCallback` 在 binder 线程回调
- Flutter 的 `EventSink.success()` 必须在主线程调用
- 必须使用 `Handler(Looper.getMainLooper()).post {}` 包装

### 消息编码
- **禁止**使用 `Uint8List.fromList(str.codeUnits)` — 截断 UTF-16 code units
- **必须**使用 `utf8.encode()` / `utf8.decode()` 处理所有字符串
- JSON 消息含 UUID + 中文约 100+ 字节，连接后需 `requestMtu(517)`

### Advertising
- BLE advertising 包限制 31 字节
- Service UUID 放 advertising data，设备名放 scan response
- Android 12+ 需要 `BLUETOOTH_ADVERTISE` 运行时权限

### Android 权限
- Android 12+: `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` + `BLUETOOTH_ADVERTISE`
- Android 10-11: `ACCESS_FINE_LOCATION`
- 使用 `permission_handler` 统一管理
