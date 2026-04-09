select
    id_vendedores as vendedor_id,
    nome_vendedor,
    id_concessionarias as concessionaria_id
from {{ ref('int_vendedores_concessionaria') }}
