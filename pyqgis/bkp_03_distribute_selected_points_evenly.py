from qgis.PyQt.QtCore import QVariant
from qgis.core import (
    QgsProject,
    QgsGeometry,
    QgsPointXY,
    QgsCoordinateReferenceSystem,
    QgsCoordinateTransform,
    QgsFeatureRequest
)

# --- Get the active layer ---
# layer = iface.activeLayer()
# --- Get the specific layer by name ---
layer = QgsProject.instance().mapLayersByName('gpx_para_revisao')[0]
if not layer or layer.selectedFeatureCount() < 2:
    raise Exception("Select at least 2 points in a point layer")

# --- CRS setup: WGS84 to UTM (you can refine UTM zone based on location) ---
wgs84 = QgsCoordinateReferenceSystem("EPSG:4326")
utm = QgsCoordinateReferenceSystem("EPSG:31983")
transform_to_utm = QgsCoordinateTransform(wgs84, utm, QgsProject.instance())
transform_to_wgs = QgsCoordinateTransform(utm, wgs84, QgsProject.instance())

# --- Get selected points and transform to UTM ---
selected_features = list(layer.selectedFeatures())
points = [(f.id(), transform_to_utm.transform(f.geometry().asPoint())) for f in selected_features]

# --- Sort points by X (or Y, or custom logic) ---
# points.sort(key=lambda tup: tup[1].x())
# Sort by feature ID
points.sort(key=lambda tup: tup[0])  

# --- Compute spacing ---
start_pt = points[0][1]
end_pt = points[-1][1]
total_distance = start_pt.distance(end_pt)
num_intervals = len(points) - 1
dx = (end_pt.x() - start_pt.x()) / num_intervals
dy = (end_pt.y() - start_pt.y()) / num_intervals

# --- Begin editing ---
layer.startEditing()

# --- Move each point to new evenly spaced location ---
for i, (fid, _) in enumerate(points):
    new_x = start_pt.x() + dx * i
    new_y = start_pt.y() + dy * i
    new_point_utm = QgsPointXY(new_x, new_y)
    new_point_wgs = transform_to_wgs.transform(new_point_utm)
    new_geom = QgsGeometry.fromPointXY(new_point_wgs)
    layer.changeGeometry(fid, new_geom)

# --- Commit changes ---
layer.commitChanges()
iface.mapCanvas().refresh()
