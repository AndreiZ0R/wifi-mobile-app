import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/config_loader.dart';
import 'package:mobile/util/snackbar_util.dart';

import '../data/wifi_data.dart';

class SavedNetworksScreen extends StatefulWidget {
  const SavedNetworksScreen({super.key});

  @override
  State<SavedNetworksScreen> createState() => _SavedNetworksScreenState();
}

class _SavedNetworksScreenState extends State<SavedNetworksScreen> {
  late Future<List<WifiData>> _futureNetworks;

  @override
  void initState() {
    super.initState();
    _futureNetworks = _fetchSavedNetworks();
  }

  Future<List<WifiData>> _fetchSavedNetworks() async {
    final response = await http.get(
      Uri.parse('${ConfigLoader.serverUri}/networks'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => WifiData.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load saved networks');
    }
  }

  Future<void> _deleteNetwork(String mac, BuildContext context) async {
    final response = await http.delete(
      Uri.parse('${ConfigLoader.serverUri}/networks/$mac'),
    );

    if (response.statusCode != 200) {
      SnackBarUtil.showErrorSnackBar(
        context,
        'Failed to delete network with mac $mac',
      );
    } else {
      SnackBarUtil.showSuccessSnackBar(context, "Deleted $mac");
    }
  }

  Widget _buildNetworkTile(WifiData network, BuildContext context) {
    return Dismissible(
      key: Key(network.mac),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text('Delete saved network "${network.ssid}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        await _deleteNetwork(network.mac, context);
        setState(() {
          _futureNetworks = _fetchSavedNetworks();
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.wifi),
          title: Text(
            network.ssid,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: Text(
            'MAC: ${network.mac}\nSecurity: ${network.security}\nSignal: ${network.signalStrength} dBm',
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved WiFi Networks')),
      body: FutureBuilder<List<WifiData>>(
        future: _futureNetworks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Failed to fetch saved networks, please try again.'),
            );
          } else if (snapshot.hasData) {
            final networks = snapshot.data!;
            if (networks.isEmpty) {
              return const Center(child: Text('No saved networks found.'));
            }
            return ListView.builder(
              itemCount: networks.length,
              itemBuilder:
                  (context, index) =>
                      _buildNetworkTile(networks[index], context),
            );
          } else {
            return const Center(child: Text('Unknown error occurred.'));
          }
        },
      ),
    );
  }
}
