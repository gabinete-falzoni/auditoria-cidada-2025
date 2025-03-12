library('tidyverse')
library('tidylog')


# Estrutura de pastas
pasta_dados <- '../dados'
pasta_fotos <- sprintf('%s/fotos', pasta_dados)
pasta_apaga <- sprintf('%s/fotos_apagadas', pasta_fotos)
pasta_reduz <- sprintf('%s/fotos_reduzidas', pasta_fotos)
pasta_temat <- sprintf('%s/fotos_tematicas', pasta_fotos)
pasta_redu_med <- sprintf('%s/01_medicao', pasta_temat)
pasta_redu_156 <- sprintf('%s/05_sp_156', pasta_temat)
dir.create(pasta_apaga, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------------------------
# Quais fotos não estão na pasta de temáticas mas ainda estão na de reduzidas?
# ------------------------------------------------------------------------------

# Algumas fotos foram apagadas ao serem atribuídas a pastas temáticas. Como esse
# processo é posterior ao de cópia das fotos reduzidas para essa pasta, precisamos
# sincronizar esses dois diretórios

fotos_tematicas <- data.frame(imgs = basename(list.files(pasta_temat, recursive = TRUE))) %>% distinct()
head(fotos_tematicas)

fotos_reduzidas <- data.frame(imgs = basename(list.files(pasta_reduz, recursive = FALSE)),
                              paths = list.files(pasta_reduz, recursive = FALSE, full.names = TRUE))
head(fotos_reduzidas)

fotos_apagadas <- fotos_reduzidas %>% filter(!imgs %in% fotos_tematicas$imgs)
head(fotos_apagadas)

# Mover fotos que foram removidas para pasta específica
for (pic in fotos_apagadas$paths) {
  out_file <- sprintf('%s/%s', pasta_apaga, basename(pic))
  file.copy(from = pic, to = out_file)
  file.remove(pic)
}


# ------------------------------------------------------------------------------
# Mover fotos de medições dentro da pasta de fotos originais
# ------------------------------------------------------------------------------

# Estrutura de pastas
pasta_orig  <- '../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/fotos_originais'
pasta_orig_med <- sprintf('%s/fotos_medicoes_originais', pasta_orig)
dir.create(pasta_orig_med, recursive = TRUE, showWarnings = FALSE)

# Quais são as fotos selecionadas como sendo de medição?
fotos_medicao <- data.frame(imgs = basename(list.files(pasta_redu_med, recursive = TRUE))) %>% distinct()
head(fotos_medicao)

fotos_originais <- data.frame(imgs = basename(list.files(pasta_orig, recursive = FALSE)),
                              paths = list.files(pasta_orig, recursive = FALSE, full.names = TRUE))
head(fotos_originais)

fotos_para_mover <- fotos_originais %>% filter(imgs %in% fotos_medicao$imgs)
head(fotos_para_mover)

# Na pasta de fotos originais, separar fotos de medição em pasta específica
for (pic in fotos_para_mover$paths) {
  # pic <- fotos_para_mover$paths[1]
  out_file <- sprintf('%s/%s', pasta_orig_med, basename(pic))
  file.copy(from = pic, to = out_file)
  file.remove(pic)
}


# ------------------------------------------------------------------------------
# Copiar fotos de SP_156 para pasta específica
# ------------------------------------------------------------------------------

# Estrutura de pastas
pasta_orig  <- '../../../BKP_Auditoria_Cidada_2025_Fotos_Originais/fotos_originais'
pasta_orig_156 <- sprintf('%s/fotos_sp156_originais', pasta_orig)
dir.create(pasta_orig_156, recursive = TRUE, showWarnings = FALSE)

# Quais são as fotos selecionadas como sendo de medição?
fotos_sp156 <- data.frame(imgs = basename(list.files(pasta_redu_156, recursive = TRUE))) %>% distinct()
head(fotos_sp156)

fotos_originais <- data.frame(imgs = basename(list.files(pasta_orig, recursive = TRUE)),
                              paths = list.files(pasta_orig, recursive = TRUE, full.names = TRUE))
head(fotos_originais)

fotos_para_copiar <- fotos_originais %>% filter(imgs %in% fotos_sp156$imgs)
head(fotos_para_copiar)

# Na pasta de fotos originais, separar fotos de medição em pasta específica
for (pic in fotos_para_copiar$paths) {
  # pic <- fotos_para_copiar$paths[1]
  out_file <- sprintf('%s/%s', pasta_orig_156, basename(pic))
  file.copy(from = pic, to = out_file)

}
