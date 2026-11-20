import 'package:flutter/material.dart';

class DiscoveryMobileView extends StatefulWidget {
  const DiscoveryMobileView({
    super.key,
    required this.search,
    required this.list,
    required this.map,
    required this.onMapSelected,
    required this.onMapHidden,
  });

  final Widget search;
  final Widget list;
  final Widget map;
  final VoidCallback onMapSelected;
  final VoidCallback onMapHidden;

  @override
  State<DiscoveryMobileView> createState() => _DiscoveryMobileViewState();
}

class _DiscoveryMobileViewState extends State<DiscoveryMobileView> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: widget.search),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Liste'),
              icon: Icon(Icons.list),
            ),
            ButtonSegment(
              value: true,
              label: Text('Carte'),
              icon: Icon(Icons.map_outlined),
            ),
          ],
          selected: {_showMap},
          onSelectionChanged: (values) {
            setState(() => _showMap = values.first);
            if (_showMap) widget.onMapSelected();
            if (!_showMap) widget.onMapHidden();
          },
        ),
        const SizedBox(height: 8),
        Expanded(child: _showMap ? widget.map : widget.list),
      ],
    );
  }
}
