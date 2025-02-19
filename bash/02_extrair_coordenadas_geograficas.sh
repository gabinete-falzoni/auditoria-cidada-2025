#!/bin/sh

# Tendo a pasta ../dados como referência
TMP_FILES_FOLDER="../dados";
cd $TMP_FILES_FOLDER;

# Extrai as coordenadas geográficas de todas as fotos da pasta em arquivo único
# com nome criado a partir do timestamp. Exemplo: 20250217_185412_fotos.tsv
exiftool -filename -gpslatitude -gpslongitude -T fotos_originais_tmp > "$(date +'%Y%m%d_%H%M%S')_fotos.tsv"
