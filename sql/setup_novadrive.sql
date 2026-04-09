-- ============================================================
-- NOVADRIVE - Database and Schema Setup
-- ============================================================

CREATE DATABASE IF NOT EXISTS NOVADRIVE;
CREATE SCHEMA IF NOT EXISTS NOVADRIVE.STAGE;
CREATE SCHEMA IF NOT EXISTS NOVADRIVE.ANALYTICS;
CREATE WAREHOUSE IF NOT EXISTS DEFAULT_WH;

-- ============================================================
-- TAGS
-- ============================================================
CREATE TAG IF NOT EXISTS NOVADRIVE.STAGE.CAMADA COMMENT = 'Camada da arquitetura (stage, curated, analytics)';
CREATE TAG IF NOT EXISTS NOVADRIVE.STAGE.DOMINIO COMMENT = 'Domínio de negócio (frota, localizacao, comercial)';

-- ============================================================
-- TABELA: VEICULOS
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.VEICULOS (
    ID_VEICULOS INTEGER COMMENT 'ID do veículo no sistema origem',
    NOME VARCHAR(255) NOT NULL COMMENT 'Nome do veículo',
    TIPO VARCHAR(100) NOT NULL COMMENT 'Tipo do veículo',
    VALOR DECIMAL(10, 2) NOT NULL COMMENT 'Valor do veículo',
    DATA_INCLUSAO TIMESTAMP_LTZ COMMENT 'Data de inclusão no sistema origem',
    DATA_ATUALIZACAO TIMESTAMP_LTZ COMMENT 'Data de atualização no sistema origem',
    CARGA_ID STRING COMMENT 'Identificador da carga',
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de ingestão no Snowflake'
)
COMMENT = 'Stage de veículos (dados estruturados do OLTP)'
WITH TAG (CAMADA = 'stage', DOMINIO = 'frota');

-- ============================================================
-- TABELA: ESTADOS
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.ESTADOS (
    ID_ESTADOS INTEGER,
    ESTADO VARCHAR(100) NOT NULL,
    SIGLA CHAR(2) NOT NULL,
    DATA_INCLUSAO TIMESTAMP_LTZ,
    DATA_ATUALIZACAO TIMESTAMP_LTZ,
    CARGA_ID STRING,
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Stage de estados'
WITH TAG (CAMADA = 'stage', DOMINIO = 'localizacao');

-- ============================================================
-- TABELA: CIDADES
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.CIDADES (
    ID_CIDADES INTEGER,
    CIDADE VARCHAR(255) NOT NULL,
    ID_ESTADOS INTEGER NOT NULL,
    DATA_INCLUSAO TIMESTAMP_LTZ,
    DATA_ATUALIZACAO TIMESTAMP_LTZ,
    CARGA_ID STRING,
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Stage de cidades'
WITH TAG (CAMADA = 'stage', DOMINIO = 'localizacao');

-- ============================================================
-- TABELA: CONCESSIONARIAS
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.CONCESSIONARIAS (
    ID_CONCESSIONARIAS INTEGER,
    CONCESSIONARIA VARCHAR(255) NOT NULL,
    ID_CIDADES INTEGER NOT NULL,
    DATA_INCLUSAO TIMESTAMP_LTZ,
    DATA_ATUALIZACAO TIMESTAMP_LTZ,
    CARGA_ID STRING,
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Stage de concessionárias'
WITH TAG (CAMADA = 'stage', DOMINIO = 'frota');

-- ============================================================
-- TABELA: VENDEDORES
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.VENDEDORES (
    ID_VENDEDORES INTEGER,
    NOME VARCHAR(255) NOT NULL,
    ID_CONCESSIONARIAS INTEGER NOT NULL,
    DATA_INCLUSAO TIMESTAMP_LTZ,
    DATA_ATUALIZACAO TIMESTAMP_LTZ,
    CARGA_ID STRING,
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Stage de vendedores'
WITH TAG (CAMADA = 'stage', DOMINIO = 'comercial');

-- ============================================================
-- TABELA: CLIENTES
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.CLIENTES (
    ID_CLIENTES INTEGER,
    CLIENTE VARCHAR(255) NOT NULL,
    ENDERECO STRING NOT NULL,
    ID_CONCESSIONARIAS INTEGER NOT NULL,
    DATA_INCLUSAO TIMESTAMP_LTZ,
    DATA_ATUALIZACAO TIMESTAMP_LTZ,
    CARGA_ID STRING,
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Stage de clientes'
WITH TAG (CAMADA = 'stage', DOMINIO = 'comercial');

-- ============================================================
-- TABELA: VENDAS
-- ============================================================
CREATE TABLE IF NOT EXISTS NOVADRIVE.STAGE.VENDAS (
    ID_VENDAS INTEGER,
    ID_VEICULOS INTEGER NOT NULL,
    ID_CONCESSIONARIAS INTEGER NOT NULL,
    ID_VENDEDORES INTEGER NOT NULL,
    ID_CLIENTES INTEGER NOT NULL,
    VALOR_PAGO DECIMAL(10, 2) NOT NULL,
    DATA_VENDA TIMESTAMP_LTZ,
    DATA_INCLUSAO TIMESTAMP_LTZ,
    DATA_ATUALIZACAO TIMESTAMP_LTZ,
    CARGA_ID STRING,
    DATA_CARGA TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
)
COMMENT = 'Stage de vendas'
WITH TAG (CAMADA = 'stage', DOMINIO = 'comercial');
