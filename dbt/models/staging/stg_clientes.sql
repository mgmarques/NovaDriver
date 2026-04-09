select
    id_clientes,
    INITCAP(cliente) as cliente,
    TRIM(endereco) as endereco,
    id_concessionarias,
    data_inclusao,
    COALESCE(data_atualizacao, data_inclusao) as data_atualizacao
from {{ source('stage', 'clientes') }}
qualify row_number() over (partition by id_clientes order by data_atualizacao desc nulls last) = 1
