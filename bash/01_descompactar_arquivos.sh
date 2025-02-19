#!/bin/sh

# Colocar arquivos .zip na pasta ../dados
TMP_FILES_FOLDER="../dados";
cd $TMP_FILES_FOLDER;

# Trocar espaços por underscore
rename 'y/ /_/' *.zip
rename 'y/ /_/' *.rar
# Retirar acentos
rename 'y/à-úÀ-Ú/a-u/' *.zip
rename 'y/à-úÀ-Ú/a-u/' *.rar
# Baixar caixas
rename 'y/A-Z/a-z/' *.zip
rename 'y/A-Z/a-z/' *.rar

# Deszipar os arquivos
# for i in `ls *.zip`; do 7z x $i; done
# Deszipar os arquivos sem criar pastas novas
for i in `ls *.zip`; do 7z e $i; done

# Deszipar pastas 'photos' que vieram de iPhone
for i in `ls photo*.zip`; do 7z e $i; done

# Remover pastas vazias criadas no momento da descompactação
find . -maxdepth 1 -type d -empty -delete

# Renomear arquivos .gpx para o original
# rename 's/(.+)?_2022/2022/' *.gpx

# Deszipar os arquivos em .rar 
# for i in `ls *.rar`; do unar -D $i; done
# Entra na pasta resultante e copia os arquivos para a pasta 
# base - não funciona porque arquivo original tem espaços no nome
# for i in `ls *.rar`; do unar -D $i; cd `echo $i | cut -d "." -f 1`; mv *.jpg *.gpx ../; cd -; done

# Mover arquivos .zip e ;kmz
mkdir -p zips && mv *.zip zips
mkdir -p kmzs && mv *.kmz kmzs

# Padronizar arquivos .jpg
rename 's/.jpeg$/\.jpg/' *.jpeg
rename 's/.JPG$/\.jpg/' *.JPG
rename 's/.JPEG$/\.jpg/' *.JPEG

# Remover parênteses
rename 'y/\\(/_/' *.jpg
rename 's/\).jpg$/\.jpg/' *.jpg

# Trocar espaços por underscore
rename 'y/ /_/' *.jpg
rename 's/_+/_/' *.jpg

# Remover vídeos
rm *.mp4 *.docx

# Mover fotos para pasta de fotos originais
mkdir -p fotos_originais_tmp && mv *.jpg fotos_originais_tmp
