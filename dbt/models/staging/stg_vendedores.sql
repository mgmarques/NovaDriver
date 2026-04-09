select
    id_vendedores,
    INITCAP(nome) as nome_vendedor,
    id_concessionarias,
    data_inclusao,
    COALESCE(data_atualizacao, data_inclusao) as data_atualizacao
from {{ source('stage', 'vendedores') }}
qualify row_number() over (partition by id_vendedores order by data_atualizacao desc nulls last) = 1
