# Criação de tabelas no Snowflake
O USE WAREHOUSE não afeta onde a tabela é criada, apenas onde a query é executada (compute). Ou seja:
 * Database/Schema → definem local da tabela
 * Warehouse → define processamento

## Boas práticas
 * Use USE DATABASE, USE SCHEMA e USE WAREHOUSE no início do script
 * Em scripts críticos (deploy/produção), prefira nomes totalmente qualificados, 
   ex: CREATE TABLE novadrive.stage.veiculos (...
 * Sempre crie o schema com o database explícito (novadrive.stage)
  
## Leitura importante (onde o curso simplificou)
O curso está certo conceitualmente, mas hoje o mercado já evoluiu para:
 * STAGE não é só tipagem
 * STAGE já inclui:
 * rastreabilidade (carga_id)
 * auditoria (data_carga)
 * governança (tags)
  
  ## Resumo direto
Seu raciocínio está correto:
  * Dados estruturados → direto para STAGE
  * Sem PK/FK → ok
  * Sem limpeza pesada → ok

Mas em projetos reais você precisa:
 * rastreabilidade + padronização + reprocessamento seguro

## O que eu NÃO fiz (de propósito)
Mantive sua premissa:
* Sem PK/FK
* Sem deduplicação
* Sem regras de negócio
* Sem normalização extra

**Nota**: Isso está correto para STAGE.

No Snowflake você **já pode (e deve)** adicionar metadados no momento da criação da tabela.

Existem algumas formas bem úteis:

---
## 1. Comentários (TABLE e COLUMN)

Você pode documentar a tabela e suas colunas diretamente:

```sql id="8qk2np"
CREATE TABLE novadrive.stage.veiculos (
    id_veiculos INTEGER COMMENT 'Identificador único do veículo',
    nome VARCHAR(255) NOT NULL COMMENT 'Nome do veículo',
    tipo VARCHAR(100) NOT NULL COMMENT 'Tipo do veículo (carro, moto, etc)',
    valor DECIMAL(10, 2) NOT NULL COMMENT 'Valor do veículo',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro'
)
COMMENT = 'Tabela de veículos da NovaDrive (camada stage)';
```

✔ Isso ajuda muito em governança e ferramentas de catálogo.

---
## 2. Tags (governança e classificação)
Snowflake permite adicionar **tags** (ótimo para LGPD, classificação de dados, etc.):

```sql id="jxhpz1"
CREATE TABLE novadrive.stage.veiculos (
    id_veiculos INTEGER,
    nome VARCHAR(255)
)
WITH TAG (
    classificacao_dado = 'interno',
    dominio = 'frota'
);
```

> ⚠️ As tags precisam ser criadas previamente (`CREATE TAG`)

---
## 3. Políticas (ex: masking)
Você também pode já associar políticas:

```sql id="1g9i3d"
CREATE TABLE novadrive.stage.veiculos (
    id_veiculos INTEGER,
    nome VARCHAR(255)
        WITH MASKING POLICY minha_policy
);
```

---
## 4. Outros metadados úteis na criação
Você pode incluir propriedades da tabela:

```sql id="qdf0az"
CREATE TABLE novadrive.stage.veiculos (
    id_veiculos INTEGER,
    nome VARCHAR(255)
)
DATA_RETENTION_TIME_IN_DAYS = 1
CHANGE_TRACKING = TRUE;
```

---
## Boas práticas
* Sempre usar `COMMENT` (baixo esforço, alto valor)
* Padronizar `tags` para governança
* Nomear bem os campos (metadado implícito também conta)
* Documentar já na criação evita retrabalho depois

Perfeito — aqui vai um **template padrão “corporativo” de `CREATE TABLE`** no Snowflake, já com boas práticas de governança, organização e reutilização 🚀

---
## Template padrão
```sql id="tpl9a2"
/* ============================================================
   OBJETO:        <database>.<schema>.<tabela>
   DESCRIÇÃO:     <descrição da tabela>
   DOMÍNIO:       <ex: frota, financeiro, cliente>
   CAMADA:        <ex: stage, raw, curated>
   RESPONSÁVEL:   <time ou pessoa>
   CRIAÇÃO:       <data>
   ============================================================ */

CREATE TABLE IF NOT EXISTS <database>.<schema>.<tabela> (
    -- =========================
    -- CHAVE PRIMÁRIA
    -- =========================
    id_<tabela> INTEGER 
        COMMENT 'Identificador único do registro',

    -- =========================
    -- DADOS DE NEGÓCIO
    -- =========================
    nome VARCHAR(255) NOT NULL 
        COMMENT 'Nome descritivo do registro',

    tipo VARCHAR(100) NOT NULL 
        COMMENT 'Categoria ou tipo do registro',

    valor DECIMAL(10,2) 
        COMMENT 'Valor associado ao registro',

    -- =========================
    -- CONTROLE / AUDITORIA
    -- =========================
    data_inclusao TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP 
        COMMENT 'Data de inclusão do registro',

    data_atualizacao TIMESTAMP_LTZ 
        COMMENT 'Data da última atualização',

    -- =========================
    -- METADADOS TÉCNICOS
    -- =========================
    origem_dado VARCHAR(100) 
        COMMENT 'Sistema de origem do dado',

    carga_id VARCHAR(100) 
        COMMENT 'Identificador da carga (batch/stream)',

    CONSTRAINT pk_<tabela> PRIMARY KEY (id_<tabela>)

)
COMMENT = '<descrição da tabela>'

-- =========================
-- GOVERNANÇA
-- =========================
WITH TAG (
    dominio = '<dominio>',
    camada = '<camada>',
    classificacao_dado = '<publico|interno|sensivel|restrito>'
)

-- =========================
-- CONFIGURAÇÕES TÉCNICAS
-- =========================
DATA_RETENTION_TIME_IN_DAYS = 1
CHANGE_TRACKING = TRUE;
```

---
## Exemplo aplicado (seu caso)

```sql id="ex4k1m"
CREATE TABLE IF NOT EXISTS novadrive.stage.veiculos (

    id_veiculos INTEGER 
        COMMENT 'Identificador único do veículo',

    nome VARCHAR(255) NOT NULL 
        COMMENT 'Nome do veículo',

    tipo VARCHAR(100) NOT NULL 
        COMMENT 'Tipo do veículo',

    valor DECIMAL(10,2) 
        COMMENT 'Valor do veículo',

    data_inclusao TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP 
        COMMENT 'Data de inclusão',

    data_atualizacao TIMESTAMP_LTZ 
        COMMENT 'Data da última atualização',

    origem_dado VARCHAR(100) 
        COMMENT 'Sistema de origem',

    carga_id VARCHAR(100) 
        COMMENT 'Identificador da carga'

)
COMMENT = 'Tabela de veículos - camada stage'

WITH TAG (
    dominio = 'frota',
    camada = 'stage',
    classificacao_dado = 'interno'
)

DATA_RETENTION_TIME_IN_DAYS = 1
CHANGE_TRACKING = TRUE;
```

---
## Por que esse padrão é forte
* 🔍 **Documentação embutida** → facilita entendimento e catálogo
* 🔐 **Governança pronta** → tags + classificação
* 🔁 **Idempotente** → `IF NOT EXISTS`
* 🧾 **Auditável** → colunas de controle
* ⚙️ **Preparado para CDC** → `CHANGE_TRACKING`

---
## Ajustes que você pode fazer
* Remover `PRIMARY KEY` se não usar (Snowflake não enforce)
* Ajustar `DATA_RETENTION` conforme custo x necessidade
* Incluir **masking policies** se houver dados sensíveis
* Criar padrão de nomes (ex: `stg_`, `dim_`, `fact_`)

Perfeito — então vamos subir um nível e organizar isso como um **padrão completo de Data Warehouse no Snowflake** 💼

A ideia é ter uma estrutura clara e escalável: **RAW → STAGE → CURATED**.

---
# Arquitetura recomendada
## 🔹 1. RAW (dados brutos)
* Dados **como vieram da origem**
* Sem transformação
* Apenas ingestão

**Exemplo:**

```sql id="raw1"
CREATE TABLE novadrive.raw.veiculos_raw (
    payload VARIANT,
    data_ingestao TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Dados brutos de veículos (JSON original)'
WITH TAG (
    camada = 'raw',
    dominio = 'frota',
    classificacao_dado = 'interno'
);
```

---
## 🔹 2. STAGE (dados tratados)
* Estruturação básica
* Tipagem
* Limpeza leve

**Exemplo (o seu caso evoluído):**

```sql id="stage1"
CREATE TABLE novadrive.stage.veiculos (

    id_veiculos INTEGER COMMENT 'ID do veículo',
    nome VARCHAR(255) COMMENT 'Nome do veículo',
    tipo VARCHAR(100) COMMENT 'Tipo',
    valor DECIMAL(10,2) COMMENT 'Valor',

    data_inclusao TIMESTAMP_LTZ,
    data_atualizacao TIMESTAMP_LTZ,

    origem_dado VARCHAR(100),
    carga_id VARCHAR(100)

)
COMMENT = 'Dados tratados de veículos'
WITH TAG (
    camada = 'stage',
    dominio = 'frota',
    classificacao_dado = 'interno'
);
```

---
## 3. CURATED (dados para negócio)
* Modelagem analítica (star schema, por exemplo)
* Dados confiáveis e prontos para BI

### Dimensão
```sql id="cur1"
CREATE TABLE novadrive.curated.dim_veiculo (

    sk_veiculo INTEGER AUTOINCREMENT,
    id_veiculos INTEGER,
    nome VARCHAR(255),
    tipo VARCHAR(100),

    data_inicio TIMESTAMP_LTZ,
    data_fim TIMESTAMP_LTZ,
    ativo BOOLEAN

)
COMMENT = 'Dimensão de veículos'
WITH TAG (
    camada = 'curated',
    tipo = 'dimensao',
    dominio = 'frota'
);
```

### Fato
```sql id="cur2"
CREATE TABLE novadrive.curated.fato_vendas_veiculos (

    sk_venda INTEGER AUTOINCREMENT,
    sk_veiculo INTEGER,
    valor DECIMAL(10,2),
    data_venda DATE

)
COMMENT = 'Fato de vendas de veículos'
WITH TAG (
    camada = 'curated',
    tipo = 'fato',
    dominio = 'frota'
);
```

---

# Naming conventions (muito importante)

| Tipo     | Prefixo                 | Exemplo        |
| -------- | ----------------------- | -------------- |
| Raw      | `_raw`                  | `veiculos_raw` |
| Stage    | (sem prefixo ou `stg_`) | `veiculos`     |
| Dimensão | `dim_`                  | `dim_veiculo`  |
| Fato     | `fato_` ou `fact_`      | `fato_vendas`  |

---
# Fluxo de dados

```
Fonte → RAW → STAGE → CURATED → BI
```

* RAW: ingestão (Snowpipe, batch, etc.)
* STAGE: SQL transformations
* CURATED: modelagem analítica

---
# Extras profissionais
Você pode evoluir isso com:
* ✅ **Streams + Tasks** (CDC e automação)
* ✅ **Snowpipe** (ingestão contínua)
* ✅ **Masking Policies** (LGPD)
* ✅ **Tags obrigatórias por camada**
* ✅ **dbt** para versionamento e deploy

---
# Dica prática (muito usada no mercado)
Mesmo no Snowflake:
* Separe schemas por camada:
  * `raw`
  * `stage`
  * `curated`

Ou até databases separados (ambientes maiores).

---

Sim — **é exatamente a mesma ideia**, só muda a nomenclatura 👍

---

## 🧠 Equivalência direta

| Conceito clássico | Medallion (moderno) |
| ----------------- | ------------------- |
| RAW               | 🥉 Bronze           |
| STAGE             | 🥈 Silver           |
| CURATED           | 🥇 Gold             |

---
## 🔍 Como interpretar cada camada
### 🥉 RAW = Bronze
* Dados **brutos**, sem tratamento
* Pode estar em JSON, CSV, etc.
* Exatamente como veio da fonte

Exemplo: ingestão via API ou arquivo

---
### 🥈 STAGE = Silver
* Dados **limpos e estruturados**
* Tipagem correta
* Remoção de inconsistências básicas

Aqui você já consegue fazer análises simples

---
### 🥇 CURATED = Gold
* Dados **modelados para negócio**
* Prontos para BI, dashboards e métricas
* Pode usar star schema (dim/fact)

Exemplo: tabela de vendas pronta pro Power BI

---
## No Snowflake
As duas abordagens são usadas — depende mais de:
* Cultura da empresa
* Ferramentas (ex: Databricks popularizou Bronze/Silver/Gold)

---
## Diferença prática (quando existe)
Na prática, algumas empresas fazem pequenas variações:
* **STAGE ≠ exatamente Silver**
  * STAGE pode ser mais “leve” (quase RAW estruturado)
* Silver às vezes inclui **regras de negócio leves**

Mas no geral, pode considerar **equivalente sim** sem medo.

---
## Dica de mercado
Se estiver:
* 📊 em ambiente mais tradicional → use **RAW/STAGE/CURATED**
* ⚡ em ambiente moderno/lakehouse → use **Bronze/Silver/Gold**

---
## 1 `CREATE TABLE IF NOT EXISTS`

```sql id="tbl1"
CREATE TABLE IF NOT EXISTS novadrive.stage.veiculos (
    id_veiculos INTEGER,
    nome VARCHAR(255)
);
```

* **O que faz:** cria a tabela **somente se não existir**
* **O que não faz:** altera a tabela se ela já existir
  * Ex.: adicionar coluna, mudar tipo ou comentário **não acontece**
* Portanto, **não é 100% idempotente para alterações**

---
## 2️ `CREATE OR REPLACE TABLE`
```sql id="tbl2"
CREATE OR REPLACE TABLE novadrive.stage.veiculos (
    id_veiculos INTEGER,
    nome VARCHAR(255)
);
```

* **O que faz:**
  * Se a tabela **não existir**, cria
  * Se existir, **apaga e recria** com a definição nova
* ⚠️ **Perigo:** apaga todos os dados existentes

---
## 3️ Snowflake não tem `CREATE OR ALTER TABLE` direto
* Diferente de outros bancos (SQL Server, Oracle), Snowflake **não tem** um comando “alter if exists” para **criação segura**
* Para manter idempotência **sem perder dados**, você precisa usar **condicional + ALTER** manual:

```sql id="tbl3"
-- Verifica se a tabela existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'STAGE' 
                 AND TABLE_NAME = 'VEICULOS') 
THEN
    CREATE TABLE novadrive.stage.veiculos (
        id_veiculos INTEGER,
        nome VARCHAR(255)
    );
ELSE
    -- ALTER TABLE aqui se quiser adicionar coluna ou modificar comentário
    ALTER TABLE novadrive.stage.veiculos
        ADD COLUMN carga_id STRING COMMENT 'Identificador da carga';
END IF;
```

> Esse tipo de script é mais trabalhoso, mas **é o padrão em pipelines de produção** para não perder dados.

---
## Prática comum
1. Para **Stage/Raw**, onde você **reescreve toda a tabela diariamente**: `CREATE OR REPLACE TABLE` funciona bem
2. Para **Curated/Dim/Fact**, onde **os dados não podem ser perdidos**:

   * `CREATE TABLE IF NOT EXISTS` + `ALTER TABLE ... ADD COLUMN` conforme necessário
   * Evita perda de histórico

---