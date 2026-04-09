select
    id_concessionarias,
    TRIM(concessionaria) as nome_concessionaria,
    id_cidades,
    data_inclusao,
    COALESCE(data_atualizacao, data_inclusao) as data_atualizacao
from {{ source('stage', 'concessionarias') }}
qualify row_number() over (partition by id_concessionarias order by data_atualizacao desc nulls last) = 1
