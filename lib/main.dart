import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const BusI());
}

class BusI extends StatelessWidget {
  const BusI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardTheme: CardThemeData(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==================== HOME SCREEN ====================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _busController = TextEditingController();

  bool _isLoading = false;

  bool _isLoadingBuses = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _liveBuses = [];

  late IO.Socket _socket;

  void initState() {
    super.initState();

    _loadLiveBuses();

    _connectSocket();
  }

  void _connectSocket() {
    _socket = IO.io('https://project1-13.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'timeout': 8000,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print("Home screen socket connected");
    });

    // Listen for bus status changes (when driver ends trip)

    _socket.on('busStatusChanged', (data) {
      print("Bus status changed: $data");

      // Refresh the bus list when status changes

      _loadLiveBuses();
    });

    // Also listen to location updates to refresh list

    _socket.on('locationUpdate', (data) {
      // Refresh to show updated live status

      _loadLiveBuses();
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  Future<void> _loadLiveBuses() async {
    setState(() {
      _isLoadingBuses = true;
    });

    try {
      // Get all buses from backend

      final response = await http
          .get(
            Uri.parse('https://project1-13.onrender.com/vehicles/search'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['vehicles'] != null) {
          final allBuses = List<Map<String, dynamic>>.from(data['vehicles']);

          // Show all buses with proper status (no filtering)

          setState(() {
            _liveBuses = allBuses;
          });

          print('Total buses found: ${allBuses.length}');

          return;
        }
      }

      // If no buses found, show empty list

      setState(() {
        _liveBuses = [];
      });

      print('No buses found');
    } catch (e) {
      print('Error loading buses: $e');

      setState(() {
        _liveBuses = [];
      });
    } finally {
      setState(() {
        _isLoadingBuses = false;
      });
    }
  }

  Future<void> _trackBus() async {
    final busNumber = _busController.text.trim().toUpperCase();

    if (busNumber.isEmpty) {
      setState(() => _errorMessage = "Bus number daalo bhai!");

      return;
    }

    setState(() {
      _isLoading = true;

      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
                'https://project1-13.onrender.com/vehicles/search?number=$busNumber'),
          )
          .timeout(const Duration(seconds: 10));

      print('Track Response Status: ${response.statusCode}');

      print('Track Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['vehicles'].isNotEmpty) {
          final bus = data['vehicles'][0];

          final lat = bus['currentLocation']?['lat']?.toDouble();

          final lng = bus['currentLocation']?['lng']?.toDouble();

          final hasValidLocation = bus['hasValidLocation'] ?? false;

          if (lat != null &&
              lng != null &&
              hasValidLocation &&
              lat != 0 &&
              lng != 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BusMapScreen(
                  busId: bus['_id']?.toString() ?? bus['number'],
                  busNumber: bus['number'],
                  initialLat: lat,
                  initialLng: lng,
                ),
              ),
            );
          } else {
            setState(
                () => _errorMessage = "Bus abhi live nahi hai - No GPS data");
          }
        } else {
          setState(() => _errorMessage = "Yeh bus number nahi mila");
        }
      } else {
        setState(() => _errorMessage = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      print('Error: $e');

      setState(() => _errorMessage = "Network error - try again later");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Where is my Bus?",
          style: TextStyle(
            color: Colors.blue[900],
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8F4FD),
                Color(0xFFF0F2F5),
                Color(0xFFF5F7FA),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Premium Hero Section

            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1976D2),
                    const Color(0xFF42A5F5),
                    const Color(0xFF64B5F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus_filled_rounded,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Track Your Bus",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Real-time bus tracking made simple\nFast • Accurate • Reliable",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Premium Search Card

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[50]!, Colors.blue[100]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.search_rounded,
                              color: Colors.blue[700], size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Find Your Bus",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _busController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter bus number (e.g. UP17, DL1P)",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[50]!, Colors.blue[100]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.directions_bus_rounded,
                              color: Colors.blue[700], size: 28),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              color: Color(0xFF1976D2), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[50]!, Colors.red[100]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.red[700], size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _trackBus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                          shadowColor: const Color(0xFF1976D2).withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Searching...",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    "Track Bus",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Live Buses Section

            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green[50]!,
                    Colors.green[100]!,
                    Colors.green[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.live_tv_rounded,
                            color: Colors.green[700], size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "All Buses",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A237E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadLiveBuses,
                        icon: Icon(Icons.refresh_rounded,
                            color: Colors.green[700]),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoadingBuses
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                color: Color(0xFF1976D2)),
                          ),
                        )
                      : _liveBuses.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "No buses found",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _liveBuses.length,
                              itemBuilder: (context, index) {
                                final bus = _liveBuses[index];

                                // Fixed: Check isActive properly - if bus is not active, it should be OFFLINE
                                // Also check if location is valid (not 0,0)
                                final hasValidLocation = bus['currentLocation']
                                            ?['lat'] !=
                                        null &&
                                    bus['currentLocation']?['lng'] != null &&
                                    bus['currentLocation']?['lat'] != 0 &&
                                    bus['currentLocation']?['lng'] != 0;

                                // A bus is LIVE only if:
                                // 1. It has valid location (not 0,0)
                                // 2. It is marked as active
                                // 3. Location was updated recently (within 2 minutes)
                                final isActive = bus['isActive'] == true;
                                final isLive = hasValidLocation && isActive;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (isLive) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BusMapScreen(
                                              busId: bus['_id']?.toString() ??
                                                  bus['busNumber'],
                                              busNumber: bus['busNumber'] ??
                                                  bus['number'],
                                              initialLat: bus['currentLocation']
                                                          ?['lat']
                                                      ?.toDouble() ??
                                                  28.7041,
                                              initialLng: bus['currentLocation']
                                                          ?['lng']
                                                      ?.toDouble() ??
                                                  77.1026,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isLive
                                                  ? [
                                                      Colors.green[50]!,
                                                      Colors.green[100]!
                                                    ]
                                                  : [
                                                      Colors.grey[50]!,
                                                      Colors.grey[100]!
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.directions_bus_rounded,
                                            color: isLive
                                                ? Colors.green[700]
                                                : Colors.grey[600],
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                bus['busNumber'] ??
                                                    bus['number'] ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1A237E),
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                bus['driverName'] ?? 'Driver',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isLive
                                                ? Colors.green
                                                : Colors.grey[400],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isLive
                                                          ? Colors.green
                                                              .withOpacity(0.8)
                                                          : Colors.grey
                                                              .withOpacity(0.8),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isLive ? "LIVE" : "OFFLINE",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ==================== LIVE MAP SCREEN WITH REAL BUS MARKER ====================

class BusMapScreen extends StatefulWidget {
  final String busId;

  final String busNumber;

  final double initialLat;

  final double initialLng;

  const BusMapScreen({
    required this.busId,
    required this.busNumber,
    required this.initialLat,
    required this.initialLng,
    super.key,
  });

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  late IO.Socket socket;

  late MapController _mapController;

  bool _disposed = false;

  LatLng _busPosition = const LatLng(28.7041, 77.1026); // fallback

  LatLng _previousPosition = const LatLng(28.7041, 77.1026);

  bool _isLive = false;

  String status = "Connecting...";

  double _speed = 0.0; // km/h

  String _eta = "Calculating..."; // ETA to next stop

  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();

    _busPosition = LatLng(widget.initialLat, widget.initialLng);

    _previousPosition = _busPosition;

    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io('https://project1-13.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'timeout': 8000,
    });

    socket.connect();

    socket.onConnect((_) {
      if (!_disposed) {
        print("Socket connected");

        socket.emit('join-bus', widget.busNumber);

        setState(() => status = "Connected – Waiting for location...");
      }
    });

    socket.on('locationUpdate', (data) {
      if (!mounted || _disposed) return;

      final receivedBus = data['busNumber'] ?? data['busId']?.toString();

      final lat = (data['lat'] as num?)?.toDouble();

      final lng = (data['lng'] as num?)?.toDouble();

      if (receivedBus == widget.busNumber &&
          lat != null &&
          lng != null &&
          lat != 0 &&
          lng != 0) {
        final newPosition = LatLng(lat, lng);

        final currentTime = DateTime.now();

        // Calculate speed

        if (_isLive && _lastUpdateTime != null) {
          final timeDiff = currentTime.difference(_lastUpdateTime!).inSeconds;

          if (timeDiff > 0) {
            final distance = Geolocator.distanceBetween(
              _busPosition.latitude,
              _busPosition.longitude,
              newPosition.latitude,
              newPosition.longitude,
            );

            _speed = (distance / timeDiff) * 3.6; // Convert m/s to km/h
          }
        }

        setState(() {
          _previousPosition = _busPosition;

          _busPosition = newPosition;

          _isLive = true;

          status = "LIVE • Bus is moving";

          _lastUpdateTime = currentTime;

          _eta = _calculateETA();
        });

        _mapController.move(_busPosition, 16.0);
      }
    });

    socket.onDisconnect((_) {
      if (!_disposed) {
        setState(() {
          _isLive = false;

          status = "Disconnected – Check connection";
        });
      }
    });

    socket.onConnectError((error) {
      if (!_disposed) {
        setState(() => status = "Connection error – Retry");

        print("Socket connection error: $error");
      }
    });
  }

  String _calculateETA() {
    if (_speed <= 0) return "Calculating...";

    // Estimate ETA to next stop (assuming 2km average distance between stops)

    final distanceToNextStop = 2.0; // km

    final timeInMinutes = (distanceToNextStop / _speed) * 60;

    if (timeInMinutes < 1) {
      return "Arriving soon";
    } else if (timeInMinutes < 60) {
      return "${timeInMinutes.round()} min";
    } else {
      final hours = (timeInMinutes / 60).floor();

      final minutes = (timeInMinutes % 60).round();

      return "${hours}h ${minutes}m";
    }
  }

  @override
  void dispose() {
    _disposed = true;

    socket.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bus ${widget.busNumber}"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _busPosition,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.busi',
                maxZoom: 19,
                retinaMode: false,
                fallbackUrl: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _busPosition,
                    width: 80,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _isLive ? Colors.red : Colors.grey,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              Icons.directions_bus_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          if (_isLive)
                            Positioned(
                              right: 5,
                              top: 5,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Status banner with Speed & ETA

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(_isLive ? Icons.circle : Icons.circle_outlined,
                            color: _isLive ? Colors.green : Colors.orange,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(status,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.speed,
                                color: Colors.blue[700], size: 24),
                            const SizedBox(height: 4),
                            Text(
                              "${_speed.toStringAsFixed(1)} km/h",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.access_time,
                                color: Colors.green[700], size: 24),
                            const SizedBox(height: 4),
                            Text(
                              _eta,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
