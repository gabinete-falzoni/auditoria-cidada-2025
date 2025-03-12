#!/bin/sh

# Rodar esse script de dentro da pasta /gitlab/auditoria-cidada-2025/bash/

# Pasta de trabalho: /gitlab/auditoria-cidada-2025/dados/tmp
CURRENT_FOLDER="`pwd`";
TMP_FILES_FOLDER="../dados/tmp";
cd $TMP_FILES_FOLDER;

# Pasta temporária para fotos reduzidas
PROCESSED_FILES_FOLDER="tmp_fotos_tematicas";
mkdir -p $PROCESSED_FILES_FOLDER

# Pastas para divisão temática
mkdir -p "$PROCESSED_FILES_FOLDER/01_medicao"
mkdir -p "$PROCESSED_FILES_FOLDER/02_pintura"
mkdir -p "$PROCESSED_FILES_FOLDER/03_pavimento"
mkdir -p "$PROCESSED_FILES_FOLDER/04_esquina"
mkdir -p "$PROCESSED_FILES_FOLDER/05_sp_156"
mkdir -p "$PROCESSED_FILES_FOLDER/06_outros"
mkdir -p "$PROCESSED_FILES_FOLDER/07_invasao"
mkdir -p "$PROCESSED_FILES_FOLDER/08_apagamento"

# Reduzir todas as imagens
# https://stackoverflow.com/questions/43253889/imagemagick-convert-how-to-tell-if-images-need-to-be-rotated
echo "Redimensionando imagens..."; 
for i in `ls *.jpg`; do
    NAME=`echo $i | cut -d "." -f 1`

    SIZE=`identify $i | cut -d " " -f 3`;
    HORIZ=`echo $SIZE | cut -d "x" -f 1`;
    VERT=`echo $SIZE | cut -d "x" -f 2`;
    
    if [ $HORIZ = $VERT ]; then
        convert -auto-orient $i -geometry 500x500! -depth 8 -density 100x100 -quality 70 jpg:$PROCESSED_FILES_FOLDER/$NAME.jpg
    # Usar -geometry 520x para redimensionar para 520px de largura e manter proporção
    elif [ $HORIZ -gt $VERT ]; then
        convert -auto-orient $i -geometry 500x -depth 8 -density 100x100 -quality 70 jpg:$PROCESSED_FILES_FOLDER/$NAME.jpg
    # Usar -geometry x500 para redimensionar para 500px de altura e manter proporção
    else
        convert -auto-orient $i -geometry x500 -depth 8 -density 100x100 -quality 70 jpg:$PROCESSED_FILES_FOLDER/$NAME.jpg
    fi    

    done


# Mover imagens grandes para pasta de BKP
echo "Copiando imagens originais para pasta de backup..."; 
BKP_ORIGINAL_IMAGES_FOLDER="../../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/fotos_originais/";
mkdir -p $BKP_ORIGINAL_IMAGES_FOLDER;
mv *.jpg $BKP_ORIGINAL_IMAGES_FOLDER;

# Copiar fotos reduzidas para a pasta onde ficarão
echo "Copiando imagens reduzidas para pasta com todas as demais fotos reduzidas..."; 
PROCESSED_FILES_FOLDER_FINAL="../fotos/fotos_reduzidas";
PROCESSED_FILES_FOLDER_THEME="../fotos/fotos_tematicas";
mkdir -p $PROCESSED_FILES_FOLDER_FINAL $PROCESSED_FILES_FOLDER_THEME;
cp $PROCESSED_FILES_FOLDER/*.jpg $PROCESSED_FILES_FOLDER_FINAL;

echo "\nSEPARAR FOTOS EM 'tmp_fotos_reduzidas' NAS PASTAS TEMÁTICAS\n"
