from qgis.core import QgsProject, QgsSpatialIndex, QgsGeometry, QgsPointXY, QgsMapLayer, QgsField
from PyQt5.QtCore import QVariant

# Get the layers
gpx_layer = QgsProject.instance().mapLayersByName('20250218_auditoria')[0]
network_layer = QgsProject.instance().mapLayersByName('86157_ciclovias_ciclofaixas_points')[0]

# Check if the layers are valid
if not gpx_layer or not network_layer:
    print("One of the layers is not found.")
else:
    # Start editing the gpx layer
    gpx_layer.startEditing()

    # Create spatial index for network_points for faster lookup
    network_index = QgsSpatialIndex(network_layer.getFeatures())

    # Get selected features from both layers
    selected_gpx_features = gpx_layer.selectedFeatures()
    selected_network_features = network_layer.selectedFeatures()

    # Sort the selected gpx_features based on ordem_pontos to ensure sequential order
    selected_gpx_features = sorted(selected_gpx_features, key=lambda f: f['ordem_pontos'])

    # Track the last fid and ordem_pontos used for network_layer
    last_fid = -1  # Start with an impossible fid value to allow the first association
    last_ordem_pontos = -1  # Start with an impossible ordem_pontos to allow the first association

    # Add new columns for latitude and longitude if they do not already exist
    if 'new_lat' not in [field.name() for field in gpx_layer.fields()]:
        gpx_layer.dataProvider().addAttributes([QgsField('new_lat', QVariant.Double)])
    if 'new_lon' not in [field.name() for field in gpx_layer.fields()]:
        gpx_layer.dataProvider().addAttributes([QgsField('new_lon', QVariant.Double)])
    gpx_layer.updateFields()  # Apply changes to the layer's field structure

    # Iterate through the sorted track_points based on ordem_pontos
    for gpx_feat in selected_gpx_features:
        gpx_geom = gpx_feat.geometry()
        gpx_point = gpx_geom.asPoint()

        current_ordem_pontos = gpx_feat['ordem_pontos']
        print(f"Processing track_point with ordem_pontos = {current_ordem_pontos}")

        # Initialize variables to track the closest network point
        closest_network_point = None
        closest_distance = float('inf')  # Start with an infinitely large distance

        # Find the nearest features in network_points using spatial index
        nearest_ids = network_index.nearestNeighbor(gpx_point, len(selected_network_features))
        nearest_features = [network_layer.getFeature(fid) for fid in nearest_ids]

        # Loop through the nearest features and calculate the actual distance
        for network_feat in nearest_features:
            network_geom = network_feat.geometry()
            network_point = network_geom.asPoint()
            distance = gpx_point.distance(network_point)  # Actual distance calculation

            if distance < closest_distance:
                closest_network_point = network_feat
                closest_distance = distance

        if closest_network_point:
            # Update the geometry of the gpx point to match the network point
            network_point = closest_network_point.geometry().asPoint()
            print(f"Associated to network point with fid = {closest_network_point['fid']} and distance = {closest_distance}")

            new_geom = QgsGeometry.fromPointXY(QgsPointXY(network_point.x(), network_point.y()))
            gpx_layer.dataProvider().changeGeometryValues({gpx_feat.id(): new_geom})

            # Update the new_lat and new_lon attributes with the new coordinates
            new_lat = network_point.y()
            new_lon = network_point.x()

            # Set the values for new_lat and new_lon
            gpx_layer.dataProvider().changeAttributeValues({gpx_feat.id(): {gpx_layer.fields().indexOf('new_lat'): new_lat,
                                                                            gpx_layer.fields().indexOf('new_lon'): new_lon}})

            # Update last_fid and last_ordem_pontos to the current values
            last_fid = closest_network_point['fid']
            last_ordem_pontos = current_ordem_pontos
        else:
            print(f"No suitable network point found for track point {current_ordem_pontos}")

    # Commit changes to the layer
    gpx_layer.commitChanges()

    # Trigger layer repaint
    gpx_layer.triggerRepaint()

    # Ensure the map is refreshed and zoom to the extent of the updated layer
    iface.mapCanvas().refresh()  # Refresh the canvas to reflect changes

    print("Changes applied, new lat/lon saved, and map view updated.")
