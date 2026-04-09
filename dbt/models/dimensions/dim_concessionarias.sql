select
    id_concessionarias as concessionaria_id,
    nome_concessionaria,
    id_cidades as cidade_id,
    nome_cidade,
    id_estados,
    nome_estado,
    sigla_estado
from {{ ref('int_concessionarias_localizacao') }}
