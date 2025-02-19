# Estrutura de pastas
CURRENT_FOLDER="`pwd`";
#TMP_FILES_FOLDER="`pwd`/fotos_originais_tmp";
TMP_FILES_FOLDER="../dados/fotos_originais_tmp";
PROCESSED_FILES_FOLDER="../dados/fotos_reduzidas_tmp";
BKP_ORIGINAL_FILES_FOLDER="../dados/fotos_originais_todas";


# Reduzir todas as imagens
# https://stackoverflow.com/questions/43253889/imagemagick-convert-how-to-tell-if-images-need-to-be-rotated
cd $TMP_FILES_FOLDER;
if [ ! -d $PROCESSED_FILES_FOLDER ]; then mkdir $PROCESSED_FILES_FOLDER; fi;

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

# Limpar metadados das imagens pequenas
#cd $PROCESSED_FILES_FOLDER
#mogrify -strip *.jpg

# Mover imagens grandes para pasta
cd $CURRENT_FOLDER
if [ ! -d $BKP_ORIGINAL_FILES_FOLDER ]; then mkdir $BKP_ORIGINAL_FILES_FOLDER; fi;
mv $TMP_FILES_FOLDER/*.jpg $BKP_ORIGINAL_FILES_FOLDER

# Remover pastas vazias (no caso, TMP_FILES_FOLDER)
find . -maxdepth 1 -type d -empty -delete
