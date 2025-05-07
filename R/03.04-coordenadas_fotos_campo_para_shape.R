# Antes de rodar esse script, rodar o script bash 07_extrair_coordenadas_geograficas_medicoes_campo.sh

library('tidyverse')
library('tidytable')
library('tidylog')
library('sf')
library('mapview')
library('measurements')


# Estrutura de pastas
pasta_dados <- '../dados/dados_trabalhados'
pasta_fotos_campo_medicoes <- '../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/fotos_originais/fotos_medicoes_campo'


# ------------------------------------------------------------------------------
# Abrir arquivos .tsv como dataframe único
# ------------------------------------------------------------------------------

# Ler arquivos de coordenadas das fotos
tsv_files <- data.frame(arqs = list.files(pasta_fotos_campo_medicoes,
                                          pattern = '.*\\.tsv$',
                                          full.names = TRUE))

fotos <- map_df(tsv_files$arqs,
                ~ read_delim(.x, delim = '\t', col_types = 'ccc', col_names = FALSE)
                  # mutate(origem = basename(.x), .before = 1),
                # .id = "file_id",
)


# Remover fotos sem coordenadas
fotos %>% filter(X2 == '-' | is.na(X2) | str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))
fotos <- fotos %>% filter(X2 != '-' & !is.na(X2) & !str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))


# img_extensions <- c('HEIC', 'jpg', 'JPG', 'jpeg', 'JPEG')
# filtered_files <- fotos[sapply(fotos, function(file) tolower(tools::file_ext(file)) %in% tolower(img_extensions))]


# ------------------------------------------------------------------------------
# Converter coordenadas geográficas
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



# Transformar em shapefile
fotos <- fotos %>% st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE)
# mapview(fotos, cex = 1, legend = FALSE)

# Criar endereço de referência das fotos, para visualizar no QGIS
pasta_imagepath_1 <- sprintf('%s/%s', getwd(), pasta_fotos_campo_medicoes) %>% str_replace('R\\/\\.\\.\\/', '')
pasta_imagepath_2 <- 'D:\\Fotos_auditoria\\Claros_total\\fotos_originais\\fotos_medicoes_campo\\'
fotos <- fotos %>% mutate(imagepath  = str_c(pasta_imagepath_1, X1, sep = '/'),
                          imagepath2 = str_c(pasta_imagepath_2, X1, sep = ''),
                          .before = 'lat')
# fotos %>% st_drop_geometry() %>% select(imagepath)

# Registrar ordem das fotos
fotos <- fotos %>% arrange(X1)

# Exportar shapefile no formato 20250218_auditoria.gpkg
out_file <- sprintf('%s/auditoria_cidada_2025_medicoes_campo.gpkg', pasta_dados)
st_write(fotos, out_file, driver = 'GPKG', append = FALSE, delete_layer = TRUE)
