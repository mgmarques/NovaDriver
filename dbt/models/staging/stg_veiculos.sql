select
    id_veiculos,
    nome as nome_veiculo,
    tipo as tipo_veiculo,
    valor::DECIMAL(10,2) as valor,
    data_inclusao,
    COALESCE(data_atualizacao, data_inclusao) as data_atualizacao
from {{ source('stage', 'veiculos') }}
qualify row_number() over (partition by id_veiculos order by data_atualizacao desc nulls last) = 1
