library('tidyverse')
library('tidylog')
library('sf')
library('mapview')


# Estrutura de pastas
pasta_dados     <- '../dados'
pasta_dados_osm <- sprintf('%s/osm', pasta_dados)

# ----------------------------------------
# 1. Baixar arquivo PBF e criar o .poly
# ----------------------------------------

# Baixar o arquivo PBF da região Sudeste do Brasil manualmente do site
# http://download.geofabrik.de/south-america/brazil/sudeste.html e
# salvar na pasta pasta 'valhalla_pbf'. Renomear para que fique clara a data
# da última modificação do arquivo, no formato '20220216_sudeste-latest.osm.pbf'

# Também será preciso o polyline da cidade de SP. Abaixo seguem links para
# gerá-lo. Uma vez criado, deve ser colocado na mesma pasta 'valhalla_pbf'
# com o nome de 'SAO_PAULO.poly'.

# Links úteis e passo a passo:
# Sobre o formato .poly para ser usado:
# https://wiki.openstreetmap.org/wiki/Osmconvert,
# https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format

#  Para usar o osmosis, é preciso criar um polígono no formato .poly de são
#  paulo. O modo mais fácil é:
#  1..Abrir o mapa dos limites administrativos de SP do Geosampa no QGIS;
#  2. Instalar um plugin chamado "Export OSM Poly, que aparece como "osmpoly_export";
#  3. No botão do plugin que aparece no menu, exportar a camada no formato .poly;
#  4. Por conveniência, renomear o polígono "SAO PAULO.poly" para "SAO_PAULO.poly".


# Atualizar os nomes dos arquivos aqui antes de continuar:
poly_file    <- sprintf('%s/sp.poly', pasta_dados_osm)
# Pegar última versão dos arquivos, com base no nome do arquivo
pbf_file     <- list.files(pasta_dados_osm, pattern = "sudeste-latest.osm.pbf", full.names = TRUE)
out_pbf_file <- sprintf('%s/sao_paulo-latest.osm.pbf', pasta_dados_osm)


# ----------------------------------------
# 2. Rodar o osmosis
# ----------------------------------------

# Uma vez baixado o arquivo PBF, é preciso isolar a cidade de SP dele. Para isso,
# é preciso usar um programa chamado Osmosis (ver passo a passo a seguir):
# Sobre o Osmosis: https://github.com/openstreetmap/osmosis (tem pacote para o Debian, instalar via apt)
# Sobre como usar o osmosis para recortar o polígono: https://github.com/eqasim-org/sao_paulo/blob/master/docs/howto.md
# Exemplos de uso do osmosis: https://wiki.openstreetmap.org/wiki/Osmosis/Examples


# Uma vez com o (a) arquivo do sudeste do Brasil no formato OSM e (b) o
# polígono de São Paulo no formato .poly, rodar o osmosis no terminal:

message('\nIniciando o osmosis - este passo deve demorar cerca de 2h15 minutos para rodar.\n')
osmosis_path <- sprintf("/usr/bin/osmosis")
arg_o1 <- sprintf('--read-pbf file="%s"', pbf_file)
arg_o2 <- sprintf('--bounding-polygon file="%s"', poly_file)
arg_o3 <- sprintf('--write-pbf file="%s"', out_pbf_file)
system2(command = osmosis_path, args = c(arg_o1, arg_o2, arg_o3))
