# Puxar latitude e longitude originais para duas colunas

from qgis.core import QgsProject, QgsField, QgsFeature
from PyQt5.QtCore import QVariant

# Get the layer by name
track_points_layer = QgsProject.instance().mapLayersByName('gpx_para_revisao')[0]

# Check if the layer exists
if track_points_layer is None:
    print("Layer not found.")
else:
    # Start editing the layer to modify attributes
    track_points_layer.startEditing()

    # Check if the fields 'latitude' and 'longitude' exist
    existing_fields = [field.name() for field in track_points_layer.fields()]

    # Add new fields for latitude and longitude (if not already added)
    if 'lat_orig' not in existing_fields:
        lat_field = QgsField('lat_orig', QVariant.Double)
        track_points_layer.dataProvider().addAttributes([lat_field])

    if 'lon_orig' not in existing_fields:
        lon_field = QgsField('lon_orig', QVariant.Double)
        track_points_layer.dataProvider().addAttributes([lon_field])

    # Update the layer's field definitions
    track_points_layer.updateFields()

    # Get the correct field indexes after adding the new fields
    lat_idx = track_points_layer.fields().indexOf('lat_orig')
    lon_idx = track_points_layer.fields().indexOf('lon_orig')

    # Iterate through features in the layer
    for feature in track_points_layer.getFeatures():
        geometry = feature.geometry()

        # Check if the geometry is a point
        # if geometry.geometryType() == QgsGeometry.Point:
        point = geometry.asPoint()

        # Extract latitude and longitude from the point geometry
        latitude = point.y()  # Latitude is the Y-coordinate
        longitude = point.x()  # Longitude is the X-coordinate

        # Create a dictionary to update the attributes of the feature
        attribute_values = {
            lat_idx: latitude,
            lon_idx: longitude
        }

        # Update the feature with the new attribute values
        track_points_layer.dataProvider().changeAttributeValues({feature.id(): attribute_values})

    # Commit the changes to the layer
    track_points_layer.commitChanges()

    # Trigger layer repaint
    track_points_layer.triggerRepaint()

    print("Latitude and longitude added as new attributes.")
