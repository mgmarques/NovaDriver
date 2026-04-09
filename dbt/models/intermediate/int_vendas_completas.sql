select
    v.id_vendas,
    v.id_veiculos,
    v.id_concessionarias,
    v.id_vendedores,
    v.id_clientes,
    v.valor_venda,
    v.data_venda,
    ve.nome_veiculo,
    ve.tipo_veiculo,
    ve.valor as valor_veiculo,
    cl.cliente as nome_cliente,
    cl.endereco as endereco_cliente,
    vc.nome_vendedor,
    con.nome_concessionaria,
    con.nome_cidade,
    con.nome_estado,
    con.sigla_estado
from {{ ref('stg_vendas') }} as v
inner join {{ ref('stg_veiculos') }} as ve
    on v.id_veiculos = ve.id_veiculos
inner join {{ ref('stg_clientes') }} as cl
    on v.id_clientes = cl.id_clientes
inner join {{ ref('int_vendedores_concessionaria') }} as vc
    on v.id_vendedores = vc.id_vendedores
inner join {{ ref('int_concessionarias_localizacao') }} as con
    on v.id_concessionarias = con.id_concessionarias
