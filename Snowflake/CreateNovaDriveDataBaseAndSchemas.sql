-- ============================================================
-- STAGE - NOVADRIVE (OLTP INCREMENTAL LOAD - POSTGRES)
-- Camada: STAGE (Silver)
-- Descrição: Dados estruturados provenientes do OLTP (PostgreSQL),
--            com tipagem definida, rastreabilidade de carga e sem regras de negócio.
-- ============================================================

-- ============================================================
-- CRIAÇÃO DE RECURSOS (IDEMPOTENTE)
-- ============================================================
CREATE DATABASE IF NOT EXISTS novadrive;
CREATE SCHEMA IF NOT EXISTS novadrive.stage;
CREATE WAREHOUSE IF NOT EXISTS DEFAULT_WH;

-- ============================================================
-- TAGS
-- Tags de governança usadas para classificar camada e domínio
-- Need to be created before they can be used in WITH TAG clauses. 
-- ============================================================
CREATE TAG IF NOT EXISTS novadrive.stage.camada COMMENT = 'Camada da arquitetura (stage, curated, analytics)';
CREATE TAG IF NOT EXISTS novadrive.stage.dominio COMMENT = 'Domínio de negócio (frota, localizacao, comercial)';

-- ============================================================
-- CONTEXTO DE SESSÃO
-- ============================================================
USE DATABASE novadrive;
USE SCHEMA stage;
USE WAREHOUSE DEFAULT_WH;

-- ============================================================
-- TABELA: VEICULOS
-- ============================================================
-- Apaga a tabela se existir
-- DROP TABLE IF EXISTS novadrive.stage.veiculos;

CREATE TABLE IF NOT EXISTS novadrive.stage.veiculos (
    id_veiculos INTEGER COMMENT 'Chave primária natural do veículo no sistema origem OLTP',
    nome VARCHAR(255) NOT NULL COMMENT 'Nome do veículo ou modelo',
    tipo VARCHAR(100) NOT NULL COMMENT 'Tipo de veículo (ex: carro, moto, caminhão)',
    valor DECIMAL(10, 2) NOT NULL COMMENT 'Preço do veículo registrado na origem',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data em que o registro foi incluído no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro no OLTP',
    carga_id STRING COMMENT 'Identificador único da carga no pipeline (batch ou full load)',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de veículos (dados estruturados do OLTP)'
WITH TAG (
    camada = 'stage',
    dominio = 'frota'
);

-- ============================================================
-- TABELA: ESTADOS
-- ============================================================

CREATE TABLE IF NOT EXISTS novadrive.stage.estados (
    id_estados INTEGER COMMENT 'Chave natural do estado no OLTP',
    estado VARCHAR(100) NOT NULL COMMENT 'Nome completo do estado',
    sigla CHAR(2) NOT NULL COMMENT 'Sigla oficial do estado',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro no OLTP',
    carga_id STRING COMMENT 'Identificador da carga no pipeline',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de estados'
WITH TAG (camada = 'stage', dominio = 'localizacao');

-- ============================================================
-- TABELA: CIDADES
-- ============================================================

CREATE TABLE IF NOT EXISTS novadrive.stage.cidades (
    id_cidades INTEGER COMMENT 'Chave natural da cidade no OLTP',
    cidade VARCHAR(255) NOT NULL COMMENT 'Nome da cidade',
    id_estados INTEGER NOT NULL COMMENT 'ID do estado ao qual a cidade pertence (FK lógica)',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro no OLTP',
    carga_id STRING COMMENT 'Identificador da carga no pipeline',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de cidades'
WITH TAG (camada = 'stage', dominio = 'localizacao');

-- ============================================================
-- TABELA: CONCESSIONARIAS
-- ============================================================

CREATE TABLE IF NOT EXISTS novadrive.stage.concessionarias (
    id_concessionarias INTEGER COMMENT 'Chave natural da concessionária no OLTP',
    concessionaria VARCHAR(255) NOT NULL COMMENT 'Nome da concessionária',
    id_cidades INTEGER NOT NULL COMMENT 'ID da cidade onde a concessionária está localizada (FK lógica)',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro no OLTP',
    carga_id STRING COMMENT 'Identificador da carga no pipeline',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de concessionárias'
WITH TAG (camada = 'stage', dominio = 'frota');

-- ============================================================
-- TABELA: VENDEDORES
-- ============================================================
CREATE TABLE IF NOT EXISTS novadrive.stage.vendedores (
    id_vendedores INTEGER COMMENT 'Chave natural do vendedor no OLTP',
    nome VARCHAR(255) NOT NULL COMMENT 'Nome completo do vendedor',
    id_concessionarias INTEGER NOT NULL COMMENT 'ID da concessionária associada (FK lógica)',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro no OLTP',
    carga_id STRING COMMENT 'Identificador da carga no pipeline',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de vendedores'
WITH TAG (camada = 'stage', dominio = 'comercial');

-- ============================================================
-- TABELA: CLIENTES
-- ============================================================
CREATE TABLE IF NOT EXISTS novadrive.stage.clientes (
    id_clientes INTEGER COMMENT 'Chave natural do cliente no OLTP',
    cliente VARCHAR(255) NOT NULL COMMENT 'Nome completo do cliente',
    endereco STRING NOT NULL COMMENT 'Endereço completo do cliente',
    id_concessionarias INTEGER NOT NULL COMMENT 'ID da concessionária associada ao cliente (FK lógica)',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro no OLTP',
    carga_id STRING COMMENT 'Identificador da carga no pipeline',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de clientes'
WITH TAG (camada = 'stage', dominio = 'comercial');

-- ============================================================
-- TABELA: VENDAS
-- ============================================================
CREATE TABLE IF NOT EXISTS novadrive.stage.vendas (
    id_vendas INTEGER COMMENT 'Chave natural da venda no OLTP',
    id_veiculos INTEGER NOT NULL COMMENT 'ID do veículo vendido (FK lógica)',
    id_concessionarias INTEGER NOT NULL COMMENT 'ID da concessionária que realizou a venda (FK lógica)',
    id_vendedores INTEGER NOT NULL COMMENT 'ID do vendedor responsável pela venda (FK lógica)',
    id_clientes INTEGER NOT NULL COMMENT 'ID do cliente comprador (FK lógica)',
    valor_pago DECIMAL(10, 2) NOT NULL COMMENT 'Valor pago pelo cliente na venda',
    data_venda TIMESTAMP_LTZ COMMENT 'Data em que a venda foi realizada no sistema OLTP',
    data_inclusao TIMESTAMP_LTZ COMMENT 'Data de inclusão do registro de venda no OLTP',
    data_atualizacao TIMESTAMP_LTZ COMMENT 'Data da última atualização do registro de venda no OLTP',
    carga_id STRING COMMENT 'Identificador da carga no pipeline',
    data_carga TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp de ingestão no Snowflake'
)
COMMENT = 'Stage de vendas'
WITH TAG (camada = 'stage', dominio = 'comercial');