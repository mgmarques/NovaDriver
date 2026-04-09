{{ config(materialized='table') }}
SELECT
    ven.vendedor_id AS id,
    ven.nome_vendedor AS vendedor,
    c.nome_concessionaria AS concessionaria,
    COUNT(v.id_vendas) AS quantidade,
    SUM(v.valor_venda) AS total,
    AVG(v.valor_venda) AS valor_medio
FROM {{ ref('fct_vendas') }} v
JOIN {{ ref('dim_vendedores') }} ven ON v.id_vendedores = ven.vendedor_id
JOIN {{ ref('dim_concessionarias') }} c ON ven.concessionaria_id = c.concessionaria_id
GROUP BY ven.vendedor_id, ven.nome_vendedor,  c.nome_concessionaria
ORDER BY total DESC 
