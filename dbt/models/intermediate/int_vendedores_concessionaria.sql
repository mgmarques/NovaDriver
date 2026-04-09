select
    vnd.id_vendedores,
    vnd.nome_vendedor,
    vnd.id_concessionarias,
    cl.nome_concessionaria
from {{ ref('stg_vendedores') }} as vnd
inner join {{ ref('int_concessionarias_localizacao') }} as cl
    on vnd.id_concessionarias = cl.id_concessionarias
