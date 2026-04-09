select
    id_clientes as cliente_id,
    cliente as nome_cliente,
    endereco,
    id_concessionarias as concessionaria_id,
    data_inclusao,
    data_atualizacao
from {{ ref('stg_clientes') }}
