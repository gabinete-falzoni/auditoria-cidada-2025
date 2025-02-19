library('tidyverse')
library('tidylog')
library('sf')
library('mapview')
library('measurements')


# Estrutura de pastas
pasta_dados <- '/home/flavio/Dados/gitlab/auditoria-cidada-2025/dados'
pasta_fotos <- sprintf('%s/00_fotos_reduzidas_tmp', pasta_dados)
pasta_gpkgs <- sprintf('%s/01_gpkgs_tmp', pasta_dados)


# Ler arquivos de coordenadas das fotos
tsv_files <- data.frame(arqs = list.files(pasta_dados,
                                          pattern = '.*\\.tsv$',
                                          full.names = TRUE))

fotos <-
  map_df(tsv_files$arqs,
         ~ read_delim(.x, delim = '\t', col_types = 'ccc', col_names = FALSE) %>%
           mutate(origem = basename(.x)), .id = "file_id")


# Fotos sem coordenadas
fotos_sem_gps <- fotos %>% filter(X2 == '-') %>% filter(!str_ends(X1, '.txt'))

# img_extensions <- c('HEIC', 'jpg', 'JPG', 'jpeg', 'JPEG')
# filtered_files <- fotos[sapply(fotos, function(file) tolower(tools::file_ext(file)) %in% tolower(img_extensions))]


# Coordenadas de lat lon estão como 23 54 33.4320 S, 46 42 34.6140 O. Para
# serem compreendidas pelo conv_unit(), o que for Sul e Oeste precisa ser
# transformado em negativo. Além disso, as letras precisam ser retiradas
fotos <-
  fotos %>%
  # Remover fotos sem coordenadas
  filter(X2 != '-') %>%
  # Garantir que as colunas de latlon tenham sempre o mesmo length
  mutate(X2 = str_replace(X2, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" S', '-\\1 \\2 \\3'),
         X2 = str_replace(X2, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" N', '\\1 \\2 \\3'),
         X3 = str_replace(X3, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" W', '-\\1 \\2 \\3'),
         X3 = str_replace(X3, '^(\\d{2}) deg (\\d{2})\' (.{4}.?)\" E', '\\1 \\2 \\3'),
         # Fazer a conversão
         lat = conv_unit(X2, from = 'deg_min_sec', to = 'dec_deg'),
         lon = conv_unit(X3, from = 'deg_min_sec', to = 'dec_deg')) %>%
  select(X1, origem, lat, lon) %>%
  mutate(lat = as.double(lat),
         lon = as.double(lon))

# Transformar em shapefile
fotos <- fotos %>% st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE)
# mapview(fotos, cex = 1, legend = FALSE)

# Criar endereço de referência das fotos, para visualizar no QGIS
fotos <- fotos %>% mutate(imagepath = str_c(pasta_fotos, X1, sep = '/'), .after = 'origem')
# fotos %>% st_drop_geometry() %>% select(imagepath)

# Registrar ordem das fotos
fotos <- fotos %>% arrange(X1) %>% mutate(ordem_pontos = row_number(), .after = 'X1')

# Exportar shapefile no formato 20250218_auditoria.gpkg
out_file <- sprintf('%s/%s_auditoria.gpkg', pasta_dados, format(Sys.Date(), "%Y%m%d"))
st_write(fotos, out_file, driver = 'GPKG', append = FALSE)

