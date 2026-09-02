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
  card_grafico("Matriz de correlacao", "04_correlacao_ggplot.png")
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
      "log(Valor unitário R$/m²) ~ log(Banheiros) + Vagas + log(Área privativa) + Estado de conservação + Padrão de acabamento + Distância do mar + 1/Localização"
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
  ),

  # Card de diagnóstico dos resíduos
  card(
    full_screen = TRUE,
    card_header("Diagnóstico dos resíduos"),
    layout_columns(
      col_widths = c(6, 6),
      card_image(file = NULL, src = "figures/05_residuos_ajustados.png",
                 height = "auto", fill = FALSE, class = "img-fluid"),
      card_image(file = NULL, src = "figures/06_qq_plot.png",
                 height = "auto", fill = FALSE, class = "img-fluid")
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
    tags$a(
      href = "https://github.com/LukePrado/avalicalc",
      target = "_blank", rel = "noopener",
      class = "nav-link d-inline-flex align-items-center",
      HTML(paste0(
        '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" ',
        'viewBox="0 0 16 16" fill="currentColor" class="me-1">',
        '<path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 ',
        '0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 ',
        '1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 ',
        '0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 ',
        '2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 ',
        '1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 ',
        '2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>',
        'Repositório'
      ))
    )
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
    
    # Nomes tecnicos -> nomes humanos (na ordem em que aparecem no modelo)
    nomes_humanos <- c(
      "(Intercept)"         = "(Intercepto)",
      "log(banheiros)"      = "Banheiros (log)",
      "vagas_garagem"       = "Vagas de garagem",
      "log(area_privativa)" = "Área privativa (log)",
      "ec"                  = "Estado de conservação",
      "pa"                  = "Padrão de acabamento",
      "dist_mar"            = "Distância do mar (m)",
      "I(1/localizacao)"    = "Localização (1/valor do bairro)"
    )

    variaveis <- rownames(coef)
    variaveis_legiveis <- ifelse(variaveis %in% names(nomes_humanos),
                                 nomes_humanos[variaveis], variaveis)

    # Criar dataframe com os dados
    dados_tabela <- data.frame(
      Variável = variaveis_legiveis,
      Coeficiente = coef[, 1],
      `Erro Padrão` = coef[, 2],
      `p-valor` = coef[, 4],
      stringsAsFactors = FALSE,
      check.names = FALSE
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
