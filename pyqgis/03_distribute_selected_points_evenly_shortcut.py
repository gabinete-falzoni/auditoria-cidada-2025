def evenly_space_selected_points():
    from qgis.PyQt.QtCore import QVariant
    from qgis.core import (
        QgsProject,
        QgsGeometry,
        QgsPointXY,
        QgsCoordinateReferenceSystem,
        QgsCoordinateTransform,
        QgsFeatureRequest
    )

    # --- Get the specific layer by name ---
    layer = QgsProject.instance().mapLayersByName('gpx_para_revisao')[0]

    # --- Validation checks ---
    if not layer or layer.selectedFeatureCount() < 2:
        raise Exception("Select at least 2 points in a point layer")

    if layer.selectedFeatureCount() == layer.featureCount():
        raise Exception("All points are selected — please select only the ones to space evenly.")

    # --- CRS setup: WGS84 to UTM ---
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

    # Turn "toggle editing" back on to continue editing
    layer.startEditing()

    # Activate the Vertex Tool
    iface.actionVertexTool().trigger()
    
# Using Shortcut for QGIS Processing Script?
# https://gis.stackexchange.com/questions/189108/using-shortcut-for-qgis-processing-script
from PyQt5.QtWidgets import QShortcut
from PyQt5.QtGui import QKeySequence
from PyQt5.QtCore import Qt

# #Assign "Ctrl+1", "Ctrl+2", .. to chgScaleX
# shortcut2 = QShortcut(QKeySequence(Qt.ControlModifier + Qt.Key_2), iface.mainWindow())
shortcut1 = QShortcut(QKeySequence("Shift+D"), iface.mainWindow())
shortcut1.setContext(Qt.ApplicationShortcut)
shortcut1.activated.connect(evenly_space_selected_points)