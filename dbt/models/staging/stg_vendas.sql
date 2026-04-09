select
    id_vendas,
    id_veiculos,
    id_concessionarias,
    id_vendedores,
    id_clientes,
    valor_pago::DECIMAL(10,2) as valor_venda,
    data_venda,
    data_inclusao,
    COALESCE(data_atualizacao, data_venda) as data_atualizacao
from {{ source('stage', 'vendas') }}
qualify row_number() over (partition by id_vendas order by data_atualizacao desc nulls last) = 1
