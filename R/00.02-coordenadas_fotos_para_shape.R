library('tidyverse')
library('tidylog')
library('sf')
library('mapview')
library('measurements')


# Estrutura de pastas
pasta_dados <- '../dados'
pasta_fotos <- sprintf('%s/fotos', pasta_dados)
pasta_reduz <- sprintf('%s/fotos_reduzidas', pasta_fotos)
pasta_gpkgs <- sprintf('%s/shapes_bkp', pasta_dados)
dir.create(pasta_gpkgs, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------------------------
# Abrir arquivos .tsv como dataframe único
# ------------------------------------------------------------------------------

# Ler arquivos de coordenadas das fotos
tsv_files <- data.frame(arqs = list.files(pasta_fotos,
                                          pattern = '.*\\.tsv$',
                                          full.names = TRUE))

fotos <- map_df(tsv_files$arqs,
                ~ read_delim(.x, delim = '\t', col_types = 'ccc', col_names = FALSE) %>%
                  mutate(origem = basename(.x), .before = 1),
                # .id = "file_id",
                )


# Remover fotos sem coordenadas
fotos %>% filter(X2 == '-' | is.na(X2) | str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))
fotos <- fotos %>% filter(X2 != '-' & !is.na(X2) & !str_starts(X2, '0')) #%>% filter(!str_ends(X1, '.txt'))

fotos %>% select(origem) %>% distinct()

# Separar fotos por tema
fotos_todas   <- fotos %>% filter(str_starts(origem, '00'))
fotos_medicao <- fotos %>% filter(str_starts(origem, '01'))
fotos_pintura <- fotos %>% filter(str_starts(origem, '02'))
fotos_pavimto <- fotos %>% filter(str_starts(origem, '03'))
fotos_esquina <- fotos %>% filter(str_starts(origem, '04'))
fotos_sp_156  <- fotos %>% filter(str_starts(origem, '05'))
fotos_outros  <- fotos %>% filter(str_starts(origem, '06'))
fotos_invasao <- fotos %>% filter(str_starts(origem, '07'))
fotos_apagmto <- fotos %>% filter(str_starts(origem, '08'))
fotos_tachao  <- fotos %>% filter(str_starts(origem, '09'))

# Insrir marcações temáticas no dataframe único
fotos <-
  fotos_todas %>%
  mutate(medicao = ifelse(X1 %in% fotos_medicao$X1, TRUE, FALSE),
         pintura = ifelse(X1 %in% fotos_pintura$X1, TRUE, FALSE),
         pavimento = ifelse(X1 %in% fotos_pavimto$X1, TRUE, FALSE),
         esquina = ifelse(X1 %in% fotos_esquina$X1, TRUE, FALSE),
         sp_156  = ifelse(X1 %in% fotos_sp_156$X1, TRUE, FALSE),
         outros  = ifelse(X1 %in% fotos_outros$X1, TRUE, FALSE),
         invasao = ifelse(X1 %in% fotos_invasao$X1, TRUE, FALSE),
         apagamento = ifelse(X1 %in% fotos_apagmto$X1, TRUE, FALSE),
         tachao  = ifelse(X1 %in% fotos_tachao$X1, TRUE, FALSE)) %>%
  select(-origem)

# Limpar ambiente
rm(tsv_files, fotos_todas, fotos_medicao, fotos_pintura, fotos_pavimto,
   fotos_esquina, fotos_sp_156, fotos_outros, fotos_invasao, fotos_apagmto,
   fotos_tachao)

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
pasta_reduz_full_path <- sprintf('%s/%s', getwd(), pasta_reduz) %>% str_replace('R\\/\\.\\.\\/', '')
# path_claros <- 'C:\\Users\\User\\Desktop\\AC2025\\Claros\\fotos\\fotos_reduzidas\\'
# path_claros <- 'D:\\Fotos_auditoria\\Claros_total\\fotos_originais\\fotos_medicoes_originais_renomeadas\\Renomeadas\\'
path_claros <- 'D:\\Fotos_auditoria\\Claros_total\\fotos\\fotos_reduzidas\\'
fotos <- fotos %>% mutate(imagepath  = str_c(pasta_reduz_full_path, X1, sep = '/'),
                          imagepath2 = str_c(path_claros, X1, sep = ''),
                          .before = 'lat')
# fotos %>% st_drop_geometry() %>% select(imagepath)

# Registrar ordem das fotos
fotos <- fotos %>% arrange(X1)

# Exportar shapefile no formato 20250218_auditoria.gpkg
out_file <- sprintf('%s/auditoria_cidada_2025.gpkg', pasta_dados)
st_write(fotos, out_file, driver = 'GPKG', append = FALSE, delete_layer = TRUE)

# # TODO: Melhorar este sistema de backup: temos que reconhecer novas colunas no
# # shape e as linhas já existentes, inserindo somente as linhas novas
# if (file.exists(out_file)) {
#   bkp_file <- sprintf('%s/%s_BKP_auditoria_cidada_2025.gpkg', pasta_gpkgs, format(Sys.Date(), "%Y%m%d"))
#
#   shape_atual <- read_sf(out_file)
#   fotos <- fotos %>% filter(!X1 %in% shape_atual$X1) %>% rename(geom = geometry)
#
#   fotos <-
#     shape_atual %>%
#     # Descartar temporariamente esta coluna, vai ser refeita em seguida
#     select(-ordem_pontos) %>%
#     # mutate(apagamento = FALSE, .before = 'imagepath') %>%
#     # rename(sp_156 = poda) %>%
#     rbind(fotos) %>%
#     mutate(ordem_pontos = row_number(), .after = 'X1') %>%
#     arrange(X1)
#
#   file.copy(out_file, bkp_file, overwrite = TRUE)
#
#   st_write(fotos, out_file, driver = 'GPKG', append = FALSE)
#
# } else {
#   st_write(fotos, out_file, driver = 'GPKG', append = FALSE)
# }

