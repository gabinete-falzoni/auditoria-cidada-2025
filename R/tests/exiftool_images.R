library('tidyverse')
library('tidylog')
library('sf')
library('mapview')
library('measurements')


pasta_base <- '/home/flavio/Downloads/FOTOS_TESTE/todas/'


# Extract GPS coordinates for all pictures in one file
# https://exiftool.org/forum/index.php?topic=3075.0
# exiftool -filename -gpslatitude -gpslongitude -T DIR > out.txt
file_exiftool <- sprintf('%s/00_gps_fotos.txt', pasta_base)
exiftool_path <- sprintf("/usr/bin/exiftool")
arg_1 <- sprintf('-filename -gpslatitude -gpslongitude -T "%s"', pasta_base)
arg_2 <- sprintf(' > "%s"', file_exiftool)
system2(command = exiftool_path, args = c(arg_1, arg_2))


fotos <- read_delim(file_exiftool, delim = '\t', col_types = 'ccc', col_names = FALSE)

# Fotos sem coordenadas
fotos_sem_gps <- fotos %>% filter(X2 == '-') %>% filter(!str_ends(X1, '.txt'))

# img_extensions <- c('HEIC', 'jpg', 'JPG', 'jpeg', 'JPEG')
# filtered_files <- fotos[sapply(fotos, function(file) tolower(tools::file_ext(file)) %in% tolower(img_extensions))]


# Converter coordenadas de latlon das imagens
fotos <- 
  fotos %>%
  # Remover fotos sem coor
  filter(X2 != '-') %>%
  # sample_n(20) %>% 
  mutate(X2 = str_replace(X2, ' deg ', ' '),
         X2 = str_replace(X2, '\'', ''),
         X2 = ifelse(str_detect(X2, ' S'),
                       str_replace(X2, '^([0-9 \\.]{10}[0-9]?)\" S', '-\\1'),
                       X2),
         X2 = ifelse(str_detect(X2, ' N'),
                     str_replace(X2, '^([0-9 \\.]{10}[0-9]?)\" N', '\\1'),
                     X2),
         X3 = str_replace(X3, ' deg ', ' '),
         X3 = str_replace(X3, '\'', ''),
         X3 = ifelse(str_detect(X3, ' W'),
                     str_replace(X3, '^([0-9 \\.]{10}[0-9]?)\" W', '-\\1'),
                     X3),
         X3 = ifelse(str_detect(X3, ' E'),
                     str_replace(X3, '^([0-9 \\.]{10}[0-9]?)\" E', '\\1'),
                     X3),
         lat = conv_unit(X2, from = 'deg_min_sec', to = 'dec_deg'),
         lon = conv_unit(X3, from = 'deg_min_sec', to = 'dec_deg')) %>% 
  select(X1, lat, lon) %>% 
  mutate(lat = as.double(lat),
         lon = as.double(lon))


# Transformar em shapefile
fotos <- fotos %>% st_as_sf(coords = c('lon', 'lat'), crs = 4326)
# mapview(fotos, legend = FALSE)

# Criar endereço de referência das fotos, para visualizar no QGIS
fotos <- fotos %>% mutate(imagepath = str_c(pasta_base, X1, sep = ''), .after = 'X1')

# Exportar shapefile
out_file <- sprintf('%s/00_fotos.gpkg', pasta_base)
st_write(fotos, out_file, driver = 'GPKG', append = FALSE)

  