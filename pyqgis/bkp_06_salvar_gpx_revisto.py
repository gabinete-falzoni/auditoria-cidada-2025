# Salvar arquivo GPX revisto na pasta, com opções GPX_USE_EXTENSIONS e FORCE_GPX_TRACK

from qgis.core import QgsProject, QgsVectorFileWriter

# Get the layer (replace 'gpx_para_revisao' with your layer name)
layer = QgsProject.instance().mapLayersByName('gpx_para_revisao')[0]
# Define the output file path
# path = '/mnt/fern/Dados/Campo_Camera360/00_pasta_de_trabalho/gpx_revisto.gpx'
path = '/media/livre/Expansion/Dados_Comp_Gabinete/Campo_Camera360/00_pasta_de_trabalho/gpx_revisto.gpx'

# Create SaveVectorOptions instance
save_options = QgsVectorFileWriter.SaveVectorOptions()
save_options.driverName = "GPX"
save_options.fileEncoding = "UTF-8"

# Set GPX-specific options
save_options.datasourceOptions = [
    'GPX_USE_EXTENSIONS=YES',  # Enable extensions for additional fields
    'FORCE_GPX_TRACK=YES'      # Force track creation in GPX format
]

# crs = QgsProject.instance().crs()

# Get the coordinate transform context
transform_context = QgsProject.instance().transformContext()

# Perform the export
_writer = QgsVectorFileWriter.writeAsVectorFormatV3(
  layer,
  path,
  # crs,
  transform_context,
  save_options
)

# Check for errors
if _writer == QgsVectorFileWriter.NoError:
    print("GPX export successful!")
else:
    print(f"GPX export failed: {_writer}")