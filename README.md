# OffChat

基于 BLE（低功耗蓝牙）的离线聊天应用，支持 Android/iOS。无需互联网，无需服务器，两台手机通过 BLE 直接通信。

## 功能

- **设备发现**: BLE 扫描附近设备（Nordic UART Service 过滤）
- **设为可见**: BLE Advertising，让其他设备发现你
- **连接握手**: 请求 → 接受/拒绝，全局对话框提示
- **文本聊天**: 发送和接收文字消息（支持中文、emoji）
- **断连检测**: 连接断开时自动提示

## 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter + flutter_blue_plus |
| 状态管理 | Provider |
| BLE协议 | Nordic UART Service (NUS) |
| GATT 服务端 | Kotlin (Android) / Swift (iOS) |
| 消息格式 | JSON over BLE (UTF-8 编码) |

## 架构

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                       │
│  HomeScreen / ScanScreen / ChatScreen           │
├─────────────────────────────────────────────────┤
│               Provider Layer                    │
│  BleProvider / ChatProvider / DeviceListProvider│
├─────────────────────────────────────────────────┤
│               Service Layer                     │
│  BluetoothService  → BLE 扫描                   │
│  BluetoothDeviceService → GATT 连接/收发        │
│  BlePeripheralService → GATT Server             │
│  MessageService → 消息编解码                    │
├─────────────────────────────────────────────────┤
│               Native Layer                      │
│  BleGattServer.kt (Android)                     │
│  BleGattServer.swift (iOS)                      │
└─────────────────────────────────────────────────┘
```

## 开发

```bash
# 获取依赖
flutter pub get

# 运行
flutter run

# Lint 检查
flutter analyze

# 运行测试（86 个）
flutter test

# 构建 APK
flutter build apk --debug --target-platform android-arm64  # BKQ AN10
flutter build apk --debug --target-platform android-arm    # Redmi 3
```

## BLE 通信协议

### Service
- **UUID**: `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- TX Characteristic (`6e400002`): Write Request — 接收数据
- RX Characteristic (`6e400003`): Notify — 发送数据

### 握手流程
```
扫描方                         可见方
  │                              │
  ├── GATT 连接 ──────────────►  │
  ├── connection_request ──────►  ├── 弹窗提示
  │                              │
  │◄── connection_accepted ──────┤ (用户接受)
  │                              │
  └── 进入聊天 ──────────────►  └── 进入聊天
```

### 消息编码
- `ChatMessage` → `jsonEncode()` → `utf8.encode()` → BLE
- BLE → `utf8.decode()` → `jsonDecode()` → `ChatMessage`

## 测试设备

- **BKQ AN10**: Android 16 (API 36) — arm64
- **Redmi 3**: Android 10 (API 29) — arm
