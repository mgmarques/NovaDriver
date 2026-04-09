select
    id_cidades,
    cidade as nome_cidade,
    id_estados,
    data_inclusao,
    data_atualizacao
from {{ source('stage', 'cidades') }}
qualify row_number() over (partition by id_cidades order by data_atualizacao desc nulls last) = 1
