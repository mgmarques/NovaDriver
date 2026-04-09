with vendas_comparacao_preco as (
    select
        f.id_vendas,
        f.valor_venda,
        d.valor_sugerido,
        case
            when f.valor_venda <= d.valor_sugerido and f.valor_venda >= d.valor_sugerido * 0.95 then true
            else false
        end as regra_respeitada
    from {{ ref('fct_vendas') }} f
    join {{ ref('dim_veiculos') }} d on f.id_veiculos = d.veiculo_id
)

select id_vendas, valor_venda, valor_sugerido
from vendas_comparacao_preco
where regra_respeitada = false
