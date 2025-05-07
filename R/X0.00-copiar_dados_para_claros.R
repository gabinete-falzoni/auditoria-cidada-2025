library('tidyverse')
library('tidylog')

# Estrutura de pastas
pasta_dados <- '../dados'
pasta_fotos <- sprintf('%s/fotos', pasta_dados)
pasta_reduz <- sprintf('%s/fotos_reduzidas', pasta_fotos)
pasta_f_orig <- '../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/fotos_originais'


pasta_claros <- sprintf('%s/x_claros', pasta_dados)
pasta_c_fotos <- sprintf('%s/fotos', pasta_claros)
# pasta_c_dorig <- sprintf('%s/dados_originais', pasta_claros)
dir.create(pasta_c_fotos, recursive = TRUE, showWarnings = FALSE)
# dir.create(pasta_c_dorig, recursive = TRUE, showWarnings = FALSE)



shape_auditoria <- list.files(pasta_dados, pattern = 'gpkg$', full.names = TRUE)
file.copy(shape_auditoria, pasta_claros, overwrite = TRUE)

arquivo_qgis <- list.files(pasta_dados, pattern = 'qgz$', full.names = TRUE)
file.copy(arquivo_qgis, pasta_claros, overwrite = TRUE)



# ------------------------------------------------------------------------------
# Fotos reduzidas
# ------------------------------------------------------------------------------

# Fotos que haviam sido copiadas antes
pasta_claros_anterior <- sprintf('%s/x_claros_1', pasta_dados)
pasta_claros_fotos_red_antes <- sprintf('%s/fotos/fotos_reduzidas', pasta_claros_anterior)

# Pasta para colocar novas fotos
pasta_destino <- sprintf('%s/fotos_reduzidas', pasta_c_fotos)
dir.create(pasta_destino, recursive = TRUE, showWarnings = FALSE)


# Quais fotos já estavam antes na pasta?
fotos_antes <- data.frame(imgs = basename(list.files(pasta_claros_fotos_red_antes, recursive = FALSE))) %>% distinct()

# Quais são as novas fotos que precisam ser copiadas (exceto as que já haviam
# sido copiadas)?
fotos_novas <- data.frame(imgs = basename(list.files(pasta_reduz, recursive = FALSE)),
                          paths = list.files(pasta_reduz, recursive = FALSE, full.names = TRUE))


fotos_para_copiar <- fotos_novas %>% filter(!imgs %in% fotos_antes$imgs)
head(fotos_para_copiar)

# Na pasta de fotos originais, separar fotos de medição em pasta específica
for (pic in fotos_para_copiar$paths) {
  # pic <- fotos_para_copiar$paths[1]
  out_file <- sprintf('%s/%s', pasta_destino, basename(pic))
  file.copy(from = pic, to = out_file)
}


# ------------------------------------------------------------------------------
# Fotos originais
# ------------------------------------------------------------------------------

# Fotos que haviam sido copiadas antes
pasta_claros_fotos_orig_antes <- sprintf('%s/fotos_originais', pasta_claros_anterior)

# Pasta para colocar novas fotos
pasta_destino <- sprintf('%s/fotos_originais', pasta_claros)
dir.create(pasta_destino, recursive = TRUE, showWarnings = FALSE)


# Quais fotos já estavam antes na pasta?
fotos_antes <- data.frame(imgs = basename(list.files(pasta_claros_fotos_orig_antes, recursive = FALSE))) %>% distinct()

# Quais são as novas fotos que precisam ser copiadas (exceto as que já haviam
# sido copiadas)?
fotos_novas <- data.frame(imgs = basename(list.files(pasta_f_orig, recursive = FALSE)),
                          paths = list.files(pasta_f_orig, recursive = FALSE, full.names = TRUE))


fotos_para_copiar <- fotos_novas %>% filter(!imgs %in% fotos_antes$imgs)
head(fotos_para_copiar)

# Na pasta de fotos originais, separar fotos de medição em pasta específica
for (pic in fotos_para_copiar$paths) {
  # pic <- fotos_para_copiar$paths[1]
  out_file <- sprintf('%s/%s', pasta_destino, basename(pic))
  file.copy(from = pic, to = out_file)
}


# pasta_fotos_orig <-
#   data.frame(arqs = list.dirs(pasta_f_orig, full.names = TRUE)) %>%
#   filter(str_detect(arqs, 'fotos_originais$')) %>%
#   pull()
# file.copy(pasta_fotos_orig, pasta_claros, overwrite = TRUE, recursive = TRUE)

# pasta_fotos <-
#   data.frame(arqs = list.dirs(pasta_reduz, full.names = TRUE, recursive = TRUE)) %>%
#   filter(str_detect(arqs, 'fotos_reduzidas')) %>%
#   pull()
# file.copy(pasta_fotos, pasta_c_fotos, overwrite = TRUE, recursive = TRUE)

# pasta_CET <-
#   data.frame(arqs = list.dirs(pasta_dados, full.names = TRUE, recursive = TRUE)) %>%
#   filter(str_detect(arqs, 'CET')) %>%
#   slice(1) %>%
#   pull()
# file.copy(pasta_CET, pasta_c_dorig, overwrite = TRUE, recursive = TRUE)

# pasta_dados_trab <-
#   data.frame(arqs = list.dirs(pasta_dados, full.names = TRUE)) %>%
#   filter(str_detect(arqs, 'dados_trabalhados')) %>%
#   slice(1) %>%
#   pull()
# file.copy(pasta_dados_trab, pasta_claros, overwrite = TRUE, recursive = TRUE)




# ------------------------------------------------------------------------------
# Fotos medições
# ------------------------------------------------------------------------------

# Fotos que já foram analisadas pelo Claros, por terem sido copiadas antes
pasta_medicoes_ja_copiadas <- sprintf('%s/x_claros_1/fotos_originais/fotos_medicoes_originais', pasta_dados)

# Pasta para colocar novas fotos
pasta_destino <- sprintf('%s/fotos_originais/fotos_medicoes_originais', pasta_claros)
dir.create(pasta_destino, recursive = TRUE, showWarnings = FALSE)


# Quais fotos já estavam antes na pasta?
fotos_antes <- data.frame(imgs = basename(list.files(pasta_medicoes_ja_copiadas, recursive = TRUE))) %>% distinct()

# Quais são as novas fotos que precisam ser copiadas (exceto as que já haviam
# sido copiadas)?
fotos_medicoes_todas <- sprintf('%s/fotos_medicoes_originais', pasta_f_orig)
fotos_novas <- data.frame(imgs = basename(list.files(fotos_medicoes_todas, recursive = FALSE)),
                          paths = list.files(fotos_medicoes_todas, recursive = FALSE, full.names = TRUE))


fotos_para_copiar <- fotos_novas %>% filter(!imgs %in% fotos_antes$imgs)
head(fotos_para_copiar)

# Na pasta de fotos originais, separar fotos de medição em pasta específica
for (pic in fotos_para_copiar$paths) {
  # pic <- fotos_para_copiar$paths[1]
  out_file <- sprintf('%s/%s', pasta_destino, basename(pic))
  file.copy(from = pic, to = out_file)
}


# ------------------------------------------------------------------------------
# Fotos SP 156
# ------------------------------------------------------------------------------

# Fotos que já foram analisadas pelo Claros, por terem sido copiadas antes
pasta_156_ja_copiadas <- sprintf('%s/x_claros_1/fotos_originais/fotos_sp156_originais', pasta_dados)

# Pasta para colocar novas fotos
pasta_destino <- sprintf('%s/fotos_originais/fotos_sp156_originais', pasta_claros)
dir.create(pasta_destino, recursive = TRUE, showWarnings = FALSE)


# Quais fotos já estavam antes na pasta?
fotos_antes <- data.frame(imgs = basename(list.files(pasta_156_ja_copiadas, recursive = TRUE))) %>% distinct()

# Quais são as novas fotos que precisam ser copiadas (exceto as que já haviam
# sido copiadas)?
fotos_156_todas <- sprintf('%s/fotos_sp156_originais', pasta_f_orig)
fotos_novas <- data.frame(imgs = basename(list.files(fotos_156_todas, recursive = FALSE)),
                          paths = list.files(fotos_156_todas, recursive = FALSE, full.names = TRUE))


fotos_para_copiar <- fotos_novas %>% filter(!imgs %in% fotos_antes$imgs)
head(fotos_para_copiar)

# Na pasta de fotos originais, separar fotos de medição em pasta específica
for (pic in fotos_para_copiar$paths) {
  # pic <- fotos_para_copiar$paths[1]
  out_file <- sprintf('%s/%s', pasta_destino, basename(pic))
  file.copy(from = pic, to = out_file)
}
