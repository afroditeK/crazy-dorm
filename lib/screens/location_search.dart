import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//todo is this needed?

class LocationSearchField extends StatefulWidget {
  final Function(String, double, double) onSelect;

  const LocationSearchField({Key? key, required this.onSelect})
      : super(key: key);

  @override
  _LocationSearchFieldState createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _isLoading = false;

  Future<void> _searchLocation(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final url =
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$input&format=json&addressdetails=1&limit=5');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'crazy-dorm' // Nominatim requires a User-Agent header
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions = data;
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Enter location',
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: _searchLocation,
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              final displayName = suggestion['display_name'] ?? '';
              return ListTile(
                title: Text(displayName),
                onTap: () {
                  final lat = double.parse(suggestion['lat']);
                  final lon = double.parse(suggestion['lon']);
                  widget.onSelect(displayName, lat, lon);
                  setState(() {
                    _suggestions = [];
                    _controller.text = displayName;
                  });
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
