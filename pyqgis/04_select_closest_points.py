from qgis.core import (
    QgsProject,
    QgsCoordinateReferenceSystem,
    QgsCoordinateTransform,
    QgsFeatureRequest,
    QgsGeometry
)

# Load layers
ref_layer = QgsProject.instance().mapLayersByName('gpx_para_revisao')[0]
target_layer = QgsProject.instance().mapLayersByName('sao_paulo_osm_filtrado_points_wgs84')[0]

# Reprojection: WGS84 to UTM (adjust zone if needed)
wgs84 = QgsCoordinateReferenceSystem("EPSG:4326")
utm = QgsCoordinateReferenceSystem("EPSG:31983")  # Example: SIRGAS 2000 / UTM zone 23S (for São Paulo area)
to_utm = QgsCoordinateTransform(wgs84, utm, QgsProject.instance())
to_wgs = QgsCoordinateTransform(utm, wgs84, QgsProject.instance())

# Collect all buffer geometries from ref_layer (transformed to UTM and buffered)
buffer_geoms = []
for feat in ref_layer.getFeatures():
    geom = feat.geometry()
    geom_utm = QgsGeometry(geom)
    geom_utm.transform(to_utm)
    buffer = geom_utm.buffer(15, 8)  # 10 meter buffer, 8 segments
    buffer_geoms.append(buffer)

# Merge all buffers into one geometry (optional for speed)
from functools import reduce
buffer_union = reduce(lambda g1, g2: g1.combine(g2), buffer_geoms)

# Select points in target_layer that intersect buffer
target_layer.removeSelection()
for feat in target_layer.getFeatures():
    geom = feat.geometry()
    geom_utm = QgsGeometry(geom)
    geom_utm.transform(to_utm)
    if buffer_union.intersects(geom_utm):
        target_layer.select(feat.id())

# Optional: zoom to selected
iface.mapCanvas().zoomToSelected(target_layer)
