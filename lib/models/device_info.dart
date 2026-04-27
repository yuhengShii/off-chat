class DeviceInfo {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
  });

  DeviceInfo copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnected,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
