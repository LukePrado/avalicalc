# 🏠 AvaliCalc - Estimativa de Valores de Apartamentos

[![Shiny](https://img.shields.io/badge/Shiny-1.8.0-blue?logo=r)](https://shiny.rstudio.com/)
[![R](https://img.shields.io/badge/R-4.3.0-276DC3?logo=r)](https://www.r-project.org/)

**Ferramenta interativa para estimativa de valor unitário (R$/m²) de apartamentos residenciais em João Pessoa-PB**

---

## 📋 Sobre o Projeto

O **AvaliCalc** é um aplicativo Shiny desenvolvido para estimar o valor de mercado de apartamentos residenciais com base em um modelo de regressão múltipla. A ferramenta integra **inferência estatística** e **recursos computacionais** para fornecer estimativas confiáveis, reproduzíveis e de fácil utilização.

---

## 🎯 Objetivos

- Desenvolver um modelo estatístico para estimar valores de apartamentos
- Utilizar técnicas de inferência estatística para seleção e ajuste do modelo
- Criar uma ferramenta interativa (AvaliCalc) para estimativas pontuais
- Aumentar a agilidade e padronização nas avaliações imobiliárias

---

## 🗺️ Área de Estudo

**Bairros analisados em João Pessoa - PB:**

| Bairro | 
|--------|
| Altiplano Cabo Branco | 
| Bessa | 
| Jardim Oceania | 
| Manaíra | 
| Tambaú |

---

## 📊 Metodologia

### 1. Coleta e Organização dos Dados
Pesquisa de mercado com dados de ofertas e transações imobiliárias, considerando variáveis relevantes para a avaliação.

### 2. Análise Exploratória
Utilização do R:
- Análise gráfica e estatística descritiva
- Estimação de parâmetros
- Seleção de variáveis

### 3. Modelagem
Ajuste de modelo de regressão múltipla para representar o valor unitário (R$/m²) em função das variáveis significativas.

### 4. Ferramenta Computacional
Desenvolvimento do aplicativo AvaliCalc com o pacote **Shiny** do R.

---

## 🚀 Tecnologias Utilizadas

### Linguagens e Pacotes
- **R** (v4.3.0+) - Linguagem principal
- **Shiny** - Framework para aplicações web interativas
- **bslib** - Theming e layout responsivo
- **ggplot2** - Visualização de dados
- **dplyr** - Manipulação de dados
- **corrplot** - Matriz de correlação

### Principais Bibliotecas

```r
library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(corrplot)
```

---

## 📁 Estrutura do Projeto

```
avalicalc/
├── app
│   ├── app.R
│   ├── modelo_regressao.rds
│   ├── rsconnect
│   │   └── shinyapps.io
│   │       └── lucianoprado
│   │           └── avalicalc.dcf
│   └── www
│       ├── avalicalc3.png
│       ├── avalicalc_logo.png
│       └── figures
│           ├── 01_dispersao_valor_area.png
│           ├── 02_boxplot_bairro.png
│           ├── 03_histograma_distribuicao.png
│           ├── 04_correlacao_ggplot.png
│           ├── 05_residuos_ajustados.png
│           └── 06_qq_plot.png
├── data
│   ├── processed
│   │   └── bd-imoveis.csv
│   └── raw
│
├── models
│   ├── modelo_regressao.rds
│   └── resumo_modelo.rds
├── outputs
│   ├── figures
│   │   ├── 01_dispersao_valor_area.png
│   │   ├── 02_boxplot_bairro.png
│   │   ├── 03_histograma_distribuicao.png
│   │   ├── 04_correlacao_ggplot.png
│   │   ├── 04_correlacao.png
│   │   ├── 05_residuos_ajustados.png
│   │   ├── 06_qq_plot.png
│   │   └── avalicalc3.png
│   └── tabela_coeficientes.csv
├── R
│   ├── analise_graficos.R
│   └── treinamento_modelo.R
├── README.md
```

---

## 🎯 Funcionalidades do App

### Aba 1: **Calculadora**
- Entrada de características do imóvel:
- Exibição do valor unitário estimado (R$/m²)
- Intervalo de confiança (80%)
- Valor total estimado

### Aba 2: **Análise Exploratória**
- Dispersão: valor unitário vs área
- Box-plot: valor por bairro
- Distribuição do valor unitário
- Matriz de correlação

### Aba 3: **Modelo de Regressão**
- Tabela de coeficientes com significância
- R² e erro padrão do modelo
- Diagnóstico dos resíduos:
  - Resíduos vs Ajustados
  - QQ-Plot

---

## 🖥️ Como Executar o App

### Pré-requisitos
- R (v4.3.0 ou superior)
- RStudio/Positron (recomendado)

### Instalação e Execução

1. **Clone o repositório:**

```bash
git clone https://github.com/LukePrado/avalicalc.git
cd avalicalc
```

2. **Instale as dependências:**

```r
install.packages(c(
  "shiny",
  "bslib",
  "ggplot2",
  "dplyr",
  "corrplot",
  "knitr",
  "kableExtra",
  "broom",
  "car",
  "MASS"
))
```

3. **Execute o app:**

```r
shiny::runApp("app/app.R")
```

---

## 👥 Autores

**Fábio Vieira Guedes Cabral**  
- Engenheiro Civil - Banco do Nordeste do Brasil
- Graduando em Estatística – UFPB

**Luciano Ribeiro do Prado**  
- Analista de Sistema - PUC MINAS
- Graduando em Estatística – UFPB

---

## 🔗 Links

- **Aplicativo Online:** [AvaliCalc](https://lucianoprado.shinyapps.io/avalicalc/)
- **Repositório:** [GitHub](https://github.com/LukePrado/avalicalc)

---


**Última atualização:** Setembro 2026
