import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SimpleMapPicker extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final bool isReadOnly;

  const SimpleMapPicker({
    Key? key, 
    required this.onLocationSelected,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<SimpleMapPicker> createState() => _SimpleMapPickerState();
}

class _SimpleMapPickerState extends State<SimpleMapPicker> {
  LatLng _currentCenter = const LatLng(11.0168, 76.9558); // Default to Coimbatore
  
  String _addressName = '';
  String _addressDetails = '';
  
  bool _isLoadingAddress = false;
  final MapController _mapController = MapController();
  
  Timer? _moveDebounce;
  Timer? _searchDebounce;

  List<Marker> _poiMarkers = [];
  bool _isLoadingPOIs = false;

  @override
  void initState() {
    super.initState();
    _getAddress(_currentCenter.latitude, _currentCenter.longitude);
    Future.delayed(const Duration(seconds: 1), _scanArea);
  }

  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    if (_moveDebounce?.isActive ?? false) _moveDebounce!.cancel();
    
    _moveDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted && position.center != null) {
        setState(() {
          _currentCenter = position.center!;
        });
        _getAddress(position.center!.latitude, position.center!.longitude);
        _scanArea();
      }
    });
  }

  Future<void> _getAddress(double lat, double lon) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddress = true;
      _addressName = "";
      _addressDetails = "Fetching...";
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1&extratags=1&namedetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.solar.dashboard/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
             _parseAddressResult(data);
        }
      } else {
        if (mounted) setState(() => _addressDetails = "Failed to fetch address");
      }
    } catch (e) {
      if (mounted) setState(() => _addressDetails = "Error fetching address");
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  String _formatConciseAddress(dynamic props) {
      if (props == null) return "";

      List<String> parts = [];
      String mainPlace = props['city'] ?? props['town'] ?? props['village'] ?? props['suburb'] ?? props['quarter'] ?? '';
      if (mainPlace.isNotEmpty) parts.add(mainPlace);

      String district = props['state_district'] ?? props['county'] ?? '';
      if (district.isNotEmpty && !parts.contains(district)) parts.add(district);

      String state = props['state'] ?? '';
      if (state.isNotEmpty && !parts.contains(state)) parts.add(state);

      String country = props['country'] ?? '';
      if (country.isNotEmpty) parts.add(country);

      String postcode = props['postcode'] ?? '';
      if (postcode.isNotEmpty) parts.add(postcode);
      
      return parts.join(', ');
  }

  void _parseAddressResult(dynamic data) {
      String name = '';
      if (data['namedetails'] != null && data['namedetails']['name'] != null) {
          name = data['namedetails']['name'];
      } else if (data['address'] != null) {
          final addr = data['address'];
          if (addr['amenity'] != null) name = addr['amenity'];
          else if (addr['shop'] != null) name = addr['shop'];
          else if (addr['office'] != null) name = addr['office'];
          else if (addr['tourism'] != null) name = addr['tourism'];
          else if (addr['building'] != null) name = addr['building'];
          else if (addr['leisure'] != null) name = addr['leisure'];
      }

      String details = "";
      if (data['address'] != null) {
          details = _formatConciseAddress(data['address']);
      } else {
          details = data['display_name'] ?? ''; 
      }
      
      if (name == details.split(',').first) {
          name = "";
      }

      setState(() {
          _addressName = name;
          _addressDetails = details;
      });
  }

  Future<void> _scanArea() async {
    if (!mounted) return;
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=&lat=${_currentCenter.latitude}&lon=${_currentCenter.longitude}&limit=40', 
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        List<Marker> newMarkers = [];

        for (var feature in features) {
          final coords = feature['geometry']['coordinates'];
          final lat = coords[1].toDouble();
          final lon = coords[0].toDouble();
          final props = feature['properties'];
          
          if (props['name'] == null) continue;

          String type = props['osm_value'] ?? 'poi';
          
          IconData icon = Icons.circle;
          Color color = Colors.blueAccent; 
          double size = 12;

          if (type == 'restaurant' || type == 'cafe') { icon = Icons.restaurant; color = Colors.orange; size = 20; }
          else if (type == 'shop' || type == 'supermarket') { icon = Icons.shopping_bag; color = Colors.purple; size = 20; }
          else if (type == 'bank' || type == 'atm') { icon = Icons.attach_money; color = Colors.green; size = 20; }
          else if (type == 'pharmacy' || type == 'hospital') { icon = Icons.local_hospital; color = Colors.red; size = 20; }
          else if (type == 'school' || type == 'college') { icon = Icons.school; color = Colors.brown; size = 20; }
          else if (type == 'company' || type == 'office') { icon = Icons.business; color = Colors.indigo; size = 20; }

          newMarkers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 35,
              height: 35,
              child: GestureDetector(
                onTap: () => _selectSearchResult(feature), 
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black38)]
                  ),
                  child: Icon(icon, color: color, size: size),
                ),
              ),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _poiMarkers = newMarkers;
          });
        }
      }
    } catch (e) {
    }
  }

  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () { 
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
       if (mounted) setState(() => _searchResults = []);
       return;
    }
    if (mounted) setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=$query&limit=8', 
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          final data = json.decode(response.body);
          setState(() {
            _searchResults = data['features']; 
          });
        }
      }
    } catch (e) {
       print("Error searching: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic feature) {
    final coords = feature['geometry']['coordinates'];
    double lon = coords[0].toDouble();
    double lat = coords[1].toDouble();
    LatLng selectedPoint = LatLng(lat, lon);

    final props = feature['properties'];
    String name = props['name'] ?? props['street'] ?? '';
    String details = _formatConciseAddress(props);

    setState(() {
      _currentCenter = selectedPoint; 
      _addressName = name;
      _addressDetails = details;
      _searchResults = []; 
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
    
    _mapController.move(selectedPoint, 17.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "View Location" : "Pick Location"),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                 String finalAddr = _addressName.isNotEmpty 
                    ? "$_addressName, $_addressDetails" 
                    : _addressDetails;
                 
                widget.onLocationSelected(_currentCenter);
                Navigator.pop(context, {
                  'latitude': _currentCenter.latitude,
                  'longitude': _currentCenter.longitude,
                  'address': finalAddr,
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onPositionChanged: _onMapPositionChanged,
              onTap: widget.isReadOnly ? null : (tapPosition, point) {
                 setState(() {
                  _currentCenter = point;
                });
                _mapController.move(point, _mapController.camera.zoom);
                _getAddress(point.latitude, point.longitude);
              },
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.solar.dashboard',
              ),
              MarkerLayer(markers: _poiMarkers),
            ],
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0),
              child: Icon(Icons.location_on, color: Colors.blueAccent, size: 50), 
            ),
          ),
          
          if (!widget.isReadOnly)
          Positioned(
            top: 10, left: 10, right: 10,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search here...",
                      contentPadding: const EdgeInsets.all(12),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                    ),
                    onChanged: (val) { setState((){}); _onSearchChanged(val); },
                    onSubmitted: (value) {
                       FocusScope.of(context).unfocus();
                       _searchPlaces(value);
                    },
                  ),
                ),
                if (_isSearching) Container(height: 2, child: LinearProgressIndicator()),
                
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: ListView.builder(
                      padding: EdgeInsets.zero, shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                          final feature = _searchResults[index];
                          final props = feature['properties'];
                          String title = props['name'] ?? props['street'] ?? "Unknown";
                          String subtitle = props['city'] ?? props['country'] ?? "";
                          return ListTile(
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(subtitle),
                            onTap: () => _selectSearchResult(feature),
                          );
                      },
                    ),
                  )
              ],
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (_isLoadingAddress) 
                      const Center(child: LinearProgressIndicator())
                   else ...[
                      if (_addressName.isNotEmpty) 
                        Text(_addressName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      
                      const SizedBox(height: 4),
                      Text(_addressDetails.isNotEmpty ? _addressDetails : "Unknown Location", 
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]), 
                        maxLines: 2
                      ),
                   ],
                  
                  const SizedBox(height: 12),
                  if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        String finalAddr = _addressName.isNotEmpty 
                           ? "$_addressName, $_addressDetails" 
                           : _addressDetails;

                        Navigator.pop(context, {
                          'latitude': _currentCenter.latitude, 
                          'longitude': _currentCenter.longitude, 
                          'address': finalAddr
                        });
                      },
                      child: const Text("Confirm Location", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
