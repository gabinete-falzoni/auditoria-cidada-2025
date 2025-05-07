#!/bin/sh

# Tendo a pasta ../dados como referência
PHOTOS_SMALL_FOLDER="../dados/fotos";
PROCESSED_FILES_FOLDER_FINAL="fotos_reduzidas";
PROCESSED_FILES_FOLDER_THEME="fotos_tematicas";

cd $PHOTOS_SMALL_FOLDER

# Extrai as coordenadas geográficas de todas as fotos da pasta em arquivo único
# com nome criado a partir do timestamp. Exemplo: 20250217_185412_fotos.tsv
#exiftool -filename -gpslatitude -gpslongitude -T $PROCESSED_FILES_FOLDER_FINAL > "00_$(date +'%Y%m%d_%H%M%S')_fotos_todas.tsv"
echo "Processando pasta: $PROCESSED_FILES_FOLDER_FINAL"; 
exiftool -filename -gpslatitude -gpslongitude -T $PROCESSED_FILES_FOLDER_FINAL > "00_fotos_todas.tsv"

for i in `ls $PROCESSED_FILES_FOLDER_THEME`; do 
    echo "Processando pasta: $i"; 
    exiftool -filename -gpslatitude -gpslongitude -T $PROCESSED_FILES_FOLDER_THEME/$i > "$i.tsv"
    done


echo "Feito."; 
