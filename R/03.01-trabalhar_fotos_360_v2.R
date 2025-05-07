# Inserir em uma mesma pasta o arquivo .gpx gravado pelo osmtracker e os dois
# arquivos de vídeo .insv com o timelapse das fotos gravadas pela câmra insta 360
# Exemplo:
# 00_qgis_visualizacao_gpx_tracks.qgz (arquivo de visualização, já na pasta)
# --- pasta "fila":
# --- 2025-04-09_14-04-01.gpx
# --- VID_20250409_140416_00_003.insv
# --- VID_20250409_140416_10_003.insv

library('tidyverse')
library('tidylog')
library('gpx')
library('sf')
library('mapview')
# library('measurements')


# Estrutura de pastas
pasta_base  <- '/media/livre/Expansion/Dados_Comp_Gabinete/Campo_Camera360'
# pasta_base  <- '/mnt/fern/Dados/Campo_Camera360'
pasta_dados <- sprintf('%s/00_pasta_de_trabalho', pasta_base)
pasta_fila  <- sprintf('%s/fila', pasta_dados)
pasta_fotos_ret <- sprintf('%s/03_image_sequences', pasta_base)
dir.create(pasta_fotos_ret, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------------------------
# Gerar .mp4 dual fisheye a partir dos vídeos originais
# ------------------------------------------------------------------------------

# Definir arquivos de entrada e saída
arqs_videos <- list.files(pasta_fila, pattern = '\\.insv$', full.names = TRUE)
out_mp4 <- sprintf('%s/tmp_video.mp4', pasta_fila)

# Converter arquivos .insv para .mp4 (dual fisheye)
# ffmpeg -i VID_20250409_140416_00_003.insv -i VID_20250409_140416_10_003.insv -filter_complex "[0:v][1:v]hstack=inputs=2" -c:v libx264 -crf 23 -preset ultrafast boo.mp4
message('\nConvertendo arquivos .insv em .mp4 com o ffmpeg.\n')
ffmpeg_path <- sprintf("/usr/bin/ffmpeg")
arg_o1 <- sprintf('-i "%s"', arqs_videos[1])
arg_o2 <- sprintf('-i "%s"', arqs_videos[2])
# arg_o3 <- sprintf('-filter_complex "[0:v][1:v]hstack=inputs=2" -c:v libx264 -crf 23 -preset ultrafast -y %s', out_mp4)
arg_o3 <- sprintf('-filter_complex "[0:v][1:v]hstack=inputs=2" -c:v libx264 -crf 0 -y %s', out_mp4)
system2(command = ffmpeg_path, args = c(arg_o1, arg_o2, arg_o3))

# Limpar ambiente
rm(arg_o1, arg_o2, arg_o3)


# ------------------------------------------------------------------------------
# Combinar duas imagens do vídeo em uma imagem 360 - saída em sequência JPG
# ------------------------------------------------------------------------------

# VID_20250409_140416_00_003.insv -> VID_20250409_140416
basename_jpgs <- basename(arqs_videos[1]) %>% str_sub(5, 19)
pasta_fotos   <- sprintf('%s/04_mapillary_sequences/%s', pasta_base, basename_jpgs)
dir.create(pasta_fotos, recursive = TRUE, showWarnings = FALSE)
# Definir valores para corrigir distorção no encontro entre as duas imagens 180°
fov <- 195

# Converter arquivo .mp4 em sequência de JPGs
# ffmpeg -i tmp_video.mp4 -vf v360=dfisheye:e:yaw=0:ih_fov=195:iv_fov=195 output_%05d.jpg
message('\nConvertendo arquivo .mp4 em sequência JPG com o ffmpeg.\n')
arg_o1 <- sprintf('-i "%s"', out_mp4)
arg_o2 <- sprintf('-vf v360=dfisheye:e:yaw=0:ih_fov=%s:iv_fov=%s -qmin 1 -q:v 1', fov, fov)
arg_o3 <- sprintf('%s/%s_%%05d.jpg', pasta_fotos, basename_jpgs)
system2(command = ffmpeg_path, args = c(arg_o1, arg_o2, arg_o3))

# Não precisamos mais do arquivo .mp4
file.remove(out_mp4)


# ------------------------------------------------------------------------------
# Gerar imagens retilineares a partir das imagens 360°
# ------------------------------------------------------------------------------

# Extrair as porções frontais dos frames
# ffmpeg -framerate 1 -start_number 1 -i 20250409_143230_%05d.jpg -vf "v360=e:rectilinear:yaw=0:h_fov=90:v_fov=90" -y 00_lala_%05d.jpg
message('\nExtraindo frames retilineares das imagens 360° com o ffmpeg.\n')
arg_o1 <- sprintf('-framerate 1 -start_number 1 -i %s/%s_%%05d.jpg', pasta_fotos, basename_jpgs)
arg_o2 <- sprintf('-vf "v360=e:rectilinear:yaw=0:h_fov=90:v_fov=90"', fov, fov)
arg_o3 <- sprintf('-y %s/%s_%%05d_ret.jpg', pasta_fotos_ret, basename_jpgs)
system2(command = ffmpeg_path, args = c(arg_o1, arg_o2, arg_o3))

# Limpar ambiente
rm(arg_o1, arg_o2, arg_o3)


# ------------------------------------------------------------------------------
# Gerar gpx para revisão
# ------------------------------------------------------------------------------

# Temos um arquivo .gpx gerado pelo osmtracker. O problema: ele deveria estar
# gravando os pontos a cada 4 segundos, mas está gerando a intervalos completamente
# aleatórios.Vamos precisar abrir esse .gpx, reescrever as infos de tempo e
# revisá-lo no QGIS para ver se está tudo ok.

# Abrir arquivo GPX
gpx <- list.files(pasta_fila, pattern = '.*\\.gpx$', full.names = TRUE)
gpx <- data.frame(read_gpx(gpx)$tracks) %>% select(Elevation = 1,
                                                   Time = 2,
                                                   Latitude = 3,
                                                   Longitude = 4,
                                                   speed = 5,
)

# Puxar endereços das imagens - vamos querer ver também se há mais imagens do que
# pontos no .gox
images <- data.frame(X1 = list.files(pasta_fotos, pattern = '.*\\.jpg$', full.names = FALSE))
images <- images %>% mutate(X1 = str_replace(X1, '\\.jpg', '_ret.jpg'),
                            imagepath = str_c(pasta_fotos_ret, basename(X1), sep = '/'))

qtd_ptos <- nrow(gpx); qtd_fotos <- nrow(images)
print(sprintf('Linhas GPX: %s - Qtd fotos: %s', qtd_ptos, qtd_fotos))


# Se quantidade de fotos for maior do que os pontos registrados no arquivo .gpx,
# vamos fazer a associação a partir do último ponto e repetir os primeiros. Isso
# porque a gravação em campo está sendo feita:
# 1. Rec na câmera, que demora vários segundos para começar a gravar;
# 2. Uma vez gravando, iniciar a gravação no osm_tracker;
# 3. Percorrer o trecho;
# 4. Parar a gravação na câmera;
# 5. Parar a gravação no osm_tracker.
# Por isso, sincronizar de trás para frente deve gerar menos imagens deslocadas
# no que se refere ao geoposicionamento
if (qtd_fotos > qtd_ptos) {
  # Inverter a ordem as imagens e dos pontos gravados
  images <- images %>% arrange(desc(X1))
  gpx <- gpx %>% arrange(desc(Time))

  # Adicionar linhas ao gpx, copiando os valores do primeiro registro (agora, na
  # última linha)
  ultima_linha <- gpx %>% slice(n())

  # Linhas a adicionar
  novas_linhas <- qtd_fotos - qtd_ptos

  # Adicionar novas linhas, repetindo valor da última
  gpx <- gpx %>% bind_rows(replicate(novas_linhas, ultima_linha, simplify = FALSE))

  # Juntar dataframes e voltar à ordem original de gravação
  images <- cbind(images, gpx) %>% arrange(X1)


  # Precisamos redistribuir proporcionalmente os pontos no espaço, para facilitar
  # a revisão da posição deles no QGIS

  # 1. Converter os pontos em sf LINESTRING
  linha <- images %>%
    select(lon = Longitude, lat = Latitude) %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%  # WGS84
    # Transformar para SIRGAS 23S para considerar distâncias corretamente
    st_transform(31983) %>%
    summarise(geometry = st_combine(geometry)) %>%
    st_cast("LINESTRING")

  mapview(linha)

  # 2. Transformar linha em uma sequência de pontos, na qual a quantidade desses
  # pontos está definida por qtd_fotos
  pontos_equidistantes <- linha %>%
    st_line_sample(n = qtd_fotos, type = "regular") %>%
    st_cast("POINT") %>%
    st_sf() %>%
    # Transformar de volta em WGS84 para obter os latlon
    st_transform(4326)

  mapview(pontos_equidistantes, cex = 2)


  # Conferir a partir do original
  # gpx %>% select(lon = Longitude, lat = Latitude) %>% st_as_sf(coords = c("lon", "lat"), crs = 4326) %>% mapview(col.regions = 'red', cex = 3)

  # Juntar novas coordenadas geográficas em um sf
  images <- cbind(pontos_equidistantes, images)

  # Converter em dataframe com colunas de latlon
  # pontos_equidistantes <-
  #   pontos_equidistantes %>%
  #   mutate(id = row_number()) %>%
  #   mutate(
  #     lon = st_coordinates(.)[,1],
  #     lat = st_coordinates(.)[,2]
  #   ) %>%
  #   select(id, lat, lon)

  # rm(ultima_linha, qtd_fotos, qtd_ptos, linha, pontos_equidistantes)
}

# O GPX não está gravando os pontos no intervalo de tempo correto, que seria de
# 4 segundos. Vamos pegar a primeira ocorrência de tempo e forçar um registro a
# cada 4s, substituindo os tempos originais
min_time <- as.POSIXct(min(images$Time), origin = "1970-01-01")

# Criar série a cada 4s
time_series <- min_time + seq(0, by = 4, length.out = nrow(images))
time_series <- data.frame(Time = time_series)

# Substituir tempos no gpx
images <- images %>% select(-Time) %>% cbind(time_series)


# Gerar shapefile a partir do gpx
# images <- images %>% st_as_sf(coords = c('Longitude', 'Latitude'), crs = 4326, remove = TRUE)

out_file <- sprintf('%s/gpx_para_revisao.gpkg', pasta_fila)
st_write(images, out_file, driver = 'GPKG', append = FALSE, delete_layer = TRUE)


# Limpar ambiente
print(sprintf('Linhas GPX: %s - Qtd fotos: %s', qtd_ptos, qtd_fotos))
rm(list = ls())
gc(T)

# ------------------------------------------------------------------------------
# Revisar arquivo .GPX no QGIS e salvar arquivo revisado como novo .gpx
# ------------------------------------------------------------------------------

# Ao abrir o arquivo no QGIS:
# 1. Checar como as fotos estão posicionadas no mapa e ajustar onde necessário;
#
# 2. Colar os pontos nas estruturas cicloviárias, utilizando os scripts PyQGIS:
# - A. Gravar latlon originais no shape (01_latlon_to_columns.py);
# - B. Colar pontos nas estruturas cicloviárias (02_move_selected_points.py);
# - C. Desfazer B (acima) caso preciso (03_latlon_cols_to_geometry.py);
# - D. Gerar colunas de lat lon com novas coordenadas (04_latlon_rev_to_cols.py)
#
# 3. Uma vez feito isso, exportar como .GPX, habilitando as opções:
# GPX_USE_EXTENSIONS = TRUE e
# FORCE_GPX_TRACK = TRUE
#
# Salvar arquivo como "gpx_revisto.gpx" na mesma pasta_dados


# Se precisar, usar Processing Toolbox > Points along geometry para criar pontos em
# trechos do OSM (camada sao_paulo_osm_filtrado) que não estão com infra cicloviária ainda
# Conversão: 2 metros = 0.000018 em graus