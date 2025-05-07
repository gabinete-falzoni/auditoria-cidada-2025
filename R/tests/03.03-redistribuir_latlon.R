library('tidyverse')
library('tidylog')
library('gpx')
library('sf')
library('mapview')
# library('measurements')

pasta_base  <- '/Volumes/Expansion/Dados_Comp_Gabinete/Campo_Camera360'
pasta_dados <- sprintf('%s/00_pasta_de_trabalho', pasta_base)

gpx <- list.files(pasta_dados, pattern = '.*\\.gpx$', full.names = TRUE)
gpx <- data.frame(read_gpx(gpx)$tracks) %>% select(Elevation = 1,
                                                   Time = 2,
                                                   Latitude = 3,
                                                   Longitude = 4,
                                                   speed = 5,
)

this <- gpx %>% select(Latitude, Longitude)

# 2. Convert to sf points and create a LINESTRING
line <- this %>%
  select(lon = Longitude, lat = Latitude) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%  # WGS84
  st_transform(31983) %>%  # Use a projected CRS for accurate distances (SIRGAS 2000 / UTM zone 23S for São Paulo)
  summarise(geometry = st_combine(geometry)) %>%
  st_cast("LINESTRING")

mapview(line)

# 3. Resample the line into evenly spaced points
n_points <- nrow(gpx)  # choose how many points you want
sampled_points <-
  st_line_sample(line, n = n_points, type = "regular") %>%
  st_cast("POINT") %>%
  st_sf() %>%
  st_transform(4326)  # back to lat/lon

mapview(sampled_points)
gpx %>%
  select(lon = Longitude, lat = Latitude) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%  # WGS84
  mapview()

# 4. Convert to data frame for further use
sampled_coords <-
  sampled_points %>%
  mutate(id = row_number()) %>%
  mutate(
    lon = st_coordinates(.)[,1],
    lat = st_coordinates(.)[,2]
  ) %>%
  select(id, lat, lon)
