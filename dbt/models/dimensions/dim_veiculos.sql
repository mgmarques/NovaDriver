select
    id_veiculos as veiculo_id,
    nome_veiculo,
    tipo_veiculo,
    valor as valor_sugerido,
    data_inclusao,
    data_atualizacao
from {{ ref('stg_veiculos') }}
