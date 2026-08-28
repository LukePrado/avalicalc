# ==============================================================================
# MODELO
# ==============================================================================

library(dplyr)

#importando dados
dados <- read.csv("data/processed/bd-imoveis.csv", sep=";",dec=",", header=TRUE)

#criando o modelo
modelo <<- lm(log(vl_unt) ~ log(banheiros) + vagas_garagem + log(area_privativa) + ec +
                pa + dist_mar + I(1/localizacao), data = dados)

#exibir e testar
summary (modelo)

reais <- function(x) {
  format(round(x, 2), big.mark = ".", decimal.mark = ",", nsmall = 2,
         scientific = FALSE)}

imovel <- data.frame(
  banheiros = 2,
  vagas_garagem = 1,
  area_privativa = 60,
  ec = 2,
  pa = 1,
  dist_mar = 100,
  localizacao = 7062.24
  )

nivel_conf <- 0.8

valor_log <- predict(modelo, newdata = imovel, interval = "confidence",
                     level = nivel_conf)

valor_real <- exp(valor_log)

paste0("O valor estimado do PU é R$ ", reais(valor_real[,"fit"]),"/m2")

paste0("Com nível de confiança de ", nivel_conf * 100,
       "% o valor real estará entre R$",reais(valor_real[,"lwr"])," e R$",
       reais(valor_real[,"upr"]))
