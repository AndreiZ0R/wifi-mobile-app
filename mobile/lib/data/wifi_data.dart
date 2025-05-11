class WifiData {
  final String ssid;
  final String mac;
  final String security;
  final int signalStrength;

  WifiData({
    required this.ssid,
    required this.mac,
    required this.security,
    required this.signalStrength,
  });

  factory WifiData.fromJson(Map<String, dynamic> json) {
    return WifiData(
      ssid: json['ssid'],
      mac: json['mac'],
      security: json['security'],
      signalStrength: json['signalStrength'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'mac': mac,
      'security': security,
      'signalStrength': signalStrength,
    };
  }
}
