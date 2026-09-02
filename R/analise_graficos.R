# ============================================
# GERAR GRÁFICOS PARA O APP E POSTER
# ============================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)
library(ggpubr)
library(corrplot)
library(RColorBrewer)

# ============================================
# CARREGAR DADOS E MODELO

dados <- read.csv("data/processed/bd-imoveis.csv", sep=";",dec=",", header=TRUE)
modelo <- readRDS("models/modelo_regressao.rds")

summary(dados)


# ============================================
# Criar pasta se não existir
if(!dir.exists("outputs/figures")) {
  dir.create("outputs/figures", recursive = TRUE)
}

message("Gerando gráficos para o app e poster...")

# Definir tema padrão (estilo profissional)
tema_personalizado <- theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5, color = "#2c3e50"),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "#34495e"),
    axis.title = element_text(size = 12, face = "bold", color = "#2c3e50"),
    axis.text = element_text(size = 10, color = "#34495e"),
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#ecf0f1", size = 0.5),
    panel.border = element_rect(fill = NA, color = "#bdc3c7", size = 0.8),
    plot.margin = margin(15, 15, 15, 15),
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    strip.text = element_text(size = 11, face = "bold")
  )

# ============================================
# GRÁFICO 1: DISPERSÃO - VALOR UNITÁRIO vs ÁREA

grafico_dispersao <- function(dados) {

  # Calcular correlação
  correlacao <- cor(dados$area_privativa, dados$vl_unt, use = "complete.obs")

  p <- ggplot(dados, aes(x = area_privativa, y = vl_unt)) +
    geom_point(alpha = 0.4, color = "#3498db", size = 2.5) +
    geom_smooth(method = "lm", color = "#e74c3c", se = TRUE,
                fill = "#e74c3c", alpha = 0.15, size = 1.2) +
    labs(
      title = "Valor unitário (R$/m²) vs Área privativa (m²)",
      subtitle = paste0("Correlação de Pearson: ", round(correlacao, 3)),
      x = "Área privativa (m²)",
      y = "Valor unitário (R$/m²)"
    ) +
    tema_personalizado +
    scale_x_continuous(labels = scales::comma) +
    scale_y_continuous(labels = scales::comma) +
    geom_text(x = max(dados$area_privativa) * 0.8,
              y = max(dados$vl_unt) * 0.95,
              label = paste0("r = ", round(correlacao, 3)),
              size = 5, color = "#2c3e50", fontface = "bold")

  return(p)
}

p_dispersao <- grafico_dispersao(dados)
ggsave("outputs/figures/01_dispersao_valor_area.png",
       p_dispersao, width = 10, height = 7, dpi = 300)

message("Gráfico: Dispersão Valor vs Área")

# ============================================
# GRÁFICO 2: BOX-PLOT - VALOR UNITÁRIO POR BAIRRO

grafico_boxplot_bairro <- function(dados) {

  # Ordenar bairros pela mediana
  bairros_ordenados <- dados %>%
    group_by(bairro) %>%
    summarise(mediana = median(vl_unt, na.rm = TRUE)) %>%
    arrange(desc(mediana)) %>%
    pull(bairro)

  dados$bairro <- factor(dados$bairro,
                                  levels = bairros_ordenados)

  p <- ggplot(dados, aes(x = bairro, y = vl_unt, fill = bairro)) +
    geom_boxplot(alpha = 0.7, color = "#2c3e50",
                 outlier.color = "#e74c3c", outlier.size = 2,
                 outlier.shape = 21, outlier.fill = "#e74c3c") +
    stat_summary(fun = mean, geom = "point", shape = 18,
                 size = 4, color = "#e67e22", fill = "#e67e22") +
    labs(
      title = "Valor unitário (R$/m²) por bairro",
      subtitle = "Box-plot com média (losango laranja) e mediana (linha central)",
      x = "Bairro",
      y = "Valor unitário (R$/m²)"
    ) +
    tema_personalizado +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
      legend.position = "none"
    ) +
    scale_y_continuous(labels = scales::comma) +
    scale_fill_brewer(palette = "Blues")

  return(p)
}

p_boxplot <- grafico_boxplot_bairro(dados)
ggsave("outputs/figures/02_boxplot_bairro.png",
       p_boxplot, width = 10, height = 7, dpi = 300)

message("Gráfico: Box-plot por Bairro")

# ============================================
# GRÁFICO 3: HISTOGRAMA - DISTRIBUIÇÃO DO VALOR UNITÁRIO

grafico_histograma <- function(dados) {

  # Criar a variável em Log
  dados$log_vl_unt <- log(dados$vl_unt)

  # Calcular estatísticas em log
  media <- mean(dados$log_vl_unt, na.rm = TRUE)
  mediana <- median(dados$log_vl_unt, na.rm = TRUE)

  # Calcular estatísticas em escala original para o subtítulo
  media_original <- mean(dados$vl_unt, na.rm = TRUE)
  mediana_original <- median(dados$vl_unt, na.rm = TRUE)

  p <- ggplot(dados, aes(x = log_vl_unt)) +
    geom_histogram(aes(y = ..density..),
                   bins = 30,
                   fill = "#3498db",
                   color = "#2c3e50",
                   alpha = 0.7) +
    geom_density(color = "#e74c3c", size = 1.2) +
    geom_vline(xintercept = media, color = "#2ecc71", size = 1.2, linetype = "dashed") +
    geom_vline(xintercept = mediana, color = "#e67e22", size = 1.2, linetype = "dashed") +
    labs(
      title = "Distribuição do log do valor unitário",
      subtitle = paste0(
        "Média: ", round(media, 2), " (R$ ", format(round(media_original, 0), big.mark = "."), ")",
        " | Mediana: ", round(mediana, 2), " (R$ ", format(round(mediana_original, 0), big.mark = "."), ")"
      ),
      x = "log(Valor Unitário) - ln(R$/m²)",
      y = "Densidade"
    ) +
    tema_personalizado +
    scale_x_continuous(labels = scales::comma) +
    annotate("text", x = media + 0.5, y = 0.9 * max(density(dados$log_vl_unt)$y),
             label = paste0("Média = ", round(media, 2)),
             color = "#2ecc71", size = 4, fontface = "bold") +
    annotate("text", x = mediana + 0.5, y = 0.8 * max(density(dados$log_vl_unt)$y),
             label = paste0("Mediana = ", round(mediana, 2)),
             color = "#e67e22", size = 4, fontface = "bold")

  return(p)
}

p_histograma <- grafico_histograma(dados)
ggsave("outputs/figures/03_histograma_distribuicao.png",
       p_histograma, width = 10, height = 7, dpi = 300)

message("Gráfico: Histograma do log do valor unitário")

# ============================================
# GRÁFICO 4: MATRIZ DE CORRELAÇÃO

grafico_correlacao <- function(dados) {

  # Selecionar variáveis
  variaveis <- dados %>%
    select(vl_unt, area_privativa, banheiros, vagas_garagem, dist_mar) %>%
    rename(
      "Valor" = vl_unt,
      "Área" = area_privativa,
      "banheiros" = banheiros,
      "Vagas" = vagas_garagem,
      "Dist. mar" = dist_mar
    )

  # Calcular matriz de correlação
  cor_matrix <- cor(variaveis, use = "complete.obs")

  # Salvar como imagem usando corrplot
  png("outputs/figures/04_correlacao.png",
      width = 800, height = 800, res = 150)

  corrplot::corrplot(cor_matrix,
                     method = "color",
                     type = "upper",
                     order = "hclust",
                     addCoef.col = "black",
                     tl.col = "black",
                     tl.srt = 45,
                     diag = FALSE,
                     number.cex = 1.2,
                     tl.cex = 1.2,
                     col = colorRampPalette(c("#e74c3c", "white", "#2ecc71"))(200),
                     title = "Correlação entre variáveis",
                     mar = c(0, 0, 2, 0))

  dev.off()

  # Versão ggplot
  cor_long <- as.data.frame(as.table(cor_matrix)) %>%
    rename(Var1 = 1, Var2 = 2, Correlacao = 3) %>%
    filter(Var1 != Var2)

  p <- ggplot(cor_long, aes(x = Var1, y = Var2, fill = Correlacao)) +
    geom_tile(color = "white") +
    geom_text(aes(label = round(Correlacao, 3)),
              color = "black", size = 4.5, fontface = "bold") +
    scale_fill_gradient2(
      low = "#e74c3c",
      mid = "white",
      high = "#2ecc71",
      midpoint = 0,
      limits = c(-1, 1),
      name = "Correlação"
    ) +
    labs(
      title = "Correlação entre variáveis",
      x = "",
      y = ""
    ) +
    tema_personalizado +
    theme(
      axis.text = element_text(size = 11, face = "bold"),
      panel.grid = element_blank(),
      legend.position = "right"
    )

  ggsave("outputs/figures/04_correlacao_ggplot.png",
         p, width = 10, height = 8, dpi = 300)

  return(p)
}

p_correlacao <- grafico_correlacao(dados)
message("Gráfico: Matriz de Correlação")

# ============================================
# GRÁFICO 5: RESÍDUOS vs AJUSTADOS

grafico_residuos_ajustados <- function(modelo) {

  # Extrair resíduos e valores ajustados
  residuos <- residuals(modelo)
  ajustados <- fitted(modelo)

  # Criar dataframe
  df_residuos <- data.frame(
    Ajustados = ajustados,
    Residuos = residuos,
    Residuos_std = rstandard(modelo)
  )

  # Limites dos eixos
  x_min <- max(8, floor(min(ajustados) * 10) / 10)
  x_max <- ceiling(max(ajustados) * 10) / 10
  y_lim <- max(abs(residuos)) * 1.3

  p <- ggplot(df_residuos, aes(x = Ajustados, y = Residuos)) +
    geom_point(alpha = 0.5, color = "#3498db", size = 2.5) +
    geom_hline(yintercept = 0, color = "#e74c3c", linetype = "dashed", size = 1.2) +
    geom_smooth(method = "loess", color = "#2c3e50", se = TRUE,
                alpha = 0.15, fill = "#3498db", size = 1) +
    labs(
      title = "Resíduos vs Ajustados (modelo em log)",
      subtitle = "Verificação da homocedasticidade e linearidade",
      x = "Valores ajustados (log)",
      y = "Resíduos (log)"
    ) +
    tema_personalizado +
    coord_cartesian(
      xlim = c(x_min, x_max),
      ylim = c(-y_lim, y_lim)
    ) +
    scale_x_continuous(
      breaks = seq(x_min, x_max, by = 0.5),
      labels = scales::number_format(accuracy = 0.1)
    ) +
    scale_y_continuous(
      breaks = seq(-round(y_lim, 2), round(y_lim, 2), by = 0.1),
      labels = scales::number_format(accuracy = 0.1)
    ) +
    annotate("text",
             x = x_min + (x_max - x_min) * 0.7,
             y = y_lim * 0.85,
             label = paste0("Variância dos resíduos: ",
                           round(var(residuos), 4)),
             size = 4, color = "#2c3e50", hjust = 0)

  return(p)
}

p_residuos <- grafico_residuos_ajustados(modelo)
ggsave("outputs/figures/05_residuos_ajustados.png",
       p_residuos, width = 10, height = 7, dpi = 300)

message("Gráfico: Resíduos vs Ajustados")

# ============================================
# GRÁFICO 6: QQ-PLOT

grafico_qq <- function(modelo) {

  # Extrair resíduos padronizados
  residuos_std <- rstandard(modelo)

  # Criar dataframe
  df_qq <- data.frame(
    residuos = residuos_std
  )

  # Calcular Shapiro-Wilk
  shapiro <- shapiro.test(residuos_std)

  p <- ggplot(df_qq, aes(sample = residuos)) +
    stat_qq(color = "#3498db", alpha = 0.6, size = 2.5) +
    stat_qq_line(color = "#e74c3c", size = 1.2, linetype = "dashed") +
    labs(
      title = "QQ-Plot dos Resíduos",
      subtitle = paste0("Teste de Shapiro-Wilk: p-valor = ", round(shapiro$p.value, 4)),
      x = "Quantis teóricos (Normal)",
      y = "Resíduos padronizados"
    ) +
    tema_personalizado +
    annotate("text", x = -2, y = max(residuos_std) * 0.9,
             label = ifelse(shapiro$p.value > 0.05,
                           "Resíduos seguem distribuição normal",
                           "Resíduos não seguem distribuição normal"),
             size = 4, color = ifelse(shapiro$p.value > 0.05, "#2ecc71", "#e74c3c"),
             hjust = 0, fontface = "bold")

  return(p)
}

p_qq <- grafico_qq(modelo)
ggsave("outputs/figures/06_qq_plot.png",
       p_qq, width = 10, height = 7, dpi = 300)

message("Gráfico: QQ-Plot")

