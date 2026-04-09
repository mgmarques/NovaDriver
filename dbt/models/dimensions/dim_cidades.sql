select
    id_cidades as cidade_id,
    nome_cidade,
    id_estados as estado_id,
    data_inclusao,
    data_atualizacao
from {{ ref('stg_cidades') }}
