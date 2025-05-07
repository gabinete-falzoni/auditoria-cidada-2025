#!/bin/sh

# Tendo a pasta ../dados como referência
FIELD_MEASUREMENTS_FOLDER="../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/fotos_originais/fotos_medicoes_campo/";

cd $FIELD_MEASUREMENTS_FOLDER
rm 00_fotos_medicao.tsv

# Extrai as coordenadas geográficas de todas as fotos da pasta em arquivo único
# com nome criado a partir do timestamp. Exemplo: 20250217_185412_fotos.tsv
#exiftool -filename -gpslatitude -gpslongitude -T $PROCESSED_FILES_FOLDER_FINAL > "00_$(date +'%Y%m%d_%H%M%S')_fotos_todas.tsv"
echo "Processando pasta: $FIELD_MEASUREMENTS_FOLDER"; 
exiftool -filename -gpslatitude -gpslongitude -T $FIELD_MEASUREMENTS_FOLDER > "00_fotos_medicao.tsv"

echo "Feito."; 
