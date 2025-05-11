import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/config_loader.dart';
import 'package:mobile/util/snackbar_util.dart';
import 'package:mobile/util/wifi_util.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../data/wifi_data.dart';

class WiFiDetailScreen extends StatelessWidget {
  final WiFiAccessPoint wifi;
  final bool isConnected;
  final VoidCallback onConnectPressed;
  final VoidCallback? onDisconnectPressed;

  const WiFiDetailScreen({
    super.key,
    required this.wifi,
    required this.isConnected,
    required this.onConnectPressed,
    this.onDisconnectPressed,
  });

  Color _getSignalStrengthColor(int level) {
    if (level >= -50) {
      return Colors.green;
    } else if (level >= -60) {
      return Colors.lightGreen;
    } else if (level >= -70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getWifiIcon(int level) {
    if (level >= -50) {
      return Icons.signal_wifi_4_bar;
    } else if (level >= -60) {
      return Icons.network_wifi;
    } else if (level >= -70) {
      return Icons.signal_wifi_4_bar_lock;
    } else {
      return Icons.signal_wifi_0_bar;
    }
  }

  String _getApproximateRange(int level) {
    if (level >= -50) {
      return "Very close (< 10m)";
    } else if (level >= -60) {
      return "Close (10-20m)";
    } else if (level >= -70) {
      return "Medium (20-40m)";
    } else if (level >= -80) {
      return "Far (40-70m)";
    } else {
      return "Very far (> 70m)";
    }
  }

  Future<void> _sendNetworkInfoToServer(BuildContext context) async {
    final uri = Uri.parse('${ConfigLoader.serverUri}/networks');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          WifiData(
            ssid: wifi.ssid,
            mac: wifi.bssid,
            security: WifiUtil.getSecurityTypeString(wifi.capabilities),
            signalStrength: wifi.level,
          ).toJson(),
        ),
      );

      SnackBarUtil.showSuccessSnackBar(context, "Successfully saved network");
    } catch (e) {
      debugPrint(e.toString());
      SnackBarUtil.showErrorSnackBar(context, "Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    String securityType = WifiUtil.getSecurityTypeString(wifi.capabilities);
    String frequencyBand = WifiUtil.getFrequencyBand(wifi.frequency);
    String signalStrength = WifiUtil.getSignalStrengthText(wifi.level);
    int approximateChannel = WifiUtil.calculateApproximateChannel(
      wifi.frequency,
    );
    Color signalColor = _getSignalStrengthColor(wifi.level);
    String approximateRange = _getApproximateRange(wifi.level);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Network Details',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Send Network Info',
            onPressed: () => _sendNetworkInfoToServer(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Network header
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    _getWifiIcon(wifi.level),
                    size: 72,
                    color: isConnected ? Colors.green : signalColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    wifi.ssid,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isConnected
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isConnected ? 'Connected' : securityType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isConnected && securityType == "Open (No Security)")
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Signal strength indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Signal Strength: $signalStrength",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "${wifi.level} dBm",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: signalColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (wifi.level + 100) / 60,
                      // Normalize from -100...-40 to 0...1
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(signalColor),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Network information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NETWORK INFORMATION",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Network info items
                  _buildInfoItem("Security", securityType, context),
                  _buildInfoItem(
                    "Standard",
                    "802.11${wifi.standard.name}",
                    context,
                  ),
                  _buildInfoItem("BSSID (MAC)", wifi.bssid, context),
                  _buildInfoItem("Frequency", "${wifi.frequency} MHz", context),
                  _buildInfoItem("Band", frequencyBand, context),
                  if (approximateChannel > 0)
                    _buildInfoItem(
                      "Channel",
                      approximateChannel.toString(),
                      context,
                    ),
                  _buildInfoItem("Estimated Range", approximateRange, context),
                  if (wifi.is80211mcResponder ?? false)
                    _buildInfoItem(
                      "Wi-Fi RTT",
                      "Supported (802.11mc)",
                      context,
                    ),
                  if (wifi.isPasspoint ?? false)
                    _buildInfoItem(
                      "Passpoint (Hotspot 2.0)",
                      "Supported",
                      context,
                    ),
                  if (wifi.channelWidth != null)
                    _buildInfoItem(
                      "Channel Width",
                      "${wifi.channelWidth?.name.replaceAll("mhz", "")} MHz",
                      context,
                    ),
                  _buildFullCapabilities(
                    "Full Capabilities",
                    wifi.capabilities.replaceAll("]", "").split("["),
                    context,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Connection buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child:
                  isConnected
                      ? ElevatedButton.icon(
                        onPressed: onDisconnectPressed,
                        icon: const Icon(Icons.close),
                        label: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[100],
                          foregroundColor: Colors.red[800],
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      )
                      : ElevatedButton.icon(
                        onPressed: onConnectPressed,
                        icon: const Icon(Icons.wifi),
                        label: Text(
                          securityType == "Open (No Security)"
                              ? 'Connect'
                              : 'Connect with Password',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCapabilities(
    String title,
    List<String> values,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  values.map((capability) {
                    return Text(
                      capability.trim(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
