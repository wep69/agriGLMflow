# agriGLMflow 0.1.0 — Guia detalhado para validação local

**Pacote:** `agriGLMflow`  
**Finalidade:** validação científica, estatística, computacional, documental e de empacotamento antes de release/CRAN  
**Plataforma prioritária:** Windows 10/11, com complementação por Linux/macOS em CI  
**Data desta revisão:** 2026-08-16  
**Snapshot de referência:** `agriGLMflow_0.1.0-state-of-art-update.zip`

---

## 1. Objetivo deste documento

Este guia descreve, passo a passo, como validar localmente o pacote `agriGLMflow` antes de classificá-lo como pronto para uso científico, distribuição institucional, publicação no GitHub, submissão ao CRAN ou utilização dos resultados em um artigo científico.

A validação deve demonstrar simultaneamente que:

1. o pacote possui estrutura válida de pacote R;
2. todo código R é sintaticamente válido;
3. a documentação corresponde à API pública;
4. os delineamentos experimentais são representados corretamente;
5. os motores estatísticos são selecionados sem modificar silenciosamente a estrutura experimental;
6. as famílias probabilísticas são compatíveis com o suporte da variável resposta;
7. `VGAM` somente é usado em situações compatíveis com efeitos fixos;
8. `GLMMadaptive` somente é usado quando sua estrutura de agrupamento é compatível;
9. `glmmTMB`, `gamlss`, `VGAM`, `ordinal`, `betareg`, `brglm2`, `lme4` e demais engines reproduzem, quando aplicável, os resultados obtidos por chamadas diretas aos respectivos backends;
10. comparações múltiplas, contrastes, tendências e predições são calculados na escala correta;
11. os diagnósticos identificam problemas simulados de especificação;
12. os procedimentos de reamostragem respeitam a unidade experimental;
13. as regressões quantitativas retornam parâmetros e quantidades derivadas coerentes;
14. gráficos são gerados sem erros e apresentam estimativas e incerteza adequadamente;
15. todas as vinhetas podem ser renderizadas;
16. exemplos dos manuais são executáveis;
17. a vinheta de estado da arte possui referências resolvidas e metadados auditáveis;
18. a bateria de simulações A–L é reproduzível;
19. o pacote pode ser construído com `R CMD build`;
20. `R CMD check --as-cran` termina sem `ERROR` e, idealmente, sem `WARNING` ou `NOTE` não justificados.

> **Regra de liberação:** uma checagem estática aprovada não substitui `R CMD check`, execução de `testthat`, renderização de vinhetas ou validação numérica dos backends.

---

# PARTE I — PREPARAÇÃO DO AMBIENTE

## 2. Requisitos mínimos

### 2.1. R

O pacote declara:

```text
Depends: R (>= 4.1.0)
```

Para a validação de release, recomenda-se utilizar **R release atual** e, posteriormente, testar também `R-oldrelease` e `R-devel` via CI.

Na data deste guia, o manual oficial *Writing R Extensions* disponibilizado pelo R Core corresponde a **R 4.6.1 (2026-06-24)**. Use preferencialmente a versão release vigente no momento efetivo da validação.

Verificação:

```r
R.version.string
R.version
sessionInfo()
```

Registre a saída integral no relatório de validação.

### 2.2. Rtools no Windows

Pacotes como `glmmTMB`, `VGAM` e algumas dependências podem exigir toolchain ao serem instalados a partir do código-fonte.

A página oficial do CRAN atualmente indica **Rtools 4.5 para R >= 4.5.0, incluindo R-devel**. Antes da validação, confirme novamente a correspondência entre a sua versão do R e o Rtools recomendado pelo CRAN.

Após instalar o Rtools, reinicie o R/RStudio e teste:

```r
Sys.which("make")
Sys.which("gcc")
Sys.which("g++")
Sys.which("tar")
```

Com `pkgbuild`:

```r
install.packages("pkgbuild")
pkgbuild::has_build_tools(debug = TRUE)
```

Resultado desejado:

```text
TRUE
```

### 2.3. RStudio

RStudio não é obrigatório, mas facilita a execução do fluxo. Se usado, confirme em:

```text
Tools > Global Options > General > R version
```

que o RStudio está apontando para a mesma versão do R usada no terminal.

### 2.4. Quarto e ferramentas de documento

Para as vinhetas e relatórios que dependam de Quarto:

```powershell
quarto --version
quarto check
```

No R:

```r
Sys.which("quarto")
```

Para PDF baseado em LaTeX, se necessário, instale TinyTeX:

```r
install.packages("tinytex")
tinytex::install_tinytex()
```

Não é necessário instalar TinyTeX se a validação pretendida usar somente HTML e DOCX.

---

## 3. Diretório de trabalho recomendado no Windows

Evite validar diretamente dentro de pastas sincronizadas, OneDrive, caminhos muito longos ou diretórios com permissões especiais.

Recomendação:

```text
D:\R-packages\agriGLMflow-validation\
```

Estrutura:

```text
D:\R-packages\agriGLMflow-validation\
├── source\
│   └── agriGLMflow\
├── check\
├── library\
├── logs\
├── simulation-results\
└── artifacts\
```

PowerShell:

```powershell
New-Item -ItemType Directory -Force D:\R-packages\agriGLMflow-validation\source
New-Item -ItemType Directory -Force D:\R-packages\agriGLMflow-validation\check
New-Item -ItemType Directory -Force D:\R-packages\agriGLMflow-validation\library
New-Item -ItemType Directory -Force D:\R-packages\agriGLMflow-validation\logs
New-Item -ItemType Directory -Force D:\R-packages\agriGLMflow-validation\simulation-results
New-Item -ItemType Directory -Force D:\R-packages\agriGLMflow-validation\artifacts
```

---

## 4. Extrair o snapshot

Não valide o ZIP diretamente.

Exemplo PowerShell:

```powershell
$Zip = "D:\temp\agriGLMflow_0.1.0-state-of-art-update.zip"
$Dest = "D:\R-packages\agriGLMflow-validation\source"
Expand-Archive -Path $Zip -DestinationPath $Dest -Force
```

Confirme:

```powershell
Test-Path "D:\R-packages\agriGLMflow-validation\source\agriGLMflow\DESCRIPTION"
Test-Path "D:\R-packages\agriGLMflow-validation\source\agriGLMflow\NAMESPACE"
```

Ambos devem retornar:

```text
True
```

---

# PARTE II — LIMPEZA E BLOQUEADORES ANTES DOS TESTES

## 5. Corrigir `DESCRIPTION` antes do primeiro `R CMD check`

O snapshot atual possui um endereço de mantenedor propositalmente inválido:

```text
REPLACE_WITH_MAINTAINER_EMAIL@example.invalid
```

Isso é um bloqueador de release.

Para este projeto, atualize `Authors@R` para os autores definidos para os pacotes científicos:

```r
Authors@R: c(
    person(
      given = c("Walter", "Esfrain"),
      family = "Pereira",
      email = "walterufpb@yahoo.com.br",
      role = c("aut", "cre", "cph"),
      comment = c(ORCID = "0000-0003-1085-0191")
    ),
    person(
      given = c("Magali", "Haidee"),
      family = "Pereira Martinez",
      role = "aut",
      comment = c(ORCID = "0009-0009-5419-959X")
    )
  )
```

Confirme o parsing:

```r
desc <- read.dcf("DESCRIPTION")
desc[, c("Package", "Version", "Authors@R")]
```

Se usar `desc`:

```r
install.packages("desc")
desc::desc(".")
```

### 5.1. Verificar campos principais

```r
x <- read.dcf("DESCRIPTION")
stopifnot(x[1, "Package"] == "agriGLMflow")
stopifnot(x[1, "Version"] == "0.1.0")
stopifnot(!grepl("REPLACE_WITH", x[1, "Authors@R"]))
```

---

## 6. Remover artefatos que não devem estar dentro do source tree

O snapshot de referência contém itens de desenvolvimento que devem ser revistos antes do build, particularmente:

```text
man/regression.Rd.tmp
agriGLMflow_0.1.0-source-snapshot.tar.gz
```

O arquivo `.Rd.tmp` deve ser removido se não tiver finalidade real.

PowerShell:

```powershell
Remove-Item "D:\R-packages\agriGLMflow-validation\source\agriGLMflow\man\regression.Rd.tmp" -ErrorAction SilentlyContinue
Remove-Item "D:\R-packages\agriGLMflow-validation\source\agriGLMflow\agriGLMflow_0.1.0-source-snapshot.tar.gz" -ErrorAction SilentlyContinue
```

Faça também uma busca por arquivos provisórios:

```powershell
Get-ChildItem -Recurse | Where-Object {
  $_.Name -match '\.(tmp|bak|old|orig|rej)$' -or
  $_.Name -match '^~' -or
  $_.Name -match '\.DS_Store$'
}
```

No R:

```r
junk <- list.files(
  ".",
  recursive = TRUE,
  full.names = TRUE,
  pattern = "(\\.tmp$|\\.bak$|\\.old$|\\.orig$|\\.rej$|~$|\\.DS_Store$)"
)
junk
```

Critério de aprovação:

```text
Nenhum arquivo provisório não intencional.
```

---

## 7. Conferir encoding

O `DESCRIPTION` declara:

```text
Encoding: UTF-8
```

Em R:

```r
files <- list.files(
  c("R", "man", "vignettes"),
  recursive = TRUE,
  full.names = TRUE
)

bad <- lapply(files, function(f) {
  z <- try(readLines(f, warn = FALSE, encoding = "UTF-8"), silent = TRUE)
  if (inherits(z, "try-error")) f else NULL
})
Filter(Negate(is.null), bad)
```

Resultado esperado:

```text
list()
```

---

# PARTE III — INSTALAÇÃO DAS DEPENDÊNCIAS

## 8. Criar uma biblioteca R isolada

É recomendável testar sem depender dos pacotes já presentes em sua biblioteca pessoal.

No PowerShell:

```powershell
$env:R_LIBS_USER="D:\R-packages\agriGLMflow-validation\library"
R
```

No R:

```r
.libPaths()
```

O primeiro caminho deve ser a biblioteca de validação.

Também é possível, dentro do R:

```r
validation_lib <- "D:/R-packages/agriGLMflow-validation/library"
dir.create(validation_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(validation_lib, .libPaths()))
.libPaths()
```

---

## 9. Instalar ferramentas de desenvolvimento

```r
install.packages(c(
  "devtools",
  "remotes",
  "pak",
  "pkgbuild",
  "rcmdcheck",
  "roxygen2",
  "testthat",
  "covr",
  "pkgdown",
  "knitr",
  "rmarkdown",
  "vdiffr",
  "withr",
  "desc"
))
```

Verifique:

```r
pkgs_dev <- c(
  "devtools", "pkgbuild", "rcmdcheck", "roxygen2",
  "testthat", "covr", "pkgdown", "knitr", "rmarkdown",
  "vdiffr", "withr", "desc"
)

sapply(pkgs_dev, requireNamespace, quietly = TRUE)
```

Todos devem retornar `TRUE`.

---

## 10. Instalar dependências científicas principais

### 10.1. Backends de ajuste

```r
install.packages(c(
  "rlang",
  "ggplot2",
  "glmmTMB",
  "lme4",
  "GLMMadaptive",
  "gamlss",
  "gamlss.dist",
  "gamlss.inf",
  "VGAM",
  "ordinal",
  "betareg",
  "brglm2",
  "mgcv",
  "MASS"
))
```

### 10.2. Inferência e diagnóstico

```r
install.packages(c(
  "emmeans",
  "DHARMa",
  "performance",
  "marginaleffects",
  "ggeffects",
  "broom",
  "broom.mixed",
  "parameters",
  "modelsummary",
  "multcomp",
  "multcompView"
))
```

### 10.3. Regressão e extensões

```r
install.packages(c(
  "minpack.lm",
  "segmented",
  "drc",
  "spaMM",
  "agridat",
  "patchwork",
  "ggdist"
))
```

Se algum pacote não estiver disponível como binário para a versão atual do R, registre o fato e tente a instalação a partir de fonte somente após confirmar o toolchain.

---

## 11. Auditoria de dependências declaradas

No diretório do pacote:

```r
setwd("D:/R-packages/agriGLMflow-validation/source/agriGLMflow")

d <- desc::desc_get_deps()
d
```

Verifique quais dependências estão ausentes:

```r
deps <- unique(d$package)
deps <- setdiff(deps, "R")

installed <- rownames(installed.packages())
setdiff(deps, installed)
```

Resultado desejado para validação completa:

```text
character(0)
```

Para verificar apenas `Imports`:

```r
imports <- d$package[d$type == "Imports"]
setdiff(imports, rownames(installed.packages()))
```

Esses pacotes são obrigatórios.

---

# PARTE IV — CHECAGEM ESTÁTICA E SINTÁTICA

## 12. Executar o checker estático incluído no pacote

No PowerShell, com Python disponível:

```powershell
cd D:\R-packages\agriGLMflow-validation\source\agriGLMflow
python tools\static_check.py
```

ou:

```powershell
py tools\static_check.py
```

Critério:

```text
PASS
```

Não prossiga para release se houver erro estrutural.

---

## 13. Parsing de todos os arquivos R com o próprio R

A validação estática em Python não substitui o parser do R.

Execute:

```r
r_files <- list.files("R", pattern = "\\.[Rr]$", full.names = TRUE)

parse_results <- lapply(r_files, function(f) {
  message("Parsing: ", f)
  tryCatch(
    {
      parse(file = f, keep.source = TRUE)
      list(file = f, ok = TRUE, error = NA_character_)
    },
    error = function(e) {
      list(file = f, ok = FALSE, error = conditionMessage(e))
    }
  )
})

bad <- Filter(function(x) !x$ok, parse_results)
bad
stopifnot(length(bad) == 0L)
```

Critério:

```text
0 erros de parsing.
```

---

## 14. Carregamento com `devtools::load_all()`

```r
devtools::load_all(".", reset = TRUE, export_all = FALSE)
```

Repetir em sessão limpa.

RStudio:

```text
Session > Restart R
```

Em seguida:

```r
devtools::load_all(".")
```

Não devem surgir erros ou warnings estruturais.

---

# PARTE V — DOCUMENTAÇÃO E API

## 15. Regenerar documentação com roxygen2

```r
devtools::document(".")
```

Em seguida:

```r
git_like_changes <- list.files("man", full.names = TRUE)
length(git_like_changes)
```

Se estiver usando Git:

```powershell
git status --short
```

Qualquer alteração inesperada em `NAMESPACE` ou `.Rd` deve ser revisada.

---

## 16. Conferir exports contra documentação

```r
ns <- readLines("NAMESPACE")
exports <- sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", ns, value = TRUE))
exports <- sort(unique(exports))

length(exports)
exports
```

A versão atual deve apresentar aproximadamente **66 funções exportadas**.

Depois:

```r
aliases <- unlist(lapply(list.files("man", pattern = "\\.Rd$", full.names = TRUE), function(f) {
  x <- readLines(f, warn = FALSE)
  sub("^\\\\alias\\{(.*)\\}$", "\\1", grep("^\\\\alias\\{", x, value = TRUE))
}))

missing_docs <- setdiff(exports, aliases)
missing_docs
stopifnot(length(missing_docs) == 0L)
```

---

## 17. Verificar os três exemplos por função analítica

Para cada função pública de análise, conferir no manual e/ou nas vinhetas:

1. exemplo mínimo;
2. exemplo agronômico pedagógico;
3. exemplo avançado ou discrepante que demonstre limitações/diagnóstico.

Lista prioritária:

```text
agri_design()
agri_response()
agri_family_scan()
agri_model()
agri_glm()
agri_glmm()
agri_gamlss()
agri_vglm()
agri_multinomial()
agri_composition()
agri_ordinal()
agri_regression()
agri_compare_models()
agri_diagnose()
agri_means()
agri_contrasts()
agri_trends()
agri_predict()
agri_cv()
agri_bootstrap()
agri_simulate()
agri_power()
agri_plot()
agri_report()
agri_workflow()
```

Não basta que os exemplos estejam presentes: eles devem ser executáveis com os pacotes sugeridos instalados.

---

## 18. Executar os exemplos dos manuais

A forma mais importante será via `R CMD check`, que executa exemplos automaticamente.

Opcionalmente, durante desenvolvimento:

```r
devtools::check_man(".")
```

ou simplesmente avance para `devtools::check()` e `R CMD check`.

Qualquer exemplo que precise de `\donttest{}` deve ter justificativa de tempo ou dependência, não ser usado para ocultar um erro.

---

# PARTE VI — TESTES UNITÁRIOS E DE INTEGRAÇÃO

## 19. Executar toda a suíte `testthat`

```r
devtools::test(".", reporter = "summary")
```

Alternativa:

```r
testthat::test_dir("tests/testthat", package = "agriGLMflow")
```

Resultado necessário:

```text
0 failures
0 errors
```

Warnings devem ser revisados individualmente.

---

## 20. Testes prioritários existentes

O snapshot inclui arquivos como:

```text
test-base-glm.R
test-designs.R
test-multienvironment.R
test-response-family.R
test-family-scan.R
test-glmmtmb.R
test-gamlss.R
test-gamlss-parameters.R
test-vgam.R
test-vgam-guard.R
test-mixed-backends.R
test-multivariate-response.R
test-regression.R
test-curve-comparison.R
test-dunnett-contract.R
test-cv-metrics.R
test-cluster-diagnostic.R
test-workflow-contract.R
```

Para executar um arquivo isoladamente:

```r
devtools::load_all(".")
testthat::test_file("tests/testthat/test-vgam.R")
```

---

## 21. Ordem sugerida para depuração dos testes

Se a suíte completa falhar, execute nesta ordem:

### Grupo 1 — estruturas básicas

```r
testthat::test_file("tests/testthat/test-designs.R")
testthat::test_file("tests/testthat/test-multienvironment.R")
testthat::test_file("tests/testthat/test-response-family.R")
```

### Grupo 2 — ajuste

```r
testthat::test_file("tests/testthat/test-base-glm.R")
testthat::test_file("tests/testthat/test-glmmtmb.R")
testthat::test_file("tests/testthat/test-mixed-backends.R")
```

### Grupo 3 — GAMLSS/VGAM

```r
testthat::test_file("tests/testthat/test-gamlss.R")
testthat::test_file("tests/testthat/test-gamlss-parameters.R")
testthat::test_file("tests/testthat/test-vgam.R")
testthat::test_file("tests/testthat/test-vgam-guard.R")
testthat::test_file("tests/testthat/test-multivariate-response.R")
```

### Grupo 4 — inferência/regressão

```r
testthat::test_file("tests/testthat/test-regression.R")
testthat::test_file("tests/testthat/test-curve-comparison.R")
testthat::test_file("tests/testthat/test-dunnett-contract.R")
```

### Grupo 5 — workflow/validação

```r
testthat::test_file("tests/testthat/test-family-scan.R")
testthat::test_file("tests/testthat/test-cv-metrics.R")
testthat::test_file("tests/testthat/test-cluster-diagnostic.R")
testthat::test_file("tests/testthat/test-workflow-contract.R")
```

---

# PARTE VII — VALIDAÇÃO DOS DELINEAMENTOS

## 22. Princípio

O objetivo desta seção é verificar que a estrutura experimental declarada determina corretamente a fórmula, os efeitos aleatórios e a unidade experimental.

Nunca considere um teste aprovado somente porque o modelo convergiu.

---

## 23. CRD/DIC

```r
data(agri_biomass, package = "agriGLMflow")
```

Crie um exemplo simples e verifique:

- ausência de bloco aleatório;
- tratamento representado corretamente;
- predição na escala esperada;
- equivalência com `stats::glm()` quando a família for convencional.

Exemplo de golden test:

```r
m_direct <- glm(y ~ treatment, family = gaussian(), data = dat)
m_agri <- agri_glm(y ~ treatment, family = gaussian(), data = dat)

all.equal(
  unname(coef(m_direct)),
  unname(coef(m_agri$engine_fit)),
  tolerance = 1e-8
)
```

---

## 24. RCBD/DBC

Validar:

```text
treatment = fixo
block = aleatório por padrão
```

Golden test sugerido:

```r
m_direct <- lme4::lmer(y ~ treatment + (1 | block), data = dat)

m_agri <- agri_glmm(
  y ~ treatment,
  design = agri_design(
    data = dat,
    design = "rcbd",
    treatment = treatment,
    block = block
  ),
  family = "gaussian",
  engine = "lme4"
)
```

Comparar:

- efeitos fixos;
- variância de bloco;
- logLik quando comparável;
- predições condicionais.

---

## 25. Split-plot

Usar `agri_splitplot`.

Validar explicitamente:

- identificação de `whole_plot_id`;
- erro de parcela principal;
- subparcela dentro de parcela principal;
- interação entre fatores;
- impossibilidade de simplificação para fatorial DBC comum.

Criar dois ajustes:

1. modelo correto;
2. modelo deliberadamente incorreto, sem estrato de parcela principal.

O pacote deve impedir ou sinalizar o segundo quando o delineamento for declarado como split-plot.

---

## 26. Split-split plot

Usar `agri_split_split`.

Confirmar três níveis de unidade experimental.

Verificar:

```text
block
whole_plot_id
subplot_id
subsubplot level
```

Critério principal:

> Os três níveis não podem ser reduzidos a uma única estrutura aleatória sem aviso.

---

## 27. Strip-plot

Usar `agri_stripplot`.

Confirmar que as duas faixas possuem estratos próprios e que a interação não é analisada como se o delineamento fosse apenas um fatorial em blocos.

---

## 28. Medidas repetidas

Usar `agri_repeated`.

Testar, quando disponíveis:

```text
independence
AR(1)
compound symmetry
Toeplitz
unstructured
```

Para AR(1), verificar:

- ordenação correta de `time`;
- identificação de sujeito/parcela;
- ausência de duplicatas por `subject × time`;
- parâmetro de correlação dentro do intervalo válido.

Testar que embaralhar as observações não altera a identificação temporal se `time` estiver corretamente declarado.

---

## 29. Multiambiente

Usar `agri_multienv`.

### Teste obrigatório

```r
expect_error(
  agri_design(
    data = agri_multienv,
    design = "multi_environment",
    treatment = genotype
  )
)
```

O objeto deve exigir `environment`.

Também validar:

- blocos aninhados em ambiente quando aplicável;
- `genotype × environment`;
- ambientes fixos versus aleatórios quando solicitado;
- ausência de mistura silenciosa entre efeitos de bloco e ambiente.

---

# PARTE VIII — VALIDAÇÃO DAS FAMÍLIAS E DO ROUTER

## 30. Registry de famílias

Execute:

```r
fam <- agri_families()
dim(fam)
names(fam)
head(fam)
```

A implementação atual possui aproximadamente **81 entradas de capacidade/família**.

Verifique duplicatas:

```r
anyDuplicated(fam$id)
```

ou adapte ao nome real da coluna identificadora.

Resultado esperado:

```text
0
```

---

## 31. Validação por suporte matemático

Crie respostas representativas:

```r
count_y <- c(0, 1, 3, 5, 10)
binary_y <- c(0, 1, 0, 1)
prop_open <- c(.1, .2, .7, .9)
prop_closed <- c(0, .1, .8, 1)
pos_cont <- c(.1, .3, 2.5, 10)
```

Verifique que `agri_family_candidates()`:

- não sugere Gamma para contagens contendo zero;
- não sugere beta convencional quando há 0/1 exatos;
- considera beta-binomial para sucessos/tentativas;
- considera ordered/extended beta para proporção fechada quando apropriado;
- inclui famílias de contagem para inteiros não negativos;
- não classifica zeros extras como prova automática de zero inflation.

---

## 32. `family = "auto"`

Validar que `family = "auto"`:

1. gera candidatos;
2. ajusta modelos admissíveis;
3. aplica gates de convergência;
4. aplica diagnóstico;
5. só depois ordena sobreviventes;
6. não escolhe simplesmente o primeiro item do registry;
7. não declara menor AIC como único critério.

Guarde o audit trail:

```r
fit <- agri_model(..., family = "auto")
agri_audit(fit)
```

O audit deve permitir reconstruir a decisão.

---

## 33. Contagens

Use `agri_insects`.

Testar, conforme disponibilidade:

```text
Poisson
NB1
NB2
COM-Poisson
generalized Poisson
ZIP
ZINB
hurdle Poisson
hurdle NB
```

Comparar com chamadas diretas do `glmmTMB` nas parametrizações equivalentes.

### Atenção

Não compare coeficientes de parâmetros de dispersão entre backends antes de confirmar que a parametrização é matematicamente equivalente.

---

## 34. Binomial e beta-binomial

Use `agri_disease` e `agri_germination`.

Verificar:

- sucesso e número de tentativas;
- overdispersion;
- beta-binomial;
- escala de probabilidade em `predict(type = "response")`;
- odds/risk quando solicitado.

---

## 35. Proporções contínuas

Use `agri_cover`.

Testar:

```text
beta
extended-support beta
ordered beta
simplex
```

Confirmar:

- beta comum só para `(0,1)`;
- famílias apropriadas quando existirem zeros e uns exatos;
- predições dentro do suporte.

---

## 36. Respostas positivas contínuas

Use `agri_biomass`.

Testar:

```text
Gamma
inverse Gaussian
lognormal
Tweedie quando aplicável
```

Verificar:

- predições positivas;
- diagnóstico de assimetria;
- sensibilidade à família.

---

# PARTE IX — GAMLSS

## 37. Testes básicos GAMLSS

Use `agri_distreg`.

Ajuste ao menos:

```r
fit_mu <- agri_gamlss(
  y ~ treatment,
  family = "NO",
  data = agri_distreg
)
```

Depois um modelo com dispersão:

```r
fit_mu_sigma <- agri_gamlss(
  y ~ treatment,
  sigma = ~ treatment,
  family = "NO",
  data = agri_distreg
)
```

Confirmar que `sigma` efetivamente entra no modelo.

---

## 38. Parâmetros `mu`, `sigma`, `nu`, `tau`

Para famílias que possuam parâmetros adicionais, validar separadamente:

```text
mu formula
sigma formula
nu formula
tau formula
```

Compare o objeto produzido pelo wrapper com ajuste direto por `gamlss::gamlss()`.

---

## 39. Famílias GAMLSS Tier 1, Tier 2 e Expert

Verificar que:

- famílias Tier 1 podem entrar na seleção automática quando validadas;
- Tier 2 seguem as regras definidas;
- Expert pode ser chamado explicitamente;
- Expert não é promovido automaticamente para recomendação primária sem validação correspondente.

---

## 40. Diagnóstico GAMLSS

Validar:

- randomized quantile residuals;
- QQ plot;
- worm plot;
- fitted distribution;
- parâmetros de localização/escala;
- curvas de centis quando aplicáveis.

Nenhum diagnóstico deve gerar erro silencioso.

---

# PARTE X — VGAM

## 41. Princípio de validação do VGAM

`VGAM` amplia o pacote para modelos vetoriais, multinomiais, ordinais, composicionais e outras famílias especializadas, porém sua integração no `agriGLMflow` deve respeitar a restrição de **efeitos fixos** estabelecida para o backend utilizado.

---

## 42. Hard stop para efeitos aleatórios

Teste obrigatório:

```r
# Exemplo conceitual
expect_error(
  agri_vglm(
    y ~ treatment,
    design = design_with_random_block,
    family = "multinomial"
  )
)
```

ou equivalente conforme API final.

Mensagem desejada:

```text
VGAM backend rejected because the declared design requires random effects.
```

A mensagem pode variar, mas a decisão não pode ser silenciosa.

---

## 43. Multinomial

Use `agri_multiclass`.

Validar:

- probabilidades por categoria;
- soma das probabilidades aproximadamente igual a 1;
- categoria de referência;
- predições para novos dados;
- log-loss em validação cruzada.

Teste:

```r
p <- agri_predict(fit)
# adaptar ao formato real retornado
```

Verificar numericamente:

```r
rowSums(prob_matrix)
```

Devem ser aproximadamente 1.

---

## 44. Modelos ordinais VGAM

Use `agri_ordstage`.

Testar:

```text
cumulative
partial proportional odds
non-proportional odds
adjacent-category
continuation-ratio
stopping-ratio
```

Verificar:

- thresholds;
- probabilidades por categoria;
- restrição `parallel`;
- `agri_check_parallel()`;
- interpretação por probabilidades, não por médias artificiais das categorias.

---

## 45. Dirichlet

Use `agri_composition`.

Verificar:

```r
rowSums(agri_composition[, c("root", "stem", "leaf")])
```

ou nomes efetivos das colunas.

Devem ser aproximadamente 1.

Após ajuste:

- predições positivas;
- soma das composições prevista igual a 1 dentro da tolerância;
- nomes das componentes preservados após uso de `cbind()`.

---

## 46. Dirichlet-multinomial

Use `agri_multicounts`.

Verificar:

- matriz de contagens preservada;
- overdispersion em relação ao multinomial simples;
- predição em termos apropriados;
- cross-entropy/log-loss, quando implementados.

---

## 47. Simplex e contagens especializadas VGAM

Testar ao menos um caso de:

```text
simplex
positive Poisson
zero-altered Poisson
zero-altered NB
ZINB
```

Registrar qualquer warning numérico do backend.

Não aceitar um ajuste como válido apenas porque um objeto foi retornado.

---

# PARTE XI — `GLMMadaptive`, `lme4` E `glmmTMB`

## 48. `GLMMadaptive`

A integração foi planejada apenas para estruturas compatíveis com um único fator de agrupamento.

Testar:

### Deve funcionar

```text
RCBD simples com apenas um grouping factor
```

### Deve bloquear/evitar

```text
split-plot com múltiplos grouping factors
multiambiente hierárquico com múltiplos grouping factors
```

Verificar o audit do router.

---

## 49. `lme4`

Use como backend de referência para modelos mistos convencionais.

Golden tests:

```r
fixef_direct <- lme4::fixef(m_direct)
fixef_agri <- lme4::fixef(m_agri$engine_fit)
all.equal(fixef_direct, fixef_agri, tolerance = 1e-6)
```

Também comparar:

```r
lme4::VarCorr()
logLik()
predict()
```

---

## 50. `glmmTMB`

É o backend principal para GLMMs flexíveis.

Validar:

- efeitos aleatórios;
- `ziformula`;
- `dispformula`;
- NB1/NB2;
- COM-Poisson;
- generalized Poisson;
- beta-binomial;
- ordered beta;
- Tweedie;
- estruturas de covariância usadas pelo pacote.

Golden test deve manter exatamente a mesma fórmula e dados.

---

# PARTE XII — INFERÊNCIA PÓS-MODELO

## 51. `agri_anova()`

Verificar:

- tipo de teste utilizado;
- graus de liberdade quando definidos;
- compatibilidade com o backend;
- não apresentar ANOVA gaussiana convencional como se fosse universal para todos os modelos.

---

## 52. `agri_means()`

Para classes suportadas pelo `emmeans`, comparar diretamente:

```r
emm_direct <- emmeans::emmeans(engine_fit, ~ treatment, type = "response")
emm_agri <- agri_means(fit, specs = ~ treatment, scale = "response")
```

Comparar estimativas e ICs dentro de tolerância.

---

## 53. Tukey

```r
agri_contrasts(fit, adjust = "tukey")
```

Comparar com:

```r
pairs(emmeans::emmeans(engine_fit, ~ treatment), adjust = "tukey")
```

---

## 54. Dunnett

Teste prioritário porque o contrato foi explicitamente corrigido.

Para controle `Control`:

```r
agri_contrasts(
  fit,
  method = "dunnett",
  control = "Control"
)
```

Compare com a família de contrastes tratamento versus controle do `emmeans`.

Verificar que Dunnett não é tratado como Tukey.

---

## 55. Holm, Sidak, Bonferroni e FDR

Executar um conjunto idêntico de contrastes e verificar somente a mudança no ajuste da multiplicidade.

---

## 56. Interações

Crie modelo:

```r
y ~ treatment * environment
```

Se a interação for importante, verificar que o workflow não apresenta automaticamente um único ranking de efeitos principais ignorando a interação.

Testar:

```r
agri_simple_effects()
agri_interaction_contrast()
```

---

## 57. Tendências

Para dose quantitativa:

```r
agri_trends(fit, variable = dose)
```

Compare com `emmeans::emtrends()` onde suportado.

---

## 58. Escala link versus response

Para Poisson/NB/binomial, execute as duas escalas.

Verifique que:

```text
scale = "link"
```

não é apresentado como se fosse a escala agronômica original.

Exemplos:

- log count vs expected count;
- log odds vs probability;
- log rate vs rate ratio.

---

# PARTE XIII — REGRESSÃO QUANTITATIVA

## 59. Regra central

Variáveis como dose, tempo, número de plantas ou taxa permanecem quantitativas por padrão.

Teste que:

```text
dose = c(0, 50, 100, 150, 200)
```

não seja convertida silenciosamente em `factor`.

---

## 60. Modelos a testar

Executar ao menos um cenário conhecido para cada classe implementada:

```text
linear
quadratic
cubic
linear plateau
quadratic plateau
Mitscherlich
Michaelis-Menten
logistic
Gompertz
Weibull
GAM
VGAM smoother
polynomial inside GLM/GLMM
```

---

## 61. Recuperação de parâmetros

Simule dados com parâmetros conhecidos.

Exemplo quadrático:

```r
set.seed(123)
x <- rep(seq(0, 100, by = 10), each = 5)
y <- 10 + 2*x - 0.01*x^2 + rnorm(length(x), 0, 5)
dat <- data.frame(x, y)
```

O ótimo verdadeiro é aproximadamente:

\[
x_{max} = -\frac{\beta_1}{2\beta_2}=100.
\]

Verifique a recuperação dentro da incerteza esperada.

---

## 62. Plateau e breakpoint

Simule dados de plateau conhecidos e teste:

- breakpoint;
- plateau;
- IC;
- estabilidade a diferentes valores iniciais.

---

## 63. ED10, ED50 e ED90

Para curvas adequadas, verificar:

- estimativa;
- IC;
- ordenação lógica `ED10 < ED50 < ED90` quando a curva é monotônica crescente;
- comportamento adequado em curva decrescente.

---

## 64. Comparação de curvas

Use `agri_compare_curves()`.

Testar:

- curvas coincidentes;
- curvas diferentes apenas em intercepto;
- diferenças em slope;
- diferenças em plateau;
- dose × genótipo.

---

# PARTE XIV — DIAGNÓSTICOS

## 65. `agri_diagnose()`

A saída deve incluir, quando aplicável:

```text
convergence
residuals
dispersion
zero inflation
outliers/influence
random effects
temporal dependence
cluster dependence
calibration
prediction quality
```

---

## 66. Testar sensibilidade com problemas deliberados

Crie datasets com:

```text
overdispersion
underdispersion
excess zeros
wrong family
omitted random effect
wrong random structure
AR(1) residual correlation
outlier
cluster dependence
```

O diagnóstico deve reagir na direção esperada.

---

## 67. Influência

Verificar que observações influentes são **sinalizadas**, mas não removidas automaticamente.

O relatório deve preservar o índice/identificador da observação ou cluster.

---

## 68. DHARMa

Quando aplicável:

```r
sim <- DHARMa::simulateResiduals(engine_fit)
plot(sim)
```

Comparar o diagnóstico geral com a saída do wrapper.

---

## 69. Dependência por cluster

Crie deliberadamente dependência dentro de blocos ou parcelas e confirme que o diagnóstico não a interpreta como substituto do delineamento.

---

# PARTE XV — PREDIÇÃO E REAMOSTRAGEM

## 70. `agri_predict()`

Validar tipos disponíveis:

```text
conditional
marginal
population-level
cluster-specific
response
link
```

Nem todos os backends suportarão todos os tipos. O pacote deve avisar quando um tipo não for definido.

---

## 71. Cross-validation design-aware

Teste:

```r
agri_cv(fit, unit = "plot")
agri_cv(fit, unit = "block")
```

Para multiambiente:

```r
agri_cv(fit, scheme = "leave_one_environment_out")
```

Confirme que observações da mesma unidade não aparecem simultaneamente em treino e teste quando isso causaria leakage.

---

## 72. Métricas por tipo de resposta

### Contínua

```text
RMSE
MAE
```

### Binária

```text
Brier score
log-loss
```

### Multinomial

```text
multiclass log-loss
multiclass Brier score
```

### Composicional

```text
cross-entropy ou métrica específica implementada
```

Não aceitar RMSE como métrica universal sem justificativa.

---

## 73. Bootstrap por cluster

Teste que uma unidade experimental sorteada duas vezes seja tratada como **duas réplicas bootstrap distintas**.

Inspecione IDs bootstrap gerados.

Não permitir que duplicatas sejam simplesmente colapsadas para o mesmo cluster original.

---

# PARTE XVI — GRÁFICOS

## 74. Catálogo mínimo a validar

Execute, quando aplicável:

```r
agri_plot_data()
agri_plot_fit()
agri_plot_diagnostics()
agri_plot_means()
agri_plot_contrasts()
agri_plot_regression()
agri_plot_interaction()
agri_plot_distribution()
agri_plot_random()
agri_plot_family_scan()
```

---

## 75. Critérios gráficos

Verifique visualmente e programaticamente:

- títulos e eixos legíveis;
- unidades preservadas;
- dados observados mostrados quando pertinente;
- estimativas acompanhadas por IC;
- ausência de truncamento visual enganoso;
- curvas de regressão dentro do domínio observado;
- legenda coerente;
- suporte a temas claros;
- sem warnings do `ggplot2` que indiquem remoções inesperadas.

---

## 76. Teste de classe

Quando a função deve retornar `ggplot`:

```r
p <- agri_plot_fit(fit)
stopifnot(inherits(p, "ggplot"))
```

---

## 77. Snapshot visual com `vdiffr`

Se os testes `vdiffr` estiverem implementados:

```r
vdiffr::manage_cases()
```

Aceite alterações visuais somente após inspeção humana.

Nunca aprove automaticamente uma grande mudança de referência visual.

---

# PARTE XVII — VINHETAS

## 78. Inventário

O snapshot atual contém aproximadamente **23 vinhetas**, incluindo:

```text
v01-introduction
v02-designs
v03-hierarchical-designs
v04-count-data
v05-proportions
v06-positive
v07-gamlss
v08-ordinal
v09-regression
v10-multiple-comparisons
v11-diagnostics
v12-repeated
v13-multienvironment
v14-graphics
v15-simulation-power
v16-advanced-engines
v17-reproducible
v18-vgam
v19-state-of-the-art
vinhetas PT complementares
```

---

## 79. Renderizar todas as vinhetas

```r
devtools::build_vignettes(".")
```

Ou:

```r
pkgbuild::build(".", vignettes = TRUE)
```

Critério:

```text
Todas renderizam sem erro.
```

---

## 80. Renderização individual para depuração

Exemplo:

```r
rmarkdown::render("vignettes/v19-state-of-the-art.Rmd")
```

GAMLSS:

```r
rmarkdown::render("vignettes/v07-gamlss.Rmd")
```

VGAM:

```r
rmarkdown::render("vignettes/v18-vgam.Rmd")
```

---

## 81. Verificar chunks

Cada chunk executável deve:

- usar datasets existentes;
- carregar apenas dependências declaradas;
- possuir `set.seed()` quando houver aleatoriedade relevante;
- não depender de caminhos locais absolutos;
- não depender de arquivos fora do pacote;
- não acessar internet durante `R CMD check`.

---

# PARTE XVIII — ESTADO DA ARTE E REFERÊNCIAS

## 82. Validar a vinheta `v19-state-of-the-art.Rmd`

```r
stopifnot(file.exists("vignettes/v19-state-of-the-art.Rmd"))
stopifnot(file.exists("vignettes/references.bib"))
stopifnot(file.exists("inst/metadata/reference_verification.csv"))
stopifnot(file.exists("inst/METADATA_VERIFICATION.md"))
```

---

## 83. Verificar chaves BibTeX

Opcionalmente usar `bib2df`:

```r
install.packages("bib2df")
bib <- bib2df::bib2df("vignettes/references.bib")
head(bib)
```

Verificar duplicatas de DOI:

```r
doi <- tolower(trimws(bib$DOI))
doi <- doi[!is.na(doi) & nzchar(doi)]
doi[duplicated(doi)]
```

Idealmente nenhuma duplicata não intencional.

---

## 84. Dupla verificação de metadados

Leia:

```r
verify <- read.csv(
  "inst/metadata/reference_verification.csv",
  stringsAsFactors = FALSE
)
```

Para cada referência científica central, confirme pelo menos:

```text
título
autores
ano
periódico
volume
páginas/artigo
DOI
fonte 1
fonte 2
status
```

Critério:

```text
Todos os DOIs citados na vinheta central possuem duas fontes independentes e status verificado.
```

---

## 85. Atualidade dos pacotes comparados

Como versões de software mudam, antes de qualquer artigo/release execute nova verificação de:

```text
CRAN version
package status
archived/not archived
principal capabilities
limitations
```

Não reutilize indefinidamente a comparação datada de agosto de 2026.

---

# PARTE XIX — DATASETS INTERNOS

## 86. Inventário

O snapshot inclui aproximadamente 18 datasets, entre eles:

```text
agri_insects
agri_disease
agri_germination
agri_cover
agri_biomass
agri_ordinal
agri_dose
agri_splitplot
agri_split_split
agri_stripplot
agri_repeated
agri_multienv
agri_distreg
agri_multiclass
agri_multicounts
agri_composition
agri_ordstage
agri_censored
```

---

## 87. Carregar todos os datasets

Após instalar o pacote:

```r
data(package = "agriGLMflow")
```

Para cada dataset:

```r
str(agri_insects)
summary(agri_insects)
anyNA(agri_insects)
```

Nem todo `NA` é erro; ele deve ser intencional e documentado.

---

## 88. Validação semântica dos datasets

Verifique:

- contagens são inteiras não negativas;
- proporções respeitam limites;
- composições somam aproximadamente 1;
- sucesso não excede total;
- IDs de parcela são únicos no estrato apropriado;
- `time` tem ordenação válida;
- `environment` está presente em multiambiente;
- fatores têm níveis suficientes para o exemplo.

---

# PARTE XX — BATERIA DE SIMULAÇÕES A–L

## 89. Não executar a bateria completa antes dos testes rápidos

A bateria A–L é para validação científica e artigo. Primeiro faça:

```text
parse
load_all
testthat
vignettes
R CMD check
```

Depois execute simulações.

---

## 90. Confirmar cenários e sementes congeladas

```r
scenarios <- read.csv("inst/simulation/scenario_grid.csv")
seeds <- read.csv("inst/simulation/seeds.csv")

dim(scenarios)
dim(seeds)
head(scenarios)
head(seeds)
```

O snapshot foi preparado com aproximadamente:

```text
188 cenários
12.000 sementes
```

Registre as contagens reais obtidas localmente.

---

## 91. Não regenerar sementes antes do artigo final

O arquivo:

```text
inst/simulation/00_freeze_scenarios.R
```

somente deve ser usado conscientemente.

Não execute esse script automaticamente em cada validação se ele sobrescrever os cenários congelados.

Faça backup antes.

---

## 92. Testar cada módulo com poucas repetições

Antes da bateria completa, crie modo smoke test.

Exemplo conceitual:

```r
source("inst/simulation/helpers.R")
source("inst/simulation/01_count_family.R")
```

Execute 2–10 repetições por cenário para detectar erros de código.

Depois aumente para o número planejado.

---

## 93. Bateria A — famílias de contagem

Avaliar:

```text
true-family inclusion
ranking
bias
RMSE
CI coverage
Type I error
power
convergence
predictive score
runtime
```

---

## 94. Bateria B — proporções

DGPs esperados:

```text
binomial
beta-binomial
beta
extended beta
ordered beta
```

Variar zeros/uns de fronteira, dispersão e tamanho amostral.

---

## 95. Bateria C — contínuas positivas

```text
Gaussian
Gamma
lognormal
inverse Gaussian
Tweedie
```

---

## 96. Bateria D — GAMLSS

Comparar:

```text
mean-only
mu-only distributional
mu + sigma
```

Avaliar recuperação dos parâmetros e cobertura.

---

## 97. Bateria E — erro de delineamento

Este experimento é central.

Comparar modelos corretos versus incorretos em:

```text
RCBD
split-plot
split-split
strip-plot
repeated measures
multi-environment
```

Avaliar:

```text
Type I error
coverage
standard errors
power
random-effect variance
```

---

## 98. Bateria F — regressão quantitativa

Avaliar recuperação de:

```text
coeficientes
optimum
breakpoint
plateau
ED50
prediction error
coverage
```

---

## 99. Bateria G — comparações múltiplas

Avaliar:

```text
FWER
coverage
power
```

para Tukey, Dunnett e Holm.

---

## 100. Bateria H — sensibilidade diagnóstica

Inserir problemas conhecidos e estimar:

```text
sensitivity
specificity
```

---

## 101. Bateria I — ordinal VGAM

Testar:

```text
proportional odds
partial proportional odds
non-proportional odds
continuation ratio
```

---

## 102. Bateria J — multinomial VGAM

Variar:

```text
number of categories
rare classes
sample size
effect size
```

---

## 103. Bateria K — composicional VGAM

Testar:

```text
Dirichlet
Dirichlet-multinomial
```

---

## 104. Bateria L — parametrizações entre backends

Objetivo:

> Demonstrar equivalência somente após converter parâmetros para uma parametrização matemática comum.

Nunca compare diretamente `size`, `theta`, `phi` ou parâmetros de dispersão de pacotes diferentes apenas porque possuem nomes semelhantes.

---

## 105. Executar o orquestrador

Revise primeiro:

```text
inst/simulation/13_run_battery.R
```

Defina diretório de saída fora do source tree, por exemplo:

```text
D:\R-packages\agriGLMflow-validation\simulation-results
```

Evite salvar resultados massivos dentro de `inst/`.

---

# PARTE XXI — COBERTURA DE TESTES

## 106. Executar `covr`

```r
coverage <- covr::package_coverage(type = "tests")
coverage
```

Relatório HTML:

```r
covr::report(coverage)
```

Meta recomendada para o núcleo:

```text
> 90% para código crítico
```

A cobertura não substitui qualidade dos testes.

---

## 107. Identificar funções sem teste

Compare exports com resultados de cobertura e com referências nos arquivos `testthat`.

Funções particularmente críticas não podem depender somente de cobertura indireta:

```text
agri_design
agri_validate_design
agri_family_scan
agri_model
agri_diagnose
agri_means
agri_contrasts
agri_regression
agri_cv
agri_bootstrap
agri_workflow
```

---

# PARTE XXII — RELATÓRIOS E EXPORTAÇÃO

## 108. `agri_report()`

Gerar pelo menos:

```text
HTML
DOCX
```

Se PDF estiver habilitado, testar também PDF.

Use um diretório temporário:

```r
out <- tempfile("agri_report_")
dir.create(out)
```

Confirmar:

```r
list.files(out, recursive = TRUE)
```

Nenhum placeholder, comentário interno ou caminho local absoluto deve permanecer no relatório.

---

## 109. `agri_export()`

Teste exportação de:

- tabelas;
- gráficos;
- predições;
- audit trail;
- relatório.

Verifique codificação UTF-8 e separadores decimais esperados.

---

# PARTE XXIII — PKGDOWN E DOCUMENTAÇÃO WEB

## 110. Construir site local

```r
pkgdown::build_site(".", new_process = TRUE)
```

Verificar:

- nenhuma referência quebrada;
- todas as funções aparecem;
- vinhetas aparecem;
- datasets aparecem;
- links internos funcionam;
- exemplos não falham.

---

# PARTE XXIV — `R CMD build`

## 111. Build com R base

No PowerShell, a partir do diretório **pai** do pacote:

```powershell
cd D:\R-packages\agriGLMflow-validation\source
R CMD build agriGLMflow
```

Resultado esperado:

```text
agriGLMflow_0.1.0.tar.gz
```

### Importante

Este arquivo deve ser o tarball produzido por `R CMD build`, e não um ZIP/TAR criado manualmente.

---

## 112. Inspecionar conteúdo do tarball

PowerShell:

```powershell
tar -tf agriGLMflow_0.1.0.tar.gz
```

Verificar ausência de:

```text
*.tmp
*.bak
.git/
.Rproj.user/
resultados massivos
arquivos pessoais
snapshot tar.gz aninhado
credenciais
```

---

# PARTE XXV — `R CMD check --as-cran`

## 113. Criar diretório limpo de check

```powershell
cd D:\R-packages\agriGLMflow-validation\check
Copy-Item ..\source\agriGLMflow_0.1.0.tar.gz .
```

Ou simplesmente execute apontando para o tarball.

---

## 114. Check principal

```powershell
R CMD check --as-cran agriGLMflow_0.1.0.tar.gz
```

Salvar log:

```powershell
R CMD check --as-cran agriGLMflow_0.1.0.tar.gz 2>&1 | Tee-Object -FilePath ..\logs\R-CMD-check-as-cran.txt
```

---

## 115. Critério de interpretação

### `ERROR`

```text
0 permitido
```

### `WARNING`

```text
0 desejado
```

Qualquer WARNING exige correção ou justificativa muito clara antes de release.

### `NOTE`

```text
0 ideal
```

Algumas NOTEs podem depender do ambiente, mas não devem ser ignoradas sem análise.

---

## 116. Ler `00check.log`

```powershell
Get-Content .\agriGLMflow.Rcheck\00check.log
```

No R:

```r
cat(readLines("agriGLMflow.Rcheck/00check.log"), sep = "\n")
```

Guarde esse arquivo no diretório `logs`.

---

## 117. Verificar exemplos, testes e vinhetas no check

Dentro de:

```text
agriGLMflow.Rcheck
```

inspecione:

```text
00check.log
tests/
vign_test/
agriGLMflow-Ex.R
```

Os nomes exatos podem variar conforme a versão do R.

---

# PARTE XXVI — `devtools::check()` E `rcmdcheck`

## 118. Check de desenvolvimento

```r
devtools::check(".", cran = TRUE, manual = TRUE)
```

Também:

```r
rcmdcheck::rcmdcheck(
  path = ".",
  args = "--as-cran",
  error_on = "warning"
)
```

Durante release, prefira validar o **tarball construído**, não somente o source directory.

---

# PARTE XXVII — INSTALAÇÃO DO TARBALL CONSTRUÍDO

## 119. Instalar em biblioteca limpa

```powershell
R CMD INSTALL --library="D:\R-packages\agriGLMflow-validation\library" agriGLMflow_0.1.0.tar.gz
```

Depois:

```r
.libPaths("D:/R-packages/agriGLMflow-validation/library")
library(agriGLMflow)
packageVersion("agriGLMflow")
```

Esperado:

```text
0.1.0
```

---

## 120. Teste de namespace instalado

```r
ns <- getNamespaceExports("agriGLMflow")
length(ns)
sort(ns)
```

Compare com `NAMESPACE`.

---

# PARTE XXVIII — SMOKE TEST DO PACOTE INSTALADO

## 121. Script mínimo

Após instalar o tarball, iniciar **nova sessão de R** e executar:

```r
library(agriGLMflow)

agri_dependencies()
agri_engines()
agri_families()

data(agri_insects)

des <- agri_design(
  data = agri_insects,
  design = "rcbd",
  treatment = treatment,
  block = block
)

resp <- agri_response(
  data = agri_insects,
  response = insects
)

scan <- agri_family_scan(
  design = des,
  response = resp
)

print(des)
print(resp)
print(scan)
```

Adapte nomes das colunas caso o dataset use nomenclatura diferente; confira primeiro com `names(agri_insects)`.

---

# PARTE XXIX — TESTE DO WORKFLOW INTEGRADO

## 122. Workflow completo

Usar um dataset interno simples e executar:

```r
result <- agri_workflow(
  data = agri_insects,
  response = insects,
  treatment = treatment,
  block = block,
  design = "rcbd"
)

print(result)
```

Verificar componentes:

```r
names(result)
```

Esperado conceitualmente:

```text
design
response
family_scan
models
diagnostics
comparison
selected_model
anova
means
contrasts
trends
predictions
figures
audit
report
```

Nem todos podem estar preenchidos em todo cenário, mas o contrato deve ser consistente.

---

## 123. Audit trail

```r
agri_audit(result$selected_model)
```

Verifique que permita responder:

```text
Qual delineamento foi usado?
Qual resposta foi identificada?
Quais famílias foram consideradas?
Quais foram rejeitadas e por quê?
Qual engine foi escolhida?
Houve warnings?
Qual escala foi usada na inferência?
```

---

# PARTE XXX — TESTE EM SESSÃO LIMPA E DEPENDÊNCIAS AUSENTES

## 124. Testar comportamento quando `Suggests` não está instalado

Como diversos backends estão em `Suggests`, o pacote precisa falhar de forma informativa.

Em uma biblioteca separada, instale somente Imports e `agriGLMflow`.

Execute função que exija VGAM.

Resultado desejado:

```text
Mensagem clara informando que VGAM precisa ser instalado.
```

Não desejado:

```text
could not find function ...
object ... not found
namespace error obscuro
```

Repita para:

```text
glmmTMB
gamlss
VGAM
ordinal
emmeans
DHARMa
```

---

# PARTE XXXI — PORTABILIDADE

## 125. Windows

Obrigatório para este projeto.

Teste:

```text
R release + Rtools correspondente
locale UTF-8
caminho sem e com espaços
```

Um teste útil:

```text
D:\R Package Tests\agriGLMflow\
```

para detectar problemas de quoting.

---

## 126. Linux

Idealmente via GitHub Actions:

```text
ubuntu-latest
R release
R-devel
```

---

## 127. macOS

Idealmente:

```text
macos-latest
R release
```

---

## 128. Check flavors

Antes de CRAN, compare com a página oficial de **CRAN Package Check Flavors** e replique localmente o máximo possível das diferenças relevantes de plataforma.

---

# PARTE XXXII — REPRODUTIBILIDADE DE AMBIENTE

## 129. Registrar `sessionInfo()`

```r
capture.output(
  sessionInfo(),
  file = "D:/R-packages/agriGLMflow-validation/logs/sessionInfo.txt"
)
```

Também:

```r
capture.output(
  installed.packages()[, c("Package", "Version")],
  file = "D:/R-packages/agriGLMflow-validation/logs/installed-packages.txt"
)
```

---

## 130. `renv` opcional

Para congelar o ambiente de validação:

```r
install.packages("renv")
renv::init(bare = TRUE)
renv::snapshot()
```

Guarde `renv.lock` junto ao relatório interno de validação, se desejar reproduzir exatamente o ambiente.

Para um pacote CRAN, `renv` não deve substituir as dependências adequadamente declaradas no `DESCRIPTION`.

---

# PARTE XXXIII — VALIDAÇÃO OFFLINE

## 131. Objetivo

Depois da validação conectada, recomenda-se testar a instalação em máquina sem internet para confirmar que todas as dependências necessárias podem ser provisionadas antecipadamente.

---

## 132. Estratégia recomendada

Em um computador conectado:

1. criar uma biblioteca limpa;
2. instalar todas as dependências;
3. baixar binários/source necessários;
4. copiar para mídia/pasta offline;
5. criar repositório CRAN local ou instalar pelos arquivos;
6. validar em uma máquina/VM sem internet.

---

## 133. Lista de dependências a registrar

No computador conectado:

```r
d <- desc::desc_get_deps("DESCRIPTION")
d
write.csv(d, "agriGLMflow-dependencies.csv", row.names = FALSE)
```

Registrar também dependências recursivas instaladas:

```r
ip <- installed.packages()
write.csv(
  ip[, c("Package", "Version", "LibPath")],
  "installed-dependency-versions.csv",
  row.names = FALSE
)
```

---

## 134. Teste sem internet

Na máquina offline:

```r
options(repos = NULL)
```

Instale o tarball do pacote e execute o smoke test.

O teste deve confirmar que nenhuma vinheta, exemplo ou função principal tenta acessar internet implicitamente.

---

# PARTE XXXIV — PERFORMANCE E TEMPO

## 135. Medir operações principais

Para workflows pesados:

```r
t0 <- proc.time()
result <- agri_workflow(...)
proc.time() - t0
```

Registrar:

```text
n observations
number of treatments
number of blocks
candidate families
engine
elapsed time
peak memory if available
```

---

## 136. Não otimizar sacrificando validade

O router nunca deve reduzir a estrutura experimental somente para tornar o ajuste mais rápido.

---

# PARTE XXXV — TESTES DE ERRO E MENSAGENS

## 137. Entradas inválidas

Criar testes para:

```text
response inexistente
treatment inexistente
block inexistente
environment ausente em multi_environment
negative counts
proportion > 1
success > total
composition not summing to 1
duplicated subject-time
unsupported engine
unsupported family
VGAM + random effects
GLMMadaptive + incompatible grouping
```

Cada caso deve produzir mensagem compreensível.

---

## 138. Warnings científicos

Warnings devem explicar o problema.

Exemplo desejável:

```text
The requested VGAM model is incompatible with the declared random-effect design.
```

Exemplo inadequado:

```text
invalid model
```

---

# PARTE XXXVI — TESTE DE ESTADO DA ARTE E METADADOS

## 139. Referências

Antes de release científico:

1. verificar novamente cada DOI;
2. conferir título, autores, periódico, ano, volume e páginas/artigo;
3. verificar se toda citação da vinheta está em `references.bib`;
4. verificar se toda referência usada está citada;
5. revisar versões atuais dos pacotes comparados;
6. atualizar a data da revisão.

---

## 140. Evitar afirmações absolutas de novidade

Preferir:

```text
Within the reviewed and dated ecosystem, no single package was identified that...
```

Evitar:

```text
No other package exists...
```

A primeira formulação é auditável e defensável.

---

# PARTE XXXVII — CHECKLIST CRAN

## 141. Antes de build

- [ ] `DESCRIPTION` possui autores reais e e-mail do mantenedor.
- [ ] ORCIDs estão corretos.
- [ ] `LICENSE` é compatível com `License: GPL-3`.
- [ ] `NAMESPACE` foi regenerado com `roxygen2` quando necessário.
- [ ] Não existem arquivos temporários.
- [ ] Não existe tarball snapshot aninhado no source tree.
- [ ] Todos os Imports estão instalados.
- [ ] Todos os Suggests necessários às vinhetas/testes estão instalados.
- [ ] Parsing R passou.
- [ ] `load_all()` passou.
- [ ] `testthat` passou.
- [ ] Vinhetas renderizam.
- [ ] Referências estão validadas.

---

## 142. Depois do build

- [ ] `R CMD build` gerou `agriGLMflow_0.1.0.tar.gz`.
- [ ] O tarball não contém arquivos privados/provisórios.
- [ ] `R CMD INSTALL` do tarball funciona em biblioteca limpa.
- [ ] `R CMD check --as-cran` tem 0 ERROR.
- [ ] `R CMD check --as-cran` tem 0 WARNING.
- [ ] NOTEs foram resolvidas ou justificadas.
- [ ] Testes passam usando o pacote instalado.
- [ ] Site pkgdown pode ser construído.
- [ ] Hash SHA-256 do tarball foi registrado.

---

# PARTE XXXVIII — HASH E ARTEFATOS

## 143. SHA-256 no PowerShell

```powershell
Get-FileHash .\agriGLMflow_0.1.0.tar.gz -Algorithm SHA256
```

Salvar:

```powershell
Get-FileHash .\agriGLMflow_0.1.0.tar.gz -Algorithm SHA256 |
  Format-List |
  Out-File ..\logs\agriGLMflow_0.1.0_SHA256.txt
```

---

# PARTE XXXIX — RELATÓRIO DE VALIDAÇÃO

## 144. Criar relatório final

Após executar tudo, produzir:

```text
VALIDATION_LOCAL_RESULTS.md
```

com a seguinte estrutura:

```markdown
# agriGLMflow 0.1.0 — Local validation report

## System
- OS:
- R version:
- Rtools:
- Quarto:
- Date:

## Package artifact
- Source commit/snapshot:
- Built tarball:
- SHA-256:

## Static validation
- Result:

## Parsing
- Result:

## Documentation
- Result:

## Unit tests
- Passed:
- Failed:
- Skipped:

## Backend validation
- stats:
- lme4:
- glmmTMB:
- GLMMadaptive:
- gamlss:
- VGAM:
- ordinal:
- betareg:
- brglm2:

## Experimental-design validation
- CRD:
- RCBD:
- split-plot:
- split-split:
- strip-plot:
- repeated:
- multi-environment:

## Inference
- emmeans:
- Tukey:
- Dunnett:
- trends:

## Regression
- Result:

## Diagnostics
- Result:

## Resampling
- CV:
- bootstrap:

## Vignettes
- Rendered:
- Failed:

## State-of-the-art references
- Double verification:

## Simulation smoke tests
- A:
- B:
- C:
- D:
- E:
- F:
- G:
- H:
- I:
- J:
- K:
- L:

## R CMD build
- Result:

## R CMD check --as-cran
- ERROR:
- WARNING:
- NOTE:

## Remaining issues
1.
2.

## Release decision
- [ ] Not ready
- [ ] Ready for internal testing
- [ ] Ready for public GitHub release
- [ ] Ready for CRAN submission
```

---

# PARTE XL — SCRIPT R DE VALIDAÇÃO RÁPIDA

## 145. Script integrado inicial

Salve, opcionalmente, como:

```text
tools/local_validation_smoke.R
```

Conteúdo:

```r
options(warn = 1)

pkg <- normalizePath(".", winslash = "/", mustWork = TRUE)
cat("Package path:", pkg, "\n")

# 1. DESCRIPTION
stopifnot(file.exists("DESCRIPTION"))
desc <- read.dcf("DESCRIPTION")
stopifnot(desc[1, "Package"] == "agriGLMflow")
stopifnot(!grepl("REPLACE_WITH", desc[1, "Authors@R"]))

# 2. Parse R files
r_files <- list.files("R", pattern = "\\.[Rr]$", full.names = TRUE)
for (f in r_files) {
  cat("Parsing:", f, "\n")
  parse(file = f, keep.source = TRUE)
}

# 3. Load package
if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("Install devtools before validation.")
}
devtools::load_all(".", reset = TRUE, export_all = FALSE)

# 4. Public API
ns_lines <- readLines("NAMESPACE")
exports <- sub(
  "^export\\((.*)\\)$",
  "\\1",
  grep("^export\\(", ns_lines, value = TRUE)
)
cat("Exports:", length(exports), "\n")

# 5. Core registries
eng <- agri_engines()
fam <- agri_families()
cat("Engines available in registry:", NROW(eng), "\n")
cat("Family/capability entries:", NROW(fam), "\n")

# 6. Dependencies
print(agri_dependencies())

# 7. Unit tests
if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Install testthat before validation.")
}
devtools::test(".", reporter = "summary")

cat("\nSMOKE VALIDATION COMPLETED\n")
```

Execute:

```powershell
Rscript tools\local_validation_smoke.R 2>&1 |
  Tee-Object -FilePath D:\R-packages\agriGLMflow-validation\logs\smoke-validation.txt
```

---

# PARTE XLI — SCRIPT POWERSHELL DE BUILD/CHECK

## 146. Script sugerido

Salve como:

```text
validate-agriGLMflow.ps1
```

Conteúdo:

```powershell
$ErrorActionPreference = "Stop"

$Root = "D:\R-packages\agriGLMflow-validation"
$SourceParent = Join-Path $Root "source"
$PackageDir = Join-Path $SourceParent "agriGLMflow"
$LogDir = Join-Path $Root "logs"

New-Item -ItemType Directory -Force $LogDir | Out-Null

Write-Host "=== R version ==="
R --version

Write-Host "=== Static check ==="
Set-Location $PackageDir
py tools\static_check.py 2>&1 |
    Tee-Object -FilePath (Join-Path $LogDir "static-check.txt")

Write-Host "=== Smoke validation ==="
if (Test-Path "tools\local_validation_smoke.R") {
    Rscript tools\local_validation_smoke.R 2>&1 |
        Tee-Object -FilePath (Join-Path $LogDir "smoke-validation.txt")
}

Write-Host "=== R CMD build ==="
Set-Location $SourceParent
R CMD build agriGLMflow 2>&1 |
    Tee-Object -FilePath (Join-Path $LogDir "R-CMD-build.txt")

$Tarball = Get-ChildItem "agriGLMflow_*.tar.gz" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $Tarball) {
    throw "No tarball produced by R CMD build."
}

Write-Host "Tarball: $($Tarball.FullName)"

Write-Host "=== SHA256 ==="
Get-FileHash $Tarball.FullName -Algorithm SHA256 |
    Tee-Object -FilePath (Join-Path $LogDir "SHA256.txt")

Write-Host "=== R CMD check --as-cran ==="
Set-Location (Join-Path $Root "check")
R CMD check --as-cran $Tarball.FullName 2>&1 |
    Tee-Object -FilePath (Join-Path $LogDir "R-CMD-check-as-cran.txt")

Write-Host "=== DONE ==="
```

Antes de usá-lo, adapte `$Root`.

---

# PARTE XLII — PROBLEMAS FREQUENTES NO WINDOWS

## 147. `R` ou `Rscript` não reconhecido

No PowerShell:

```powershell
Get-Command R -ErrorAction SilentlyContinue
Get-Command Rscript -ErrorAction SilentlyContinue
```

Se vazio, localize:

```powershell
Get-ChildItem "C:\Program Files\R" -Directory
```

Exemplo temporário:

```powershell
$env:Path += ";C:\Program Files\R\R-4.6.1\bin"
```

Adapte à versão instalada.

---

## 148. `make` não encontrado

```r
pkgbuild::has_build_tools(debug = TRUE)
```

Se `FALSE`, verifique Rtools e PATH.

---

## 149. Erro de compilação em `glmmTMB`/TMB

Primeiro tente instalar binário compatível:

```r
install.packages("glmmTMB", type = "binary")
```

Se precisar compilar, confirme toolchain antes.

Reinicie R após atualização de Rtools.

---

## 150. Vinheta falha por pacote sugerido ausente

Instale o pacote explicitamente e repita.

Confira se a vinheta usa:

```r
if (requireNamespace("pkg", quietly = TRUE)) {
  ...
}
```

quando o código é realmente opcional.

Para uma vinheta central que promete demonstrar aquela funcionalidade, preferir declarar a dependência corretamente e executar o exemplo.

---

## 151. `R CMD check` reclama de arquivos não portáveis

Revise:

- nomes longos;
- caracteres especiais em nomes de arquivo;
- diferenças de maiúscula/minúscula;
- caminhos absolutos;
- arquivos ocultos.

---

## 152. Testes passam no RStudio, falham no check

Causa comum: dependência implícita do Global Environment.

Reinicie R e tente:

```r
rm(list = ls(all.names = TRUE))
gc()
devtools::test(".")
```

Depois use `R CMD check`, que executa em ambiente mais controlado.

---

## 153. Resultados mudam entre execuções

Verifique:

- `set.seed()`;
- paralelismo;
- simuladores de resíduos;
- bootstrap;
- geração de dados;
- otimizadores.

Para testes determinísticos, use sementes fixas e tolerâncias numéricas adequadas.

---

## 154. Diferenças entre backends

Antes de classificar como bug, confirme:

- função de ligação;
- parametrização da distribuição;
- método de likelihood;
- quadratura/Laplace;
- definição de dispersão;
- tratamento dos efeitos aleatórios;
- contraste/reference level;
- escala de predição.

---

# PARTE XLIII — NÍVEIS DE APROVAÇÃO

## 155. Nível A — validação estrutural

Exige:

- [ ] checker estático PASS;
- [ ] parsing R PASS;
- [ ] documentação/API coerente;
- [ ] nenhum arquivo provisório.

Esse nível **não** autoriza declarar o pacote cientificamente validado.

---

## 156. Nível B — validação funcional

Exige Nível A +:

- [ ] `load_all()`;
- [ ] testes unitários;
- [ ] datasets;
- [ ] vinhetas;
- [ ] gráficos;
- [ ] relatórios.

---

## 157. Nível C — validação numérica

Exige Nível B +:

- [ ] golden tests contra backends;
- [ ] delineamentos complexos;
- [ ] family scan;
- [ ] pós-modelo;
- [ ] regression recovery;
- [ ] reamostragem design-aware.

---

## 158. Nível D — validação científica

Exige Nível C +:

- [ ] simulações A–L;
- [ ] cobertura;
- [ ] erro tipo I;
- [ ] viés/RMSE;
- [ ] diagnóstico sensitivity/specificity;
- [ ] casos de estudo reais.

---

## 159. Nível E — release

Exige Nível D +:

- [ ] `R CMD build`;
- [ ] instalação do tarball limpo;
- [ ] `R CMD check --as-cran` satisfatório;
- [ ] Windows;
- [ ] Linux;
- [ ] macOS;
- [ ] documentação web;
- [ ] metadados do release;
- [ ] SHA-256.

---

# PARTE XLIV — MATRIZ RESUMIDA DE ACEITAÇÃO

| Área | Teste mínimo | Critério |
|---|---|---|
| Source | `tools/static_check.py` | PASS |
| Sintaxe | `parse()` de todos `R/*.R` | 0 erros |
| Metadata | `DESCRIPTION` | autores/e-mail reais |
| API | exports × aliases | 0 órfãos |
| Unit tests | `devtools::test()` | 0 failures/errors |
| CRD | golden test | equivalência |
| RCBD | golden test | efeitos fixos/aleatórios coerentes |
| Split-plot | estrutura | estrato whole-plot preservado |
| Split-split | estrutura | 3 níveis preservados |
| Strip-plot | estrutura | faixas/erros corretos |
| Repeated | dependência | tempo/sujeito corretos |
| Multi-env | guard | `environment` obrigatório |
| glmmTMB | golden tests | dentro da tolerância |
| lme4 | golden tests | dentro da tolerância |
| GLMMadaptive | guard | 1 grouping factor compatível |
| GAMLSS | parâmetros | mu/sigma/nu/tau corretos |
| VGAM | guards + modelos | fixed-only preservado |
| Ordinal | probabilidades | somam 1 e modelo correto |
| Composition | Dirichlet | composições válidas |
| emmeans | EMMs/contrastes | equivalência |
| Dunnett | controle | contraste correto |
| Regression | recovery | parâmetros/IC coerentes |
| Diagnostics | cenários artificiais | sinais detectados |
| CV | splits | sem leakage |
| Bootstrap | cluster IDs | duplicações preservadas |
| Plots | execução/inspeção | sem erro e com incerteza |
| Vignettes | build | todas renderizam |
| References | audit | dupla verificação |
| Simulation | A–L smoke/full | reproduzível |
| Coverage | `covr` | >90% núcleo crítico desejado |
| Build | `R CMD build` | tarball gerado |
| Check | `R CMD check --as-cran` | 0 ERROR/WARNING desejado |
| Install | clean lib | sucesso |
| Portability | Win/Linux/macOS | sucesso |

---

# PARTE XLV — SEQUÊNCIA RECOMENDADA, SEM ATALHOS

## 160. Ordem completa

Execute exatamente nesta lógica:

```text
01. Extrair snapshot em diretório limpo
02. Corrigir Authors@R e mantenedor
03. Remover arquivos provisórios/aninhados
04. Registrar R/Rtools/sessionInfo
05. Criar biblioteca isolada
06. Instalar dependências
07. Executar static_check.py
08. Parsear todo código com R
09. devtools::document()
10. devtools::load_all()
11. devtools::test()
12. Testes direcionados por backend
13. Testes direcionados por delineamento
14. Golden tests
15. Testes de inferência
16. Testes de regressão
17. Testes de diagnóstico
18. Testes de CV/bootstrap
19. Testes de gráficos
20. Renderizar todas as vinhetas
21. Verificar bibliografia/estado da arte
22. pkgdown::build_site()
23. covr::package_coverage()
24. Simulation smoke tests A–L
25. Bateria científica completa quando apropriado
26. R CMD build
27. Inspecionar tarball
28. R CMD INSTALL em biblioteca limpa
29. Smoke test do pacote instalado
30. R CMD check --as-cran no tarball
31. Repetir em Windows/Linux/macOS
32. Gerar relatório de validação
33. Calcular SHA-256
34. Somente então classificar como release candidate
```

---

# PARTE XLVI — REFERÊNCIAS OFICIAIS PARA O PROCESSO

## 161. Documentação principal

Antes de uma submissão efetiva, conferir sempre as páginas atuais, pois versões e políticas podem mudar.

- R Core Team. *Writing R Extensions*. Manual oficial para criação, documentação, build e check de pacotes R.  
  `https://cran.r-project.org/doc/manuals/r-release/R-exts.html`

- CRAN. *RTools: Toolchains for building R and R packages from source on Windows*.  
  `https://cran.r-project.org/bin/windows/Rtools/`

- CRAN. *Package Check Flavors*.  
  `https://cran.r-project.org/web/checks/check_flavors.html`

---

# 162. Decisão final de release

O pacote pode ser considerado **pronto para submissão ao CRAN** somente quando houver evidência documentada de que:

1. o tarball foi produzido por `R CMD build`;
2. o tarball foi instalado em biblioteca limpa;
3. `R CMD check --as-cran` foi executado sobre esse tarball;
4. não há `ERROR`;
5. não há `WARNING` pendente;
6. qualquer `NOTE` foi resolvida ou claramente justificada;
7. os backends científicos principais foram testados em runtime;
8. os delineamentos complexos foram validados numericamente;
9. as vinhetas renderizam;
10. as referências da vinheta de estado da arte permanecem verificadas;
11. os exemplos manuais são executáveis;
12. as decisões automáticas podem ser reconstruídas por `agri_audit()`;
13. a bateria de simulações relevante ao manuscrito está congelada e reproduzível;
14. o pacote passou, idealmente, em Windows, Linux e macOS.

Até essa etapa, use termos como:

```text
source snapshot
development version
validation candidate
release candidate
```

Não use `CRAN-ready` ou `fully validated` sem executar efetivamente o processo correspondente.

---

# 163. Resultado esperado desta validação

Ao finalizar este guia, a pasta de validação deve conter, no mínimo:

```text
agriGLMflow-validation/
├── source/
│   ├── agriGLMflow/
│   └── agriGLMflow_0.1.0.tar.gz
├── check/
│   └── agriGLMflow.Rcheck/
├── library/
├── logs/
│   ├── sessionInfo.txt
│   ├── installed-packages.txt
│   ├── static-check.txt
│   ├── smoke-validation.txt
│   ├── R-CMD-build.txt
│   ├── R-CMD-check-as-cran.txt
│   └── SHA256.txt
├── simulation-results/
├── artifacts/
└── VALIDATION_LOCAL_RESULTS.md
```

Esse conjunto constitui a evidência local mínima recomendada para afirmar que o pacote foi submetido a um processo sistemático de validação.
