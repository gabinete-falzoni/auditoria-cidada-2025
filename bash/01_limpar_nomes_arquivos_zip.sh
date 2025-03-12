#!/bin/sh

# Rodar esse script de dentro da pasta /gitlab/auditoria-cidada-2025/bash/

# Colocar arquivos .zip na pasta ../dados/tmp
TMP_FILES_FOLDER="../dados/tmp";
cd $TMP_FILES_FOLDER;

# Trocar espaços e hífens por underscore
rename 'y/ /_/' *.zip *.rar
rename 'y/-/_/' *.zip *.rar
# Retirar acentos
rename 'y/à-úÀ-Ú/a-u/' *.zip *.rar
# Baixar caixas
rename 'y/A-Z/a-z/' *.zip *.rar
# Remover parênteses
rename 'y/\\(/_/' *.zip *.rar
rename 's/\).zip$/\.zip/' *.zip *.rar
rename 's/\)/_/' *.zip *.rar
# Trocar espaços por underscore
rename 's/_+/_/g' *.zip *.rar

echo "\nFINALIZADO - CHECAR NOMES DOS ARQUIVOS ANTES DE SEGUIR\n"

