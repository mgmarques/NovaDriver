select
    con.id_concessionarias,
    con.nome_concessionaria,
    cid.id_cidades,
    cid.nome_cidade,
    est.id_estados,
    est.estado as nome_estado,
    est.sigla as sigla_estado
from {{ ref('stg_concessionarias') }} as con
inner join {{ ref('stg_cidades') }} as cid
    on con.id_cidades = cid.id_cidades
inner join {{ ref('stg_estados') }} as est
    on cid.id_estados = est.id_estados
