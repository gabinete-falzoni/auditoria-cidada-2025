# Pega as coordenadas das colunas de latitude e longitude e aplica como o geometry
# da camada (somente para os pontos selecionados)

from qgis.core import QgsProject, QgsGeometry, QgsPointXY

# Get the layer by name
track_points_layer = QgsProject.instance().mapLayersByName('20250218_auditoria')[0]

# Check if the layer exists
if track_points_layer is None:
    print("Layer not found.")
else:
    # Start editing the layer to modify geometries
    track_points_layer.startEditing()

    # Iterate through selected features
    for feature in track_points_layer.selectedFeatures():
        # Get the latitude and longitude values from the attributes
        latitude = feature['lat']
        longitude = feature['lon']

        # Create a new QgsPointXY from the latitude and longitude
        new_point = QgsPointXY(longitude, latitude)

        # Create a new geometry from the point
        new_geom = QgsGeometry.fromPointXY(new_point)

        # Update the geometry of the feature with the new geometry
        track_points_layer.dataProvider().changeGeometryValues({feature.id(): new_geom})

    # Commit the changes to the layer
    track_points_layer.commitChanges()

    # Trigger layer repaint
    track_points_layer.triggerRepaint()

    print("Selected points' geometries updated based on latitude and longitude.")
