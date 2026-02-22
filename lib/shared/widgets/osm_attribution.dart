/// OSM Attribution — Required by OpenStreetMap tile usage policy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Compact OSM attribution overlay for map widgets.
///
/// OpenStreetMap tiles require visible attribution per their terms.
/// Uses flutter_map's built-in RichAttributionWidget for compliance.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      popupInitialDisplayDuration: Duration.zero,
      animationConfig: const ScaleRAWA(),
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: null,
        ),
      ],
    );
  }
}
