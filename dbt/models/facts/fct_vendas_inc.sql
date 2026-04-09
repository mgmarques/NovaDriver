{{ config(materialized='incremental', unique_key='venda_id') }}

with vendas as (
    select
        v.id_vendas as venda_id,
        v.id_veiculos as veiculo_id,
        v.id_concessionarias as concessionaria_id,
        v.id_vendedores as vendedor_id,
        v.id_clientes as cliente_id,
        v.valor_venda,
        v.data_venda,
        v.data_inclusao,
        v.data_atualizacao
    from {{ ref('stg_vendas') }} v
    join {{ ref('dim_veiculos') }} vei on v.id_veiculos = vei.veiculo_id
    join {{ ref('dim_concessionarias') }} con on v.id_concessionarias = con.concessionaria_id
    join {{ ref('dim_vendedores') }} ven on v.id_vendedores = ven.vendedor_id
    join {{ ref('dim_clientes') }} cli on v.id_clientes = cli.cliente_id
)

select
    venda_id,
    veiculo_id,
    concessionaria_id,
    vendedor_id,
    cliente_id,
    valor_venda,
    data_venda,
    data_inclusao,
    data_atualizacao
from vendas
{% if is_incremental() %}
    where venda_id > (select max(venda_id) from {{ this }})
{% endif %}
