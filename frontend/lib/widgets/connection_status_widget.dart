// lib/widgets/connection_status_widget.dart
import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/connection/connection_manager.dart';

/// Bağlantı durumunu gösteren widget
class ConnectionStatusWidget extends StatelessWidget {
  final bool showDetails;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ConnectionStatusWidget({
    super.key,
    this.showDetails = false,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionType>(
      stream: ServiceLocator.connection.connectionTypeStream,
      builder: (context, connectionSnapshot) {
        return StreamBuilder<bool>(
          stream: ServiceLocator.connection.isConnectedStream,
          builder: (context, statusSnapshot) {
            final connectionType = connectionSnapshot.data ?? ConnectionType.websocket;
            final isConnected = statusSnapshot.data ?? false;
            
            return Container(
              margin: margin,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(isConnected),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(isConnected).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIcon(isConnected, connectionType),
                  const SizedBox(width: 6),
                  if (showDetails) ...[
                    _buildStatusText(isConnected, connectionType),
                    const SizedBox(width: 4),
                  ],
                  _buildConnectionTypeIcon(connectionType),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusIcon(bool isConnected, ConnectionType connectionType) {
    IconData iconData;
    Color iconColor;
    
    if (isConnected) {
      iconData = Icons.wifi;
      iconColor = Colors.green;
    } else {
      iconData = Icons.wifi_off;
      iconColor = Colors.red;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }

  Widget _buildStatusText(bool isConnected, ConnectionType connectionType) {
    String text;
    Color textColor;
    
    if (isConnected) {
      text = _getConnectionTypeText(connectionType);
      textColor = Colors.green.shade700;
    } else {
      text = 'Bağlantı Yok';
      textColor = Colors.red.shade700;
    }
    
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildConnectionTypeIcon(ConnectionType connectionType) {
    IconData iconData;
    Color iconColor;
    
    switch (connectionType) {
      case ConnectionType.websocket:
        iconData = Icons.flash_on;
        iconColor = Colors.blue;
        break;
      case ConnectionType.sse:
        iconData = Icons.stream;
        iconColor = Colors.orange;
        break;
      case ConnectionType.polling:
        iconData = Icons.refresh;
        iconColor = Colors.grey;
        break;
    }
    
    return Icon(
      iconData,
      size: 14,
      color: iconColor,
    );
  }

  Color _getStatusColor(bool isConnected) {
    if (isConnected) {
      return Colors.green.shade50;
    } else {
      return Colors.red.shade50;
    }
  }

  String _getConnectionTypeText(ConnectionType connectionType) {
    switch (connectionType) {
      case ConnectionType.websocket:
        return 'WebSocket';
      case ConnectionType.sse:
        return 'SSE';
      case ConnectionType.polling:
        return 'Polling';
    }
  }
}

/// Basit bağlantı durumu göstergesi (sadece nokta)
class SimpleConnectionIndicator extends StatelessWidget {
  final double size;
  
  const SimpleConnectionIndicator({
    super.key,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ServiceLocator.connection.isConnectedStream,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.green : Colors.red).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ağ kalitesi göstergesi
class NetworkQualityIndicator extends StatelessWidget {
  final bool showText;
  
  const NetworkQualityIndicator({
    super.key,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkQuality>(
      stream: ServiceLocator.connection.networkQualityStream,
      builder: (context, snapshot) {
        final quality = snapshot.data ?? NetworkQuality.good;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityIcon(quality),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                _getQualityText(quality),
                style: TextStyle(
                  fontSize: 12,
                  color: _getQualityColor(quality),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQualityIcon(NetworkQuality quality) {
    IconData iconData;
    Color iconColor;
    
    switch (quality) {
      case NetworkQuality.excellent:
        iconData = Icons.signal_wifi_4_bar;
        iconColor = Colors.green;
        break;
      case NetworkQuality.good:
        iconData = Icons.wifi;
        iconColor = Colors.blue;
        break;
      case NetworkQuality.poor:
        iconData = Icons.wifi_off;
        iconColor = Colors.orange;
        break;
      case NetworkQuality.offline:
        iconData = Icons.wifi_off;
        iconColor = Colors.red;
        break;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }

  String _getQualityText(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return 'Mükemmel';
      case NetworkQuality.good:
        return 'İyi';
      case NetworkQuality.poor:
        return 'Zayıf';
      case NetworkQuality.offline:
        return 'Çevrimdışı';
    }
  }

  Color _getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.blue;
      case NetworkQuality.poor:
        return Colors.orange;
      case NetworkQuality.offline:
        return Colors.red;
    }
  }
}
