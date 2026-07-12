/// Built-in basemap choices for the map view. Overlays from the layer
/// catalog render on top of the selected basemap.
enum Basemap {
  osm(
    label: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxZoom: 19,
  ),
  esriImagery(
    label: 'Esri Imagery',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    maxZoom: 19,
  ),
  esriStreets(
    label: 'Esri Streets',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    maxZoom: 19,
  ),
  cartoLight(
    label: 'Carto Light',
    urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    maxZoom: 20,
  );

  const Basemap({
    required this.label,
    required this.urlTemplate,
    required this.maxZoom,
  });

  final String label;
  final String urlTemplate;
  final int maxZoom;

  static Basemap fromName(String name) => Basemap.values.firstWhere(
        (b) => b.name == name,
        orElse: () => Basemap.osm,
      );
}
