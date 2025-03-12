library('tidyverse')
library('tidylog')


# Estrutura de pastas
pasta_dados <- '../dados'
pasta_tmp   <- sprintf('%s/tmp', pasta_dados)

for (i in list.files(pasta_tmp, pattern = '.jpg$', full.names = TRUE)) {
  # i <- list.files(pasta_tmp, pattern = '.jpg$', full.names = TRUE)[2]
  print(i)

  creation_data <-
    str_sub(file.info(i)$mtime, 1, 19) %>%
    str_replace_all('[-:]', '') %>%
    str_replace(' ', '_')

  out_file <- sprintf('%s/%s.jpg', pasta_tmp, creation_data)
  print(out_file)

  file.rename(i, out_file)
}
