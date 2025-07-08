# Move os arquivos da pasta fila para a pasta de trabalho e, em seguida, puxa
# os arquivos seguintes .insv e .gpx para a pasta de fila

library('fs') # copiar pastas

# Estrutura de pastas
# pasta_base  <- '/media/livre/Expansion/Dados_Comp_Gabinete/Campo_Camera360'
pasta_base  <- '/mnt/fern/Dados/Campo_Camera360'
pasta_dados <- sprintf('%s/00_pasta_de_trabalho', pasta_base)


# ------------------------------------------------------------------------------
# Limpar ambiente
# ------------------------------------------------------------------------------

# Remover arquivos da pasta de trabalho
rm_file1 <- sprintf('%s/gpx_para_revisao.gpkg', pasta_dados)
# rm_file2 <- sprintf('%s/gpx_revisto.qmd', pasta_dados)
out_tsv <- sprintf('%s/00_fotos_todas.tsv', pasta_dados)
out_file <- sprintf('%s/00_shape_fotos.gpkg', pasta_dados)
file.remove(out_tsv, out_file, rm_file1)
gpx <- list.files(pasta_dados, pattern = '.*\\.gpx$', full.names = TRUE)
file.remove(arqs_videos, gpx)

# Mover arquivos da fila para pasta de trabalho
pasta_fila  <- sprintf('%s/fila', pasta_dados)
for (arq in list.files(pasta_fila, recursive = FALSE, full.names = TRUE)) {
  print(arq)
  file.copy(arq, pasta_dados)
  file.remove(arq)
}


# Copiar arquivos seguintes de vídeo para a pasta de fila e para pasta de backup
pasta_bkp_vd <- sprintf('%s/02_timelapses_originais_bkp', pasta_base)
proximos_videos <- list.files(pasta_base, pattern = '\\.insv', recursive = FALSE, full.names = TRUE)[1:2]
file.copy(proximos_videos, pasta_bkp_vd)
file.copy(proximos_videos, pasta_fila)


# Copiar arquivos seguintes de GPX para a pasta de fila e para pasta de backup
pasta_gpx <- sprintf('%s/osmtracker', pasta_base)
pasta_bkp_gpx <- sprintf('%s/01_gpx_originais_bkp', pasta_base)

proxima_pasta_gpx <- list.dirs(pasta_gpx)[2] # Arquivo 1 é a própria pasta
fs::dir_copy(proxima_pasta_gpx, pasta_bkp_gpx)

proximo_gpx <- list.files(proxima_pasta_gpx, recursive = FALSE, full.names = TRUE)
file.copy(proximo_gpx, pasta_fila)


# Quais são os próximos arquivos a serem processados?
this <-
  data.frame(arqs = list.files(pasta_fila)) %>%
  mutate(times = case_when(str_detect(arqs, 'insv') ~ str_sub(arqs, 14, 19),
                           TRUE ~ str_replace_all(str_sub(arqs, 12, 19), '-', '')
  ))
this

time_dif <- as.integer(this$times[1]) - as.integer(this$times[2])
message(sprintf('Diferença de tempo: %s segundo(s)', time_dif))


# Garantidos que os arquivos foram copiados, remover da pasta geral
file.remove(proximos_videos)
unlink(proxima_pasta_gpx, recursive = TRUE)

# Limpar ambiente
rm(list = ls())
gc(T)

