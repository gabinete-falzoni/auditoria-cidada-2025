# Salvar arquivo GPX revisto na pasta, com opções GPX_USE_EXTENSIONS e FORCE_GPX_TRACK

from qgis.core import QgsProject, QgsVectorFileWriter

# Parte 1. Garantir que arquivo será "fechado" após o layer.startEditing()
# do script de distribuição espacial de pontos. Como ele mantém a camada
# aberta a edição, os arquivos .gpkg-shm e .gpkg-wal ainda estão na pasta. A
# camada precisa ser encerrada - vamos fazer isso salvando-a, removendo-a
# do projeto e reinserindo-a novamente.
layer_name = 'gpx_para_revisao'
layer_path = '/media/livre/Expansion/Dados_Comp_Gabinete/Campo_Camera360/00_pasta_de_trabalho/gpx_para_revisao.gpkg'

# Get layer
layer = QgsProject.instance().mapLayersByName(layer_name)[0]

# Commit or roll back edits
if layer.isEditable():
    # Optionally test if there are changes
    if layer.isModified():        
        layer.commitChanges()  # Save edits
    else:        
        layer.rollBack()       # No changes, just exit editing mode

# Remove layer from project (this deletes the C++ object)
QgsProject.instance().removeMapLayer(layer)

# Recreate a new instance of the layer from file
uri = f"{layer_path}|layername={layer_name}"
new_layer = QgsVectorLayer(uri, layer_name, "ogr")

if new_layer.isValid():
    QgsProject.instance().addMapLayer(new_layer)
    # Show feature count
    QgsProject.instance().layerTreeRoot().findLayer(new_layer.id()).setCustomProperty("showFeatureCount", True)

else:
    print("Failed to reload the layer.")


# Parte 2. Exportar a camada como .gpx

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