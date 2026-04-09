{{ config(materialized='table') }}
SELECT
    vei.veiculo_id AS id,
    vei.nome_veiculo AS veiculo,
    vei.tipo_veiculo AS tipo,
    vei.valor_sugerido AS valor_sugerido,
    COUNT(v.id_vendas) AS quantidade,
    SUM(v.valor_venda) AS total,
    AVG(v.valor_venda) AS valor_medio
FROM {{ ref('fct_vendas') }} v
JOIN {{ ref('dim_veiculos') }} vei ON v.id_veiculos = vei.veiculo_id
GROUP BY vei.veiculo_id, vei.nome_veiculo, vei.tipo_veiculo, vei.valor_sugerido
ORDER BY quantidade desc