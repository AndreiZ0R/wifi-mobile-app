import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:mobile/screens/saved_networks_screen.dart';
import 'package:mobile/screens/wifi_detail_screen.dart';
import 'package:mobile/util/snackbar_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WiFiScannerScreen extends StatefulWidget {
  const WiFiScannerScreen({super.key});

  @override
  State<WiFiScannerScreen> createState() => _WiFiScannerScreenState();
}

class _WiFiScannerScreenState extends State<WiFiScannerScreen> {
  List<WiFiAccessPoint> _wifiList = [];
  bool _isScanning = true;
  bool _permissionsGranted = false;
  String? _connectedNetwork;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<WiFiAccessPoint> _filteredWiFiList = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _navigateToNetworkDetails(WiFiAccessPoint wifi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WiFiDetailScreen(
              wifi: wifi,
              isConnected: _connectedNetwork == wifi.ssid,
              onConnectPressed: () {
                Navigator.pop(context);
                _connectToWiFi(wifi.ssid);
              },
              onDisconnectPressed:
                  _connectedNetwork == wifi.ssid
                      ? () async {
                        Navigator.pop(context);

                        try {
                          // First attempt using WiFiForIoTPlugin
                          bool? disconnected;
                          try {
                            disconnected = await WiFiForIoTPlugin.disconnect();
                          } catch (e) {
                            debugPrint('Primary disconnect method failed: $e');
                            disconnected = false;
                          }

                          if (!disconnected) {
                            // Fallback: Use alternative approach for newer Android
                            await _showDisconnectionDialog();
                          } else {
                            setState(() {
                              _connectedNetwork = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Disconnected from WiFi'),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error disconnecting: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        // Refresh current WiFi state after disconnect attempt
                        await _getCurrentWiFi();
                      }
                      : null,
            ),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.location, Permission.nearbyWifiDevices].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) allGranted = false;
    });

    setState(() {
      _permissionsGranted = allGranted;
    });

    if (_permissionsGranted) {
      await _scanForWiFiNetworks();
      await _getCurrentWiFi();
    }
  }

  Future<void> _getCurrentWiFi() async {
    try {
      String? connected = await WiFiForIoTPlugin.getSSID();
      setState(() {
        _connectedNetwork =
            (connected != '<unknown ssid>' && connected != null)
                ? connected
                : null;
      });
    } catch (e) {
      debugPrint('Error getting current WiFi: $e');
      // Try an alternative method for newer Android versions
      try {
        final wifiState = await WiFiForIoTPlugin.isConnected();
        if (!wifiState) {
          setState(() {
            _connectedNetwork = null;
          });
        }
      } catch (e2) {
        debugPrint('Alternative WiFi check also failed: $e2');
      }
    }
  }

  Future<void> _showDisconnectionDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Manual Disconnection Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'On newer Android versions, apps cannot disconnect from WiFi networks directly due to security restrictions.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please follow these steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...[
                  'Open your device Settings',
                  'Go to Connections or Network & Internet',
                  'Tap on Wi-Fi',
                  'Tap on the currently connected network',
                  'Select "Forget" or "Disconnect"',
                ].map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alternatively, you can turn off WiFi temporarily.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  // Mark as disconnected in UI for better UX, even though technically still connected
                  setState(() {
                    _connectedNetwork = null;
                  });
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Open WiFi settings using app_settings package
                  await AppSettings.openAppSettings(type: AppSettingsType.wifi);
                },
                child: const Text('Open WiFi Settings'),
              ),
            ],
          ),
    );
  }

  Future<void> _scanForWiFiNetworks() async {
    if (!_permissionsGranted) {
      await _checkPermissions();
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      // Check if scan can be performed
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        SnackBarUtil.showErrorSnackBar(
          context,
          "Cannot scan for networks at this time",
        );
        setState(() {
          _isScanning = false;
        });
        return;
      }

      // Start scan
      final result = await WiFiScan.instance.startScan();

      // Get scan results
      if (result) {
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Give time for scan to complete
        final results = await WiFiScan.instance.getScannedResults();

        // Filter out empty SSIDs and sort by signal strength
        final filtered =
            results.where((ap) => ap.ssid.isNotEmpty).toList()
              ..sort((a, b) => b.level.compareTo(a.level));

        setState(() {
          _wifiList = filtered;
          _filteredWiFiList = filtered;
          _isScanning = false;
        });
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error scanning WiFi: $e');
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: ${e.toString()}')),
      );
    }
  }

  Future<void> _connectToWiFi(String ssid) async {
    String password = '';
    bool cancelled = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Connect to $ssid'),
          content: TextField(
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (value) => password = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );

    if (cancelled || password.isEmpty) return;

    // Show connecting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting...'),
              ],
            ),
          ),
    );

    try {
      // Attempt to determine security type (this is a simplification)
      NetworkSecurity security = NetworkSecurity.WPA;

      // First disconnect from any current network
      await WiFiForIoTPlugin.disconnect();

      // Try to connect
      bool connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: security,
        joinOnce: true,
        withInternet: true,
      );

      // Close the progress dialog
      Navigator.pop(context);

      if (connected) {
        setState(() {
          _connectedNetwork = ssid;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $ssid'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to $ssid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close the progress dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Refresh the current connection state
    await _getCurrentWiFi();
  }

  Widget _buildNetworkIcon(WiFiAccessPoint wifi) {
    int signalLevel = 0;

    if (wifi.level >= -50) {
      signalLevel = 4; // Excellent
    } else if (wifi.level >= -60) {
      signalLevel = 3; // Good
    } else if (wifi.level >= -70) {
      signalLevel = 2; // Fair
    } else {
      signalLevel = 1; // Poor
    }

    IconData icon;
    switch (signalLevel) {
      case 4:
        icon = Icons.signal_wifi_4_bar;
        break;
      case 3:
        icon = Icons.network_wifi;
        break;
      case 2:
        icon = Icons.signal_wifi_4_bar_lock;
        break;
      default:
        icon = Icons.signal_wifi_0_bar;
    }

    return Icon(
      icon,
      color: _connectedNetwork == wifi.ssid ? Colors.green : Colors.grey,
    );
  }

  void _filterWiFiList(String query) {
    final filtered =
        _wifiList.where((ap) {
          return ap.ssid.toLowerCase().contains(query.toLowerCase());
        }).toList();

    setState(() {
      _filteredWiFiList = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search by SSID...',
                    border: InputBorder.none,
                  ),
                  onChanged: _filterWiFiList,
                )
                : const Text("Available networks"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredWiFiList = _wifiList;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForWiFiNetworks,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedNetworksScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body:
          !_permissionsGranted
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Location permission is required to scan WiFi networks',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      child: const Text('Grant Permissions'),
                    ),
                  ],
                ),
              )
              : _isScanning
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning for WiFi networks...'),
                  ],
                ),
              )
              : _wifiList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No WiFi networks found',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                      onPressed: _scanForWiFiNetworks,
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _scanForWiFiNetworks,
                      child: ListView.builder(
                        itemCount: _filteredWiFiList.length,
                        itemBuilder: (context, index) {
                          final wifi = _filteredWiFiList[index];
                          final isConnected = _connectedNetwork == wifi.ssid;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            elevation: isConnected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  isConnected
                                      ? const BorderSide(
                                        color: Colors.green,
                                        width: 2,
                                      )
                                      : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: _buildNetworkIcon(wifi),
                              title: Text(
                                wifi.ssid,
                                style: TextStyle(
                                  fontWeight:
                                      isConnected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Signal: ${wifi.level} dBm${isConnected ? ' • Connected' : ''}',
                              ),
                              trailing:
                                  isConnected
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                              onTap:
                                  isConnected
                                      ? () => _navigateToNetworkDetails(wifi)
                                      : () => _navigateToNetworkDetails(wifi),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
