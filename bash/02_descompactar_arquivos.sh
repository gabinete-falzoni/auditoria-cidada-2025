#!/bin/sh

# Rodar esse script de dentro da pasta /gitlab/auditoria-cidada-2025/bash/

# Pasta de trabalho: /gitlab/auditoria-cidada-2025/dados/tmp
TMP_FILES_FOLDER="../dados/tmp";
cd $TMP_FILES_FOLDER;

BKP_ORIGINAL_FILES_FOLDER="../../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/zips_originais";
mkdir -p $BKP_ORIGINAL_FILES_FOLDER;

# Descompactar os arquivos sem criar pastas novas; zips originais serão movidos
# para pasta de backup
for i in `ls *.zip`; do 7z e $i; mv $i $BKP_ORIGINAL_FILES_FOLDER; done

# Descompactar os arquivos em .rar 
for i in `ls *.rar`; do unar -D $i; mv $i $BKP_ORIGINAL_FILES_FOLDER; done

## Deszipar pastas 'photos' que vieram de iPhone
#for i in `ls photo*.zip`; do 7z e $i; done

# Remover pastas vazias criadas no momento da descompactação
find . -maxdepth 1 -type d -empty -delete

### Renomear arquivos .gpx para o original
### rename 's/(.+)?_2022/2022/' *.gpx

### Entra na pasta resultante e copia os arquivos para a pasta 
### base - não funciona porque arquivo original tem espaços no nome
### for i in `ls *.rar`; do unar -D $i; cd `echo $i | cut -d "." -f 1`; mv *.jpg *.gpx ../; cd -; done

# Converter fotos HEIC para JPG
echo "Convertendo fotos HEIC para JPG..."; 
for i in `ls *.HEIC`; do convert $i $i.jpg; done
## Jogar fotos originais HEIC em pasta própria
#mkdir -p fotos_HEIC && mv *.HEIC fotos_HEIC
rm *.HEIC

## Remover vídeos
rm *.mp4 

echo "\nFINALIZADO - CHECAR SE ARQUIVOS ZIPS FORAM PARA PASTA DE BKP"
echo "\n------------ CHECAR SE AINDA HÁ ARQUIVOS ZIP NA PASTA FOTOS\n"


