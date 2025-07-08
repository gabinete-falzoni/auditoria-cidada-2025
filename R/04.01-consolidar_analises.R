# A partir dos arquivos segmentos.gpkg e intersecao.gpkg

library('tidyverse')
library('tidylog')
library('sf')
library('mapview')

pasta_base  <- '/mnt/fern/Dados/Campo_Camera360/07_publicacao'
# pasta_base  <- '/media/livre/Expansion/Dados_Comp_Gabinete/gitlab/auditoria-cidada-2025/dados/dados_trabalhados/analises/'
pasta_analises   <- sprintf('%s/analises', pasta_base)
# pasta_publicacao <- sprintf('%s/dados_x_publicacao', pasta_base)


agrupar <- function(df, group_var) {
  df %>%
    group_by(!!group_var) %>%
    tally() %>%
    ungroup() %>%
    mutate(prop = n / sum(n) * 100)
}



# ------------------------------------------------------------------------------
# Quadras - Atribuição de notas
# ------------------------------------------------------------------------------

quadra <- sprintf('%s/segmentos.gpkg', pasta_analises)
quadra <- read_sf(quadra)
# mapview(quadra)

# Ordenar colunas para
quadra <- quadra %>% select(PROGRAMA_DE_CICLOVIAS,
                            TIPOLOGIA,
                            SENTIDO,
                            LOCALIZACAO,
                            EXTENSAO,
                            MENOS,
                            INAUGURACAO,
                            ORGAO_EXECUTOR,
                            TIPO,
                            TITULO,
                            PREP,
                            VIA,
                            STATUS,
                            REGIAO,
                            SUBP,
                            GET,
                            DET,

                            id_original,
                            TIPOLOGIA_rev,
                            SENTIDO_rev,
                            LOCALIZACAO_rev, # Revisto somente para ciclovias
                            sin_tachao = tachao,
                            sin_l_bordo = linha_bordo,
                            sin_l_vermelha = linha_vermelha,
                            sin_l_amarela = linha_amarela,
                            # sin_aprox = aproximacao,
                            sin_picto_seta = pictograma_seta,
                            pavimento,
                            largura_cm,
                            em_recapeamento,
                            trecho_inexistente,
                            gradil,
                            excluir_sarjeta,
                            observacao = Observacao,
                            length_m_original,
                            length_m_atual,
                            prop_ext_atual_original,
                            EXTENSAO_atual,
                            MENOS_atual,
                            geom)

quadra <- quadra %>% mutate(id_linha = 1:nrow(.), .before = 1)
names(quadra)

notas <-
  quadra %>%
  st_drop_geometry() %>%
  select(id_linha, matches('^sin_'), em_recapeamento, trecho_inexistente) %>%
  mutate(sin_soma = select(., matches("sin_")) %>% rowSums(na.rm = TRUE),
         sin_qtd_itens = rowSums(!is.na(select(., matches("sin_")))),
         sin_media = sin_soma / sin_qtd_itens,
         sin_media_floor = floor(sin_media),
         sin_media_floor_rev = ifelse(!is.na(sin_tachao) & sin_tachao < sin_media_floor, sin_tachao, sin_media_floor)) %>%
  # Ajustar: se for recapeamento, nota precisa ser NA
  mutate(sin_media_floor     = ifelse(em_recapeamento == TRUE | trecho_inexistente == TRUE | is.na(sin_media), as.numeric(NA), sin_media_floor),
         sin_media_floor_rev = ifelse(em_recapeamento == TRUE | trecho_inexistente == TRUE | is.na(sin_media), as.numeric(NA), sin_media_floor_rev)) %>%
  select(id_linha, sin_qtd_itens, sin_media, sin_media_floor, sin_media_floor_rev)

# quadra %>% st_drop_geometry() %>% filter(id_linha == 2411) %>%
#   select(id_linha, matches('^sin_'), em_recapeamento)

sample_n(notas, 20)


# Juntar de volta no dataframe principal
quadra <- quadra %>% left_join(notas, by = 'id_linha') %>% relocate(geom, .after = last_col())
rm(notas)

# out_gpkg <- sprintf('%s/teste_classificacao.gpkg', pasta_analises)
# st_write(quadra, out_gpkg, driver = 'GPKG', append = FALSE, delete_layer = TRUE)


# ------------------------------------------------------------------------------
# Quadras - Atribuição de notas de Largura
# ------------------------------------------------------------------------------

# Atualizar: calçadas partilhadas vão ter tipologia revista: ou é sobre canteiro
# central, ou é sobre a calçada
calc_part <- quadra %>% filter(TIPOLOGIA_rev == 'CALÇADA PARTILHADA')
demais_est <- quadra %>% filter(TIPOLOGIA_rev != 'CALÇADA PARTILHADA')

# # Testar alterações
# calc_part %>%
#   st_drop_geometry() %>%
#   sample_n(20) %>%
#   select(id_original, TIPOLOGIA_rev, SENTIDO_rev, LOCALIZACAO, LOCALIZACAO_rev, excluir_sarjeta, gradil, largura_cm) %>%
#   mutate(LOCALIZACAO_rev = ifelse(str_starts(LOCALIZACAO_rev, '(S)?OBRE O CANTEIRO'), 'SOBRE O CANTEIRO CENTRAL', 'SOBRE A CALÇADA'))

# Fazer alterações
calc_part <- calc_part %>%
  mutate(LOCALIZACAO_rev = ifelse(str_starts(LOCALIZACAO_rev, '(S)?OBRE O CANTEIRO'), 'SOBRE O CANTEIRO CENTRAL', 'SOBRE A CALÇADA'))

quadra <- rbind(demais_est, calc_part) %>% arrange(id_linha)
# quadra %>%
#   st_drop_geometry() %>%
#   filter(TIPOLOGIA_rev == 'CALÇADA PARTILHADA') %>%
#   select(id_original, TIPOLOGIA_rev, SENTIDO_rev, LOCALIZACAO, LOCALIZACAO_rev, excluir_sarjeta, gradil, largura_cm) %>%
#   sample_n(20)
rm(demais_est, calc_part)


quadra_largura <-
  quadra %>%
  # Adicionar margem de erro nas larguras, em cm
  mutate(largura_cm = largura_cm + 10) %>%
  # agrupar(expr(LOCALIZACAO_rev))
  mutate(class_largura = case_when(
    # Nota 4
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & largura_cm >= 195 ~ 4,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & largura_cm >= 150 ~ 4,
    SENTIDO_rev == 'UNIDIRECIONAL' & (TIPOLOGIA_rev %in% c('CICLOVIA', 'CALÇADA PARTILHADA')) & largura_cm >= 150 ~ 4,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & largura_cm >= 295 ~ 4,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & largura_cm >= 250 ~ 4,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == FALSE & largura_cm >= 255 ~ 4,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == TRUE & largura_cm >= 275 ~ 4,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE O CANTEIRO CENTRAL' & largura_cm >= 275 ~ 4,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE A CALÇADA' & largura_cm >= 255 ~ 4,
    # Nota 3
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & between(largura_cm, 145, 194) ~ 3,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & between(largura_cm, 100, 149) ~ 3,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & between(largura_cm, 100, 149) ~ 3,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & between(largura_cm, 115, 149) ~ 3,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & between(largura_cm, 225, 294) ~ 3,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & between(largura_cm, 180, 249) ~ 3,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == FALSE & between(largura_cm, 200, 254) ~ 3,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == TRUE & between(largura_cm, 180, 274) ~ 3,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE O CANTEIRO CENTRAL' & between(largura_cm, 215, 274) ~ 3,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE A CALÇADA' & between(largura_cm, 230, 254) ~ 3,
    # Notas 2
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & between(largura_cm, 125, 144) ~ 2,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & between(largura_cm, 80, 99) ~ 2,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & between(largura_cm, 80, 99) ~ 2,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & between(largura_cm, 105, 114) ~ 2,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & between(largura_cm, 205, 224) ~ 2,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & between(largura_cm, 160, 179) ~ 2,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == FALSE & between(largura_cm, 180, 199) ~ 2,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == TRUE & between(largura_cm, 140, 179) ~ 2,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE O CANTEIRO CENTRAL' & between(largura_cm, 165, 214) ~ 2,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE A CALÇADA' & between(largura_cm, 160, 229) ~ 2,
    # Notas 1
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & largura_cm <= 124 ~ 1,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & largura_cm <= 79 ~ 1,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & largura_cm <= 79 ~ 1,
    SENTIDO_rev == 'UNIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & largura_cm <= 104 ~ 1,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == FALSE & largura_cm <= 204 ~ 1,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOFAIXA' & excluir_sarjeta == TRUE & largura_cm <= 159 ~ 1,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == FALSE & largura_cm <= 179 ~ 1,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CICLOVIA' & gradil == TRUE & largura_cm <= 139 ~ 1,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE O CANTEIRO CENTRAL' & largura_cm <= 164 ~ 1,
    SENTIDO_rev == 'BIDIRECIONAL' & TIPOLOGIA_rev == 'CALÇADA PARTILHADA' & LOCALIZACAO_rev == 'SOBRE A CALÇADA' & largura_cm <= 159 ~ 1,
    TRUE ~ NA)) %>%
  select(id_linha, id_original, SENTIDO_rev, TIPOLOGIA_rev, excluir_sarjeta, LOCALIZACAO_rev, gradil, largura_cm, class_largura, EXTENSAO_atual, trecho_inexistente, em_recapeamento) # %>%
# filter(!TIPOLOGIA_rev %in% c('CALÇADA COMPARTILHADA', 'CICLORROTA') & !is.na(largura_cm)) %>%
# filter(is.na(class_largura))


# Calçadas compartilhadas: se tiverem 290 cm estão no desejável; senão são irregulares
calc_comp <- quadra_largura %>% filter(TIPOLOGIA_rev == 'CALÇADA COMPARTILHADA')
outros    <- quadra_largura %>% filter(TIPOLOGIA_rev != 'CALÇADA COMPARTILHADA')
# Fazer alteração
calc_comp <- calc_comp %>% mutate(class_largura = ifelse(largura_cm >= 290, 4, 1))
# Conferir
calc_comp %>% st_drop_geometry() %>% filter(!is.na(largura_cm)) %>% sample_n(20) %>% select(id_linha, TIPOLOGIA_rev, largura_cm, class_largura)
calc_comp %>% st_drop_geometry() %>% filter(!is.na(largura_cm) & class_largura == 4) %>% select(id_linha, TIPOLOGIA_rev, largura_cm, class_largura)

# Reconstituir dataframe
quadra_largura <- rbind(calc_comp, outros) %>% arrange(id_linha)
rm(calc_comp, outros)


# Trechos em recapeamento ou inexistentes terão class_largura NULL
quadra_largura <-
  quadra_largura %>%
  mutate(class_largura = ifelse(trecho_inexistente == TRUE | em_recapeamento == TRUE, as.numeric(NA), class_largura))

quadra_largura %>%
  st_drop_geometry() %>%
  filter(!is.na(class_largura)) %>%
  # group_by(TIPOLOGIA_rev, class_largura) %>%
  group_by(class_largura) %>%
  summarise(ext = sum(EXTENSAO_atual)) %>%
  mutate(perc = ext / sum(ext) * 100)
# class_largura     ext  perc
# <dbl>   <dbl> <dbl>
# 1             1 153247. 17.1
# 2             2 338566. 37.7
# 3             3 329120. 36.6
# 4             4  77340.  8.61

# out_gpkg <- sprintf('%s/teste_classificacao_largura.gpkg', pasta_analises)
# st_write(quadra_largura, out_gpkg, driver = 'GPKG', append = FALSE, delete_layer = TRUE)

# Juntar com dataframe principal
quadra_largura <- quadra_largura %>% st_drop_geometry() %>% select(id_linha, class_largura)
quadra <- quadra %>% left_join(quadra_largura, by = 'id_linha') %>% relocate(class_largura, .before = 'geom')
rm(quadra_largura)
names(quadra)

# Ordenar colunas para
quadra <- quadra %>% select(id_linha,
                            PROGRAMA_DE_CICLOVIAS,
                            TIPOLOGIA,
                            SENTIDO,
                            LOCALIZACAO,
                            EXTENSAO,
                            MENOS,
                            INAUGURACAO,
                            ORGAO_EXECUTOR,
                            TIPO,
                            TITULO,
                            PREP,
                            VIA,
                            STATUS,
                            REGIAO,
                            SUBP,
                            GET,
                            DET,

                            id_original,
                            TIPOLOGIA_rev,
                            SENTIDO_rev,
                            LOCALIZACAO_rev,
                            EXTENSAO_atual,
                            em_recapeamento,
                            trecho_inexistente,

                            sin_tachao,
                            sin_l_bordo,
                            sin_l_vermelha,
                            sin_l_amarela,
                            sin_picto_seta,
                            # sin_aprox = aproximacao,
                            sin_qtd_itens,
                            sin_media,
                            sin_media_floor,
                            sin_media_floor_rev,
                            pavimento,
                            largura_cm,
                            class_largura,
                            gradil,
                            excluir_sarjeta,
                            observacao,
                            length_m_original,
                            length_m_atual,
                            prop_ext_atual_original,
                            MENOS_atual,
                            geom)


out_gpkg <- sprintf('%s/auditoria_cidada_2025_A_trechos_quadra.gpkg', pasta_base)
st_write(quadra, out_gpkg, driver = 'GPKG', append = FALSE, delete_layer = TRUE)


# ------------------------------------------------------------------------------
# Quadras - Consolidação das Análises
# ------------------------------------------------------------------------------


# Em quantos casos a mudança da nota de tachão se aplica? # Cerca de 4%
quadra %>% st_drop_geometry() %>% filter(!is.na(sin_tachao)) %>% nrow() # 1933
quadra %>% st_drop_geometry() %>% filter(!is.na(sin_tachao) & sin_tachao < sin_media_floor) %>% nrow() # 85


quadra_eval <- quadra %>% st_drop_geometry()


# Extensão oficial da rede: 735,672 km
quadra_eval %>%
  distinct(id_original, .keep_all = TRUE) %>%
  summarise(EXTENSAO = sum(EXTENSAO, na.rm = TRUE),
            MENOS = sum(MENOS, na.rm = TRUE)) %>%
  mutate(ext_m = EXTENSAO - MENOS)
# EXTENSAO  MENOS  ext_m
# <int>  <int>  <int>
# 1   949396 213724 735672

# Trechos avaliados: 715,302 km
quadra_eval %>%
  filter(!is.na(sin_media_floor_rev)) %>%
  group_by(sin_media_floor_rev) %>%
  summarise(EXTENSAO_atual = sum(EXTENSAO_atual),
            MENOS_atual = sum(MENOS_atual)) %>%
  mutate(ext_m = EXTENSAO_atual - MENOS_atual,
         perc  = ext_m / sum(ext_m) * 100) %>%
  ungroup() %>%
  select(ext_m) %>%
  sum()

# Trechos não avaliados (método proporcional) - Recapeamento 4,871
quadra_eval %>%
  filter(is.na(sin_media_floor_rev)) %>%
  select(sin_media_floor_rev, length_m_atual, em_recapeamento) %>%
  group_by(em_recapeamento) %>%
  summarise(ext_m = sum(length_m_atual, na.rm = TRUE)) %>%
  mutate(perc  = ext_m / sum(ext_m) * 100)
# em_recapeamento  ext_m  perc
# <lgl>            <dbl> <dbl>
# 1 FALSE           21059.  81.2
# 2 TRUE             4871.  18.8

# Trechos não avaliados (método proporcional) - Inexistente: 12,671 km
quadra_eval %>%
  filter(is.na(sin_media_floor_rev)) %>%
  select(sin_media_floor_rev, length_m_atual, trecho_inexistente, em_recapeamento) %>%
  group_by(trecho_inexistente, em_recapeamento) %>%
  summarise(ext_m = sum(length_m_atual, na.rm = TRUE)) %>%
  mutate(perc  = ext_m / sum(ext_m) * 100)
# trecho_inexistente em_recapeamento  ext_m  perc
# <lgl>              <lgl>            <dbl> <dbl>
# 1 FALSE              FALSE            8388. 68.7
# 2 FALSE              TRUE             3825. 31.3
# 3 TRUE               FALSE           12671. 92.4
# 4 TRUE               TRUE             1046.  7.63

# Não avaliada por qualquer motivo (sem acesso, parques etc): 2,765 km
quadra_eval %>%
  filter(str_detect(observacao, 'Não avaliada')) %>%
  select(sin_media_floor_rev, length_m_atual, em_recapeamento, trecho_inexistente) %>%
  group_by(em_recapeamento, trecho_inexistente) %>%
  summarise(ext_m = sum(length_m_atual, na.rm = TRUE)) %>%
  mutate(perc  = ext_m / sum(ext_m) * 100)
# em_recapeamento trecho_inexistente ext_m  perc
# <lgl>           <lgl>              <dbl> <dbl>
# 1 FALSE           FALSE              2765.  88.9
# 2 FALSE           TRUE                344.  11.1
# 3 TRUE            FALSE               509. 100



# Notas pintura - método proporcional
quadra_eval %>%
  filter(!is.na(sin_media_floor_rev)) %>%
  group_by(sin_media_floor_rev) %>%
  summarise(ext_m = sum(length_m_atual)) %>%
  mutate(perc  = ext_m / sum(ext_m) * 100) #%>%
  #ungroup() %>% select(ext_m) %>% sum()
# sin_media_floor_rev   ext_m  perc
# <dbl>   <dbl> <dbl>
# 1                   1  74567.  8.09
# 2                   2  77410.  8.39
# 3                   3 288445. 31.3
# 4                   4 481791. 52.2

# Notas pintura - método CET (715 km)
quadra_eval %>%
  filter(!is.na(sin_media_floor_rev)) %>%
  group_by(sin_media_floor_rev) %>%
  summarise(EXTENSAO_atual = sum(EXTENSAO_atual),
            MENOS_atual = sum(MENOS_atual)) %>%
  mutate(ext_m = EXTENSAO_atual - MENOS_atual,
         perc  = ext_m / sum(ext_m) * 100) #%>%
  # ungroup() %>% select(ext_m) %>% sum()
# sin_media_floor_rev EXTENSAO_atual MENOS_atual   ext_m  perc
# <dbl>          <dbl>       <dbl>   <dbl> <dbl>
# 1                   1         74686.       9188.  65497.  9.16
# 2                   2         77476.       8442.  69034.  9.65
# 3                   3        288756.      69012. 219744. 30.7
# 4                   4        482510.     121482. 361028. 50.5



quadra_eval %>%
  filter(!is.na(sin_media_floor)) %>%
  group_by(sin_media_floor) %>%
  summarise(EXTENSAO_atual = sum(EXTENSAO_atual),
            MENOS_atual = sum(MENOS_atual)) %>%
  mutate(ext_m = EXTENSAO_atual - MENOS_atual,
         perc  = ext_m / sum(ext_m) * 100)
# sin_media_floor EXTENSAO_atual MENOS_atual   ext_m  perc
# <dbl>          <dbl>       <dbl>   <dbl> <dbl>
# 1               1         66821.       7823.  58998.  8.25
# 2               2         79471.       9159.  70312.  9.83
# 3               3        294626.      69661. 224965. 31.5
# 4               4        482510.     121482. 361028. 50.5


quadra_eval %>%
  filter(!is.na(sin_media_floor_rev)) %>%
  group_by(pavimento) %>%
  summarise(EXTENSAO_atual = sum(EXTENSAO_atual),
            MENOS_atual = sum(MENOS_atual)) %>%
  mutate(ext_m = EXTENSAO_atual - MENOS_atual,
         perc  = ext_m / sum(ext_m) * 100)
# pavimento EXTENSAO_atual MENOS_atual   ext_m  perc
# <dbl>          <dbl>       <dbl>   <dbl> <dbl>
# 1         1         22510.       1484.  21026.  2.94
# 2         2         45791.       8986.  36805.  5.15
# 3         3        121067.      21922.  99145. 13.9
# 4         4        723979.     173869. 550110. 76.9
# 5        NA         10080.       1864.   8216.  1.15

# ------------------------------------------------------------------------------
# Interseções
# ------------------------------------------------------------------------------

inter <- sprintf('%s/intersecao.gpkg', pasta_analises)
inter <- read_sf(inter)
names(inter)

inter <- inter %>% select(osm_id,
                          name,
                          semaforo = Semaforo,
                          class_semaforo = Classificacao_Semaforo,
                          sin_horizontal = Sinalizacao_horizontal,
                          sin_aproximacoes = Aproximacoes,
                          pavimento = Pavimento,
                          flag_recapeamento = Recapeamento,
                          flag_inexistente = Inexistente,
                          observacao = Observacao,
                          geom)

inter <- inter %>% mutate(id_linha = 1:nrow(.), .before = 1)
summary(inter)


inter_valid <-
  inter %>%
  mutate(lon = st_coordinates(geom)[, 1],
         lat = st_coordinates(geom)[, 2]) %>%
  mutate(mapillary = str_c('https://www.mapillary.com/app/user?lat=', lat,
                           '&lng=', lon,
                           '&z=19.9&menu=false&panos=true&all_coverage=false&dateFrom=2025-04-09&dateTo=2025-06-30&username%5B%5D=gabinete_falzoni')) %>%
  st_drop_geometry()

nrow(inter_valid)

# Com semáforo
agrupar(inter_valid, expr(class_semaforo))
# class_semaforo     n  prop
# <chr>          <int> <dbl>
# 1 A               1427 22.6
# 2 B                220  3.48
# 3 C                835 13.2
# 4 D                322  5.09
# 5 NA              3516 55.6

# Excluindo vias sem semáforo
inter_valid %>% filter(!is.na(class_semaforo)) %>% agrupar(., expr(class_semaforo))
# class_semaforo     n  prop
# <chr>          <int> <dbl>
# 1 A               1427 50.9
# 2 B                220  7.85
# 3 C                835 29.8
# 4 D                322 11.5



notas_esq <-
  inter_valid %>%
  # select(matches('^sin_')) %>%
  mutate(
    sin_soma = rowSums(select(., matches("sin_")), na.rm = TRUE),
    sin_qtd_itens = rowSums(!is.na(select(., matches("sin_")))),
    sin_media = sin_soma / sin_qtd_itens,
    sin_media_floor = floor(sin_media)
  ) %>%
  # select(id_linha, matches('^sin_'))
  select(id_linha, sin_soma, sin_qtd_itens, sin_media, sin_media_floor)

inter <- inter %>% left_join(notas_esq, by = 'id_linha') %>% relocate(geom, .after = last_col())


# out_gpkg <- sprintf('%s/teste_classificacao_intersecoes.gpkg', pasta_analises)
# st_write(inter, out_gpkg, driver = 'GPKG', append = FALSE, delete_layer = TRUE)

out_gpkg <- sprintf('%s/auditoria_cidada_2025_B_intersecoes.gpkg', pasta_base)
st_write(inter, out_gpkg, driver = 'GPKG', append = FALSE, delete_layer = TRUE)



notas_esq %>% agrupar(expr(sin_media_floor)) %>% mutate(prop = as.character(prop))
# notas_esq %>% filter(is.na(sin_media_floor))
# sin_media_floor     n   prop
# <dbl> <int>  <dbl>
# 1               1   568  8.99
# 2               2   822 13.0
# 3               3  1595 25.2
# 4               4  3318 52.5



inter_valid %>% agrupar(expr(sin_horizontal))
# sinalizacao_horizontal     n  prop
# <int> <int> <dbl>
# 1                      1   465  7.36
# 2                      2   356  5.63
# 3                      3   808 12.8
# 4                      4  3263 51.6
# 5                     NA  1428 22.6

inter_valid %>% filter(!is.na(sin_horizontal)) %>% agrupar(expr(sin_horizontal))
# sinalizacao_horizontal     n  prop
# <int> <int> <dbl>
# 1                      1   465  9.51
# 2                      2   356  7.28
# 3                      3   808 16.5
# 4                      4  3263 66.7

inter_valid %>% agrupar(expr(pavimento))
# pavimento     n   prop
# <int> <int>  <dbl>
# 1         1    25  0.396
# 2         2   250  3.96
# 3         3   563  8.91
# 4         4  5482 86.7


inter_valid %>% agrupar(expr(sin_aproximacoes))
# aproximacoes     n  prop
# <int> <int> <dbl>
# 1            1   710 11.2
# 2            2   604  9.56
# 3            3  1116 17.7
# 4            4  3712 58.7
# 5           NA   178  2.82

inter_valid %>% filter(!is.na(sin_aproximacoes)) %>% agrupar(expr(sin_aproximacoes))
# aproximacoes     n  prop
# <int> <int> <dbl>
# 1            1   710 11.6
# 2            2   604  9.83
# 3            3  1116 18.2
# 4            4  3712 60.4

inter_valid %>% agrupar(expr(flag_recapeamento))
# flag_recapeamento     n   prop
# <lgl>             <int>  <dbl>
# 1 FALSE              6258 99.0
# 2 TRUE                 62  0.981

inter_valid %>% agrupar(expr(flag_inexistente))
# flag_inexistente     n   prop
# <lgl>            <int>  <dbl>
# 1 FALSE             6274 99.3
# 2 TRUE                46  0.728


