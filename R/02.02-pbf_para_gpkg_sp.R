# Simplifica o arquivo .pbf com o viário da cidade de São Paulo para que possa
# ser aberto no QGIS para a conferência das vias com infraestrutura cicloviária
# e áreas de parques. São descartadas algumas colunas e tipos de 'highway'

library('tidyverse')
library('tidylog')
library('sf')
library('mapview')


# Estrutura de pastas
pasta_dados     <- '../dados'
pasta_dados_osm <- sprintf('%s/dados_originais/osm', pasta_dados)
pasta_dados_out <- sprintf('%s/dados_trabalhados', pasta_dados)


# Arquivo de viário para o município pode ser muito grande e não ler
# inteiro com o read_sf() abaixo. Em especial, isso vai acontecer com
# São Paulo - todos os arquivos de malha viária das cidades têm menos
# de 25 MB, enquanto o de SP tem quase 120 MB. Na dúvida, vamos ler
# todos esses arquivos como .gpkg para garantir que o viário seja lido
# em sua totalidade
# viario_muni <- read_sf(map_file, layer = 'lines') # não usar

# Ler arquivos de viário como .gpkg. Sobre este tema, ver:
# https://github.com/ropensci/osmextract/issues/12
read_from_gpkg <- function(path) {
  gpkg_file <- paste0(tempfile(), ".gpkg")
  gdal_utils(
    util = "vectortranslate",
    source = path,
    destination = gpkg_file,
    options = c("-f", "GPKG", "lines")
  )
  res <- st_read(gpkg_file, quiet = TRUE)
  names(res)[which(names(res) == "geom")] <- "geometry"
  st_geometry(res) <- "geometry"
  res
}

# Abrir arquivo .pbf do OSM para a cidade de São Paulo
# map_file <- sprintf("%s/20220216_sao_paulo.osm.pbf", pasta_valhalla)
osm_sp_file <- sprintf('%s/sao_paulo-latest.osm.pbf', pasta_dados_osm)
viario_muni <- read_from_gpkg(osm_sp_file)


# ------------------------------------------------------------------------------
# Simplificar mapa OSM para SP
# ------------------------------------------------------------------------------

# Retirar tudo o que não é viário de veículos terrestres
viario_muni <- viario_muni %>% filter(is.na(waterway) &
                                        is.na(aerialway) &
                                        is.na(barrier) &
                                        is.na(man_made))


# Simplificar a base e descartar colunas desnecessárias
viario_muni <- viario_muni %>% select(-c(waterway, aerialway, barrier, man_made, z_order))

# Retirar esses tipos de estrutura - todas foram olhadas no mapa para checagem
no_use <- c("raceway", "proposed", "construction", "elevator", "bus_stop",
            "platform", "emergency_bay", "crossing", "services")
viario_muni <- viario_muni %>% filter(!highway %in% no_use)
# Retirar também viários em que highway é nulo
viario_muni <- viario_muni %>% filter(!is.na(highway))

# Ordenar por osm_id para exportar
viario_muni <- viario_muni %>% arrange(osm_id)


# ------------------------------------------------------------------------------
# Inserir marcações para infra cicloviária
# ------------------------------------------------------------------------------

# Ciclovias: highway == 'cycleway'
viario_muni_out <- viario_muni
viario_muni_out <- viario_muni_out %>% mutate(infra_ciclo = case_when(highway == 'cycleway' ~ TRUE,
                                                                      TRUE ~ NA))

# Tentar marcar vias que possuem infraestrutura cicloviária - essa informação
# pode aparecer na coluna 'other_tags' ou diretamente na coluna de highway
viario_muni_out <-
  viario_muni_out %>%
  mutate(infra_ciclo = case_when(str_detect(other_tags, '"cycleway"=>"lane"') ~ TRUE,
                                 str_detect(other_tags, '"cycleway:left"=>"lane"') ~ TRUE,
                                 str_detect(other_tags, '"cycleway:right"=>"lane"') ~ TRUE,
                                 str_detect(other_tags, '"cycleway:both"=>"lane"') ~ TRUE,
                                 str_detect(other_tags, '"cycleway:left"=>"shared_lane"') ~ TRUE,
                                 str_detect(other_tags, '"cycleway:right"=>"shared_lane"') ~ TRUE,
                                 str_detect(other_tags, '"cycleway"=>"shared_lane"') ~ TRUE,
                                 # Estruturas de ciclovias ou em calçadas
                                 highway == 'cycleway'~ TRUE,
                                 highway == 'footway' & str_detect(other_tags, '"bicycle"=>"designated"') ~ TRUE,
                                 highway == 'pedestrian' & str_detect(other_tags, '"bicycle"=>"designated"') ~ TRUE,
                                 # Alguém marcou ciclofaixas nos acostamentos de rodovias...
                                 str_detect(other_tags, '"cycleway:left"=>"shoulder"') ~ FALSE,
                                 str_detect(other_tags, '"cycleway:right"=>"shoulder"') ~ FALSE,
                                 TRUE ~ NA)) %>%
  mutate(infra_ciclo_tp = case_when(str_detect(other_tags, '"cycleway"=>"lane"') ~ 'ciclofaixa',
                                    str_detect(other_tags, '"cycleway:left"=>"lane"') ~ 'ciclofaixa',
                                    str_detect(other_tags, '"cycleway:right"=>"lane"') ~ 'ciclofaixa',
                                    str_detect(other_tags, '"cycleway:both"=>"lane"') ~ 'ciclofaixa',
                                    str_detect(other_tags, '"cycleway:left"=>"shared_lane"') ~ 'ciclorrota',
                                    str_detect(other_tags, '"cycleway:right"=>"shared_lane"') ~ 'ciclorrota',
                                    str_detect(other_tags, '"cycleway"=>"shared_lane"') ~ 'ciclorrota',
                                    highway == 'cycleway' & !str_detect(other_tags, '"foot"=>"designated"') ~ 'ciclovia',
                                    highway == 'cycleway' & str_detect(other_tags, '"cycleway"=>"crossing"') ~ 'ciclofaixa',
                                    highway == 'cycleway' & str_detect(other_tags, '"foot"=>"designated"') & !str_detect(other_tags, '"segregated"=>"no"') ~ 'calçadada partilhada',
                                    highway == 'cycleway' & str_detect(other_tags, '"foot"=>"designated"') & str_detect(other_tags, '"segregated"=>"no"') ~ 'calçadada compartilhada',
                                    highway == 'footway' & str_detect(other_tags, '"bicycle"=>"designated"') ~ 'calçadada partilhada',
                                    highway == 'pedestrian' & str_detect(other_tags, '"bicycle"=>"designated"') ~ 'calçadada compartilhada',
                                    TRUE ~ NA))


# viario_muni_out %>% st_drop_geometry() %>% select(highway) %>% distinct()
# viario_muni_out %>% filter(str_detect(other_tags, '"cycleway:right"=>"shoulder"'))


# Exportar a base resultante
st_write(viario_muni_out, sprintf('%s/sao_paulo_osm_filtrado.gpkg', pasta_dados_out), driver = 'GPKG', append = FALSE, delete_layer = TRUE)

