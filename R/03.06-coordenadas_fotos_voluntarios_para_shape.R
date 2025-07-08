# Antes de rodar esse script, rodar no terminal, dentro da pasta de fotos do
# Mapillary: exiftool -filename -gpslatitude -gpslongitude -T -r . > "../fotos_voluntarios.tsv"

library('tidyverse')
library('tidytable')
library('tidylog')
library('sf')
library('mapview')
library('measurements')


# Estrutura de pastas
pasta_fotos_campo <- '/mnt/fern/Dados/Campo_Camera360'
pasta_fotos_volunt_reduz <- sprintf('%s/06_fotos_voluntarios_reduzidas', pasta_fotos_campo)
pasta_publicacao  <- sprintf('%s/07_publicacao', pasta_fotos_campo)
pasta_fotos_tsv   <- sprintf('%s/tsv_fotos', pasta_publicacao)


# ------------------------------------------------------------------------------
# Abrir arquivos .tsv como dataframe único
# ------------------------------------------------------------------------------

# Ler arquivos de coordenadas das fotos
tsv_files <- data.frame(arqs = list.files(pasta_fotos_tsv,
                                          pattern = '.*\\voluntarios.tsv$',
                                          full.names = TRUE))

fotos <- map_df(tsv_files$arqs,
                ~ read_delim(.x, delim = '\t', col_types = 'ccc', col_names = FALSE)
                # mutate(origem = basename(.x), .before = 1),
                # .id = "file_id",
)


# Remover fotos sem coordenadas
# fotos %>% filter(X2 == '-' | is.na(X2) | str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))
fotos <- fotos %>% filter(X2 != '-' & !is.na(X2) & !str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))


# img_extensions <- c('HEIC', 'jpg', 'JPG', 'jpeg', 'JPEG')
# filtered_files <- fotos[sapply(fotos, function(file) tolower(tools::file_ext(file)) %in% tolower(img_extensions))]


# ------------------------------------------------------------------------------
# Extrair e converter coordenadas geográficas das fotos cropped do Mapillary
# ------------------------------------------------------------------------------

# Testar separação de latlon, caso tenha dado erro
# fotos %>% select(X3) %>% separate(X3, into = c('a', 'b', 'c', 'd', 'e', 'f'))
# fotos %>% select(X2) %>% separate(X2, into = c('a', 'b', 'c', 'd', 'e', 'f'))
# fotos %>% slice(240:248)

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

head(fotos)
tail(fotos)


# Criar endereço de referência das fotos, para visualizar no QGIS
fotos <- fotos %>% mutate(imagepath = str_c(pasta_fotos_volunt_reduz, X1, sep = '/'),
                          .before = 'lat')
# fotos %>% st_drop_geometry() %>% select(imagepath)

# URL para fotos no servidor: coluna foto_url, <img src='../fotos/2022-05-10_13-23-52.jpg'>
# https://falzoni.com.br/auditoria_cidada/fotos_voluntarios/20250215_092203.jpg
fotos <- fotos %>% mutate(foto_url = str_c("<img src='../fotos_voluntarios/", X1, "'>", sep = ''), .after = X1)
# Para visualização local
# fotos <- fotos %>% mutate(foto_url = str_c("<img src='", pasta_fotos_volunt_reduz, "/", X1, "'>", sep = ''), .after = X1)


# Link Mapillary para a área da foto:
# <a href="NTA_ENTE.pdf" target="_blank">NTA_ENTE.pdf</a>
# https://www.mapillary.com/app/user?lat=-23.50242890063116&lng=-46.61111296893637&z=19.9&menu=false&panos=true&all_coverage=false&dateFrom=2025-04-09&dateTo=2025-06-30&username%5B%5D=gabinete_falzoni&pKey=1277960299983573
# fotos <-
#   fotos %>%
#   mutate(mapillary_url = str_c(
#     '<h3><a href="https://www.mapillary.com/app/user?lat=', lat,
#     '&lng=', lon,
#     # '&z=18&menu=false&panos=true&all_coverage=false&dateFrom=2025-04-09&dateTo=2025-06-30&username%5B%5D=gabinete_falzoni&mapStyle=Esri+navigation" target="_blank">',
#     '&z=18&menu=false&panos=true&all_coverage=false&dateFrom=2025-04-09&dateTo=2025-06-30&username%5B%5D=gabinete_falzoni" target="_blank">',
#     'Clique aqui para ver fotos 360° (Mapillary)',
#     '</a></h3>',
#     sep = ''),
#     .after = X1)


# Transformar em shapefile
fotos <- fotos %>% st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = TRUE)
# mapview(fotos, cex = 1, legend = FALSE)


# Registrar ordem das fotos
fotos <- fotos %>% arrange(X1) %>% rename(foto = X1)

# Exportar shapefile no formato 20250218_auditoria.gpkg
out_file <- sprintf('%s/auditoria_cidada_2025_C_fotos_volutarios_reduzidas.gpkg', pasta_publicacao)
st_write(fotos, out_file, driver = 'GPKG', append = FALSE, delete_layer = TRUE)
