#!/bin/sh

# Rodar esse script de dentro da pasta /gitlab/auditoria-cidada-2025/bash/

# Pasta de trabalho: /gitlab/auditoria-cidada-2025/dados/tmp
TMP_FILES_FOLDER="../dados/tmp";
cd $TMP_FILES_FOLDER;

# Padronizar arquivos .jpg
rename 's/.jpeg$/\.jpg/' *.jpeg
rename 's/.JPG$/\.jpg/' *.JPG
rename 's/.JPEG$/\.jpg/' *.JPEG

# Remover parênteses
rename 'y/\\(/_/' *.jpg
rename 's/\).jpg$/\.jpg/' *.jpg
# Trocar espaços por underscore
rename 'y/ /_/' *.jpg
rename 'y/\~/_/' *.jpg
rename 's/_+/_/' *.jpg


## Mover fotos para pasta de fotos originais
#mkdir -p fotos_originais_tmp && mv *.jpg fotos_originais_tmp

echo "\nFINALIZADO - CHECAR SE ESTÁ TUDO OK COM NOMES DE ARQUIVOS\n"

