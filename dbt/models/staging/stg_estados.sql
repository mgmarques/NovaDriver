select
    id_estados,
    UPPER(estado) as estado,
    UPPER(sigla) as sigla,
    data_inclusao,
    COALESCE(data_atualizacao, data_inclusao) as data_atualizacao
from {{ source('stage', 'estados') }}
qualify row_number() over (partition by id_estados order by data_atualizacao desc nulls last) = 1
