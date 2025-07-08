#!/bin/sh

# Rodar esse script de dentro da pasta /gitlab/auditoria-cidada-2025/bash/
# Copiar fotos que serão reduzidas para a pasta de trabalho antes de rodar.

# Pasta de trabalho: /gitlab/auditoria-cidada-2025/dados/tmp
CURRENT_FOLDER="`pwd`";
TMP_FILES_FOLDER="../dados/tmp";
cd $TMP_FILES_FOLDER;

# Pasta temporária para fotos reduzidas
PROCESSED_FILES_FOLDER="fotos_reduzidas_voluntarios";
mkdir -p $PROCESSED_FILES_FOLDER

# Reduzir todas as imagens
# https://stackoverflow.com/questions/43253889/imagemagick-convert-how-to-tell-if-images-need-to-be-rotated
echo "Redimensionando imagens..."; 
for i in `ls *.jpg`; do
    NAME=`echo $i | cut -d "." -f 1`

    SIZE=`identify $i | cut -d " " -f 3`;
    HORIZ=`echo $SIZE | cut -d "x" -f 1`;
    VERT=`echo $SIZE | cut -d "x" -f 2`;
    
    if [ $HORIZ = $VERT ]; then
        convert -auto-orient $i -geometry 300x300! -depth 8 -density 100x100 -quality 70 jpg:$PROCESSED_FILES_FOLDER/$NAME.jpg
    # Usar -geometry 520x para redimensionar para 520px de largura e manter proporção
    elif [ $HORIZ -gt $VERT ]; then
        convert -auto-orient $i -geometry 300x -depth 8 -density 100x100 -quality 70 jpg:$PROCESSED_FILES_FOLDER/$NAME.jpg
    # Usar -geometry x500 para redimensionar para 500px de altura e manter proporção
    else
        convert -auto-orient $i -geometry x300 -depth 8 -density 100x100 -quality 70 jpg:$PROCESSED_FILES_FOLDER/$NAME.jpg
    fi

    done

echo "\nFeito!\n"
