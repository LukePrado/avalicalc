# ==============================================================================
# AvaliCalc - App Shiny
# Estimativa de valor unitario (R$/m2) de apartamentos residenciais
# ==============================================================================

library(shiny)
library(bslib)

# ------------------------------------------------------------------------------
# Modelo e dados de apoio
# ------------------------------------------------------------------------------
modelo <- readRDS("modelo_regressao.rds")

# Bairro -> valor de "localizacao" usado pelo modelo
bairros <- c(
  "Altiplano Cabo Branco" = 5032.20,
  "Bessa"                 = 4732.95,
  "Jardim Oceania"        = 7062.24,
  "Manaira"               = 7620.48,
  "Tambau"                = 7865.29
)

estado_conservacao <- c("Ruim" = 1, "Bom" = 2, "Otimo" = 3)
padrao_acabamento  <- c("Baixo" = 1, "Medio" = 2, "Alto" = 3)

# Formata numero em reais (pt-BR)
reais <- function(x, dec = 0) {
  format(round(x, dec), big.mark = ".", decimal.mark = ",",
         nsmall = dec, scientific = FALSE)
}

NIVEL_CONF <- 0.80

# ------------------------------------------------------------------------------
# Tema
# ------------------------------------------------------------------------------
tema <- bs_theme(
  version = 5,
  primary = "#1b4f72",
  base_font = font_google("Inter", local = FALSE),
  heading_font = font_google("Inter", local = FALSE)
)

# ------------------------------------------------------------------------------
# Aba 1: Calculadora
# ------------------------------------------------------------------------------
aba_calculadora <- layout_columns(
  col_widths = c(5, 7),
  fill = FALSE,

  # ---- Card de entrada ----
  card(
    card_header("Informe as caracteristicas"),
    selectInput("bairro", "Bairro", choices = names(bairros),
                selected = "Manaira"),
    numericInput("area", "Area privativa (m²)", value = 80,
                 min = 10, max = 1000, step = 1),
    selectInput("banheiros", "Banheiros", choices = 1:6, selected = 2),
    selectInput("vagas", "Vagas de garagem", choices = 0:6, selected = 1),
    selectInput("ec", "Estado de conservacao",
                choices = estado_conservacao, selected = 2),
    selectInput("pa", "Padrao de acabamento",
                choices = padrao_acabamento, selected = 2),
    numericInput("dist_mar", "Distancia do mar (m)", value = 150,
                 min = 0, max = 10000, step = 10),
    actionButton("calcular", "Calcular", class = "btn-primary w-100 mt-2")
  ),

  # ---- Card de resultado ----
  card(
    card_header("Resultado da estimativa"),
    div(
      class = "d-flex flex-column align-items-center justify-content-center h-100 text-center p-3",
      div(class = "text-muted", "Valor unitário estimado (R$/m²)"),
      div(class = "display-3 fw-bold text-primary my-2",
          textOutput("valor_fit", inline = TRUE)),
      div(class = "text-muted mt-3",
          sprintf("Intervalo de confianca (%d%%)", round(NIVEL_CONF * 100))),
      div(class = "fs-4 fw-semibold",
          textOutput("valor_ic", inline = TRUE)),
      div(class = "mt-4 pt-3 border-top border-light",
          div(class = "text-muted", "Valor total estimado (R$)"),
          div(class = "display-4 fw-bold text-success my-2",
              textOutput("valor_total", inline = TRUE))
      ),
      div(class = "text-muted small mt-4",
          "Modelo ajustado com base em dados de mercado da area de estudo.")
    )
  )
)

# ------------------------------------------------------------------------------
# Aba 2: Análise Exploratória
# ------------------------------------------------------------------------------
card_grafico <- function(titulo, arquivo) {
  card(
    full_screen = TRUE,
    card_header(titulo),
    card_image(file = NULL, src = file.path("figures", arquivo),
               height = "auto", fill = FALSE,
               class = "img-fluid")
  )
}

aba_graficos <- layout_columns(
  col_widths = c(6, 6),
  card_grafico("Dispersao: valor unitario vs area", "01_dispersao_valor_area.png"),
  card_grafico("Valor unitario por bairro", "02_boxplot_bairro.png"),
  card_grafico("Distribuicao do valor unitario", "03_histograma_distribuicao.png"),
  card_grafico("Matriz de correlacao", "04_correlacao_ggplot.png"),
  card_grafico("Residuos vs ajustados", "05_residuos_ajustados.png"),
  card_grafico("QQ-plot dos residuos", "06_qq_plot.png")
)

# ------------------------------------------------------------------------------
# Aba 3: Modelo de Regressão
# ------------------------------------------------------------------------------
aba_modelo <- layout_columns(
  col_widths = 12,
  fill = FALSE,
  
  card(
    card_header("Modelo final ajustado"),
    
    # Título do modelo
    div(
      class = "text-center text-muted small mb-3",
      "Valor unitário (R$/m²) ~ Área + Quartos + Vagas + Padrão + Distância do mar + Bairro"
    ),
    
    # Tabela de coeficientes (em HTML)
    div(
      style = "overflow-x: auto;",
      tableOutput("tabela_modelo")
    ),
    
    # Rodapé com métricas
    div(
      class = "text-center text-muted small mt-3",
      textOutput("metricas_modelo")
    ),
    
    # Nota sobre significância
    div(
      class = "text-center text-muted small mt-2",
      "*** p<0,001; ** p<0,01; * p<0,05"
    )
  )
)

# ------------------------------------------------------------------------------
# UI
# ------------------------------------------------------------------------------
ui <- page_navbar(
  title = tags$span(
    tags$img(src = "avalicalc3.png", height = "34px",
             class = "me-2 align-middle"),
    "AvaliCalc"
  ),
  theme = tema,
  fillable = FALSE,
  # page_navbar ja colapsa em menu "hamburguer" no mobile
  nav_panel("Calculadora", aba_calculadora),
  nav_panel("Análise Exploratória", aba_graficos),
  nav_panel("Modelo de Regressão", aba_modelo),
  nav_spacer(),
  nav_item(
    tags$span(class = "navbar-text small",
              "Estimativa de valor de apartamentos residenciais")
  )
)

# ------------------------------------------------------------------------------
# Server
# ------------------------------------------------------------------------------
server <- function(input, output, session) {

  estimativa <- eventReactive(input$calcular, {
    req(input$area, input$dist_mar)

    novo <- data.frame(
      banheiros      = as.numeric(input$banheiros),
      vagas_garagem  = as.numeric(input$vagas),
      area_privativa = as.numeric(input$area),
      ec             = as.numeric(input$ec),
      pa             = as.numeric(input$pa),
      dist_mar       = as.numeric(input$dist_mar),
      localizacao    = unname(bairros[[input$bairro]])
    )

    pred_log <- predict(modelo, newdata = novo, interval = "confidence",
                        level = NIVEL_CONF)
    exp(pred_log)  # volta para R$/m2
  }, ignoreNULL = FALSE)

  output$valor_fit <- renderText({
    reais(estimativa()[, "fit"])
  })

  output$valor_ic <- renderText({
    v <- estimativa()
    paste0(reais(v[, "lwr"]), "  –  ", reais(v[, "upr"]))
  })

  output$valor_total <- renderText({
    req(estimativa())
    total <- estimativa()[, "fit"] * input$area
    reais(total)
  })
  
  # ----------------------------------------------------------------------------
  # Tabela do modelo de regressão
  # ----------------------------------------------------------------------------
  
  output$tabela_modelo <- renderTable({
    
    # Extrair coeficientes do modelo
    coef <- summary(modelo)$coefficients
    
    # Criar dataframe com os dados
    dados_tabela <- data.frame(
      Variável = rownames(coef),
      Coeficiente = coef[, 1],
      `Erro Padrão` = coef[, 2],
      `p-valor` = coef[, 4],
      stringsAsFactors = FALSE
    )
    
    # Formatar p-valor com estrelas
    dados_tabela$`p-valor` <- ifelse(
      dados_tabela$`p-valor` < 0.001,
      "<0,001 ***",
      ifelse(
        dados_tabela$`p-valor` < 0.01,
        paste0(round(dados_tabela$`p-valor`, 3), " **"),
        ifelse(
          dados_tabela$`p-valor` < 0.05,
          paste0(round(dados_tabela$`p-valor`, 3), " *"),
          as.character(round(dados_tabela$`p-valor`, 3))
        )
      )
    )
    
    # Formatar números (substituir . por ,)
    dados_tabela$Coeficiente <- format(round(dados_tabela$Coeficiente, 2), 
                                       big.mark = ".", decimal.mark = ",")
    dados_tabela$`Erro Padrão` <- format(round(dados_tabela$`Erro Padrão`, 2), 
                                         big.mark = ".", decimal.mark = ",")
    
    # Substituir NA por espaço
    dados_tabela[is.na(dados_tabela)] <- ""
    
    # Renomear colunas para português
    colnames(dados_tabela) <- c("Variável", "Coeficiente", "Erro Padrão", "p-valor")
    
    dados_tabela
  }, 
  striped = TRUE,
  hover = TRUE,
  bordered = TRUE,
  align = "lrrr",
  width = "100%",
  spacing = "m",
  digits = 2,
  na = "")
  
  output$metricas_modelo <- renderText({
    r2_ajustado <- summary(modelo)$adj.r.squared
    erro_padrao <- summary(modelo)$sigma
    
    paste0(
      "R² ajustado: ", round(r2_ajustado, 3),
      " | Erro padrão do modelo: ", round(erro_padrao, 2)
    )
  })
  
}
shinyApp(ui, server)
