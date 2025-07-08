# Nesta continuação do script anterior, vão ser inseridas as coordenadas de GPS
# nas fotos e gerar um shape para conferência. As fotos já vão estar prontas
# para subir no Mapillary
# Na pasta de dados, devem estar os arquivos:
# 00_qgis_visualizacao_gpx_tracks.qgz (arquivo de visualização, já na pasta)
# 2025-04-09_14-04-01.gpx
# gpx_para_revisao.gpkg
# gpx_revisto.gpx
# VID_20250409_140416_00_003.insv
# VID_20250409_140416_10_003.insv

library('tidyverse')
library('tidylog')
library('gpx')
library('sf')
library('measurements')
# library('mapview')


# Estrutura de pastas
pasta_base  <- '/media/livre/Expansion/Dados_Comp_Gabinete/Campo_Camera360'
pasta_dados <- sprintf('%s/00_pasta_de_trabalho', pasta_base)
pasta_fotos_ret <- sprintf('%s/03_image_sequences', pasta_base)

# Pasta de destino
arqs_videos <- list.files(pasta_dados, pattern = '\\.insv$', full.names = TRUE)
basename_jpgs <- basename(arqs_videos[1]) %>% str_sub(5, 19)
pasta_fotos   <- sprintf('%s/04_mapillary_sequences/%s', pasta_base, basename_jpgs)


# ------------------------------------------------------------------------------
# Inserir timestamps nas fotos - Parte 1: Inserir e replicar primeiro timestamp
# ------------------------------------------------------------------------------

# Precisamos do valor do primeiro timestamp do GPX revisado
gpx <- sprintf('%s/gpx_revisto.gpx', pasta_dados)
min_time <- read_gpx(gpx)
min_time <- format(min(min_time$waypoints$Time), '%Y-%m-%dT%H:%M:%SZ')


# Inserir timestamp inicial nas fotos - -overwrite_original é opcional
# exiftool -XMP:DateTimeOriginal='2025-01-28T10:53:43Z' .
message('\nInserindo timestamp inicial nas fotos.\n')
exiftool_path <- sprintf("/usr/bin/exiftool")
arg_o1 <- sprintf('-XMP:DateTimeOriginal="%s" -overwrite_original %s', min_time, pasta_fotos)
system2(command = exiftool_path, args = c(arg_o1))

# Limpar ambiente
rm(arg_o1)


# ------------------------------------------------------------------------------
# Timestamps nas fotos - Parte 2: Atualizar valores a intervalos de x segundos
# ------------------------------------------------------------------------------

# Intervalo em segundos
int_seg <- 4

# Atualizar timestamp a cada x segundos - -overwrite_original é opcional
# exiftool '-XMP:DateTimeOriginal+<0:0:${filesequence;$_*=4}' $(ls -1v *.jpg)
message('\nInserindo timestamp inicial nas fotos.\n')
cmd <- sprintf(
  "%s '-XMP:DateTimeOriginal+<0:0:${filesequence;$_*=%s}' -overwrite_original $(ls -1v %s/*.jpg)",
  exiftool_path, int_seg, pasta_fotos
)
# Vamos usar o system() em vez do system2() devido a esse monte de caracteres especiais
system(cmd)

# Limpar ambiente
rm(cmd)


# ------------------------------------------------------------------------------
# Inserir coordenadas GPS vindas do arquivo .GPX revisto
# ------------------------------------------------------------------------------

# Inserir coordenadas GPS - -overwrite_original é opcional
# exiftool -geotag gpx_revisto.gpx '-Geotime<XMP:DateTimeOriginal' .
message('\nInserindo coordenadas GPS nas fotos.\n')
cmd <- sprintf(
  "%s -geotag %s '-Geotime<XMP:DateTimeOriginal' -overwrite_original %s",
  exiftool_path, gpx, pasta_fotos
)
# Vamos usar o system() em vez do system2() devido a esse monte de caracteres especiais
system(cmd)

# Limpar ambiente
rm(cmd)


# ------------------------------------------------------------------------------
# Gerar arquivo shapefile para checagem
# ------------------------------------------------------------------------------

# Arquivo .tsv temporário de saída
out_tsv <- sprintf('%s/00_fotos_todas.tsv', pasta_dados)

# Extrair coordenadas GPS em arquivo .tsv
# exiftool -filename -gpslatitude -gpslongitude -T . > "00_fotos_todas.tsv"
message('\nExtraindo coordenadas das fotos para checagem.\n')
cmd <- sprintf(
  "%s -filename -gpslatitude -gpslongitude -T %s > %s",
  exiftool_path, pasta_fotos, out_tsv
)
# Vamos usar o system() em vez do system2() devido a esse monte de caracteres especiais
system(cmd)

# Limpar ambiente
rm(cmd)


# Ler arquivo .tsv de coordenadas das fotos
fotos <- read_delim(out_tsv, delim = '\t', col_types = 'ccc', col_names = FALSE)


# Remover fotos sem coordenadas
# fotos %>% filter(X2 == '-' | is.na(X2) | str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))
fotos <- fotos %>% filter(X2 != '-' & !is.na(X2) & !str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))

# Registrar ordem das fotos
fotos <- fotos %>% arrange(X1)


# ------------------------------------------------------------------------------
# Converter coordenadas geográficas
# ------------------------------------------------------------------------------

# Coordenadas de lat lon estão como 23 54 33.4320 S, 46 42 34.6140 O. Para
# serem compreendidas pelo conv_unit(), o que for Sul e Oeste precisa ser
# transformado em negativo. Além disso, as letras precisam ser retiradas
fotos <-
  fotos %>%
  # Garantir que as colunas de latlon tenham sempre o mesmo length
  mutate(X2 = str_replace(X2, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" S', '-\\1 \\2 \\3'),
         X2 = str_replace(X2, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" N', '\\1 \\2 \\3'),
         X3 = str_replace(X3, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" W', '-\\1 \\2 \\3'),
         X3 = str_replace(X3, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" E', '\\1 \\2 \\3'),
         # Fazer a conversão
         lat = conv_unit(X2, from = 'deg_min_sec', to = 'dec_deg'),
         lon = conv_unit(X3, from = 'deg_min_sec', to = 'dec_deg')) %>%
  select(-X2, -X3) %>%
  mutate(lat = as.double(lat),
         lon = as.double(lon))



# Transformar em shapefile
fotos <- fotos %>% st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE)
# mapview(fotos, cex = 1, legend = FALSE)

# Criar endereço de referência das fotos, para visualizar no QGIS
fotos <- fotos %>% mutate(X1 = str_replace(X1, '\\.jpg', '_ret.jpg'),
                          imagepath = str_c(pasta_fotos_ret, basename(X1), sep = '/'),
                          .before = 'lat')
# fotos %>% st_drop_geometry() %>% select(imagepath)

# Exportar shapefile no formato 20250218_auditoria.gpkg
out_file <- sprintf('%s/00_shape_fotos.gpkg', pasta_dados)
st_write(fotos, out_file, driver = 'GPKG', append = FALSE, delete_layer = TRUE)


# ------------------------------------------------------------------------------
# Limpar ambiente
# ------------------------------------------------------------------------------

# rm_file1 <- sprintf('%s/gpx_para_revisao.gpkg', pasta_dados)
# rm_file2 <- sprintf('%s/gpx_revisto.qmd', pasta_dados)
# file.remove(out_tsv, out_file, rm_file1, rm_file2)
# gpx <- list.files(pasta_dados, pattern = '.*\\.gpx$', full.names = TRUE)
# file.remove(arqs_videos, gpx)
# rm(list = ls())
# gc(T)