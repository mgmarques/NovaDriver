# Atividades
Atividade 1: Seleção Simples
Descrição: Liste todos os veículos com tipo 'SUV Compacta' e valor inferior a 30.000,00.

Atividade 2: Junção Simples
Descrição: Exiba o nome dos clientes e o nome das concessionárias onde realizaram suas compras.

Atividade 3: Contagem e Agrupamento
Descrição: Conte quantos vendedores existem em cada concessionária.

Atividade 4: Subconsulta
Descrição: Encontre os veículos mais caros vendidos em cada tipo de veículo.

Atividade 5: Junção Múltipla
Descrição: Liste o nome do cliente, o veículo comprado e o valor pago, para todas as vendas.

Atividade 6: Filtro com Agregação
Descrição: Identifique as concessionárias que venderam mais de 5 veículos.

Atividade 7: Consulta com ORDER BY e LIMIT
Descrição: Liste os três veículos mais caros disponíveis.

Atividade 8: Consulta com Datas
Descrição: Selecione todos os veículos adicionados no último mês.

Atividade 9: Junção Externa
Descrição: Liste todas as cidades e qualquer concessionária nelas, se houver.

Atividade 10: Consulta com Várias Condições
Descrição: Encontre clientes que compraram veículos 'SUV Premium Híbrida' ou veículos com valor acima de 60.000,00.

```sql
SELECT count(*) as total FROM public.vendas;

SELECT COUNT(*) as jt FROM (
	SELECT vd.*, co.concessionaria, cd.cidade
	FROM vendas AS vd 
	INNER JOIN concessionarias AS co
	ON vd.id_concessionarias = co.id_concessionarias
	INNER JOIN cidades as cd on cd.id_cidades = co.id_cidades 
) as sub;


SELECT COUNT(*) as total, co.concessionaria, cd.cidade
FROM vendas AS vd 
INNER JOIN concessionarias AS co
ON vd.id_concessionarias = co.id_concessionarias
INNER JOIN cidades as cd on cd.id_cidades = co.id_cidades
GROUP BY co.concessionaria, cd.cidade
ORDER BY 1 DESC;


-- Liste todos os veículos com tipo 'SUV Compacta' e valor inferior a 30.000,00.
SELECT *
FROM veiculos as vi
WHERE vi.tipo = 'SUV Compacta' 
AND valor < 30000;

-- Exiba o nome dos clientes e o nome das concessionárias onde realizaram suas compras.
SELECT ci.cliente, co.concessionaria
FROM clientes AS ci
INNER JOIN concessionarias AS co
    ON ci.id_concessionarias = co.id_concessionarias;

-- Conte quantos vendedores existem em cada concessionária.
SELECT co.concessionaria, COUNT(*) as vedendores
FROM concessionarias AS co
INNER JOIN vendedores AS ve
    ON co.id_concessionarias = ve.id_concessionarias
group by co.concessionaria
order by 2 desc;

-- Encontre os veículos mais caros vendidos em cada tipo de veículo.
SELECT tipo, MAX(valor) AS valor_maximo
FROM veiculos
GROUP BY tipo;

-- Liste o nome do cliente, o veículo comprado e o valor pago, para todas as vendas.
SELECT ci.cliente, vi.nome as veiculo ,vd.valor_pago
FROM vendas AS vd
INNER JOIN clientes AS ci
    ON vd.id_clientes = ci.id_clientes
INNER JOIN veiculos AS vi
    ON vd.id_veiculos = vi.id_veiculos;

-- Identifique as concessionárias que venderam mais de 5 veículos.
SELECT co.concessionaria, count(*) vendas_unitarias
FROM vendas AS vd
INNER JOIN concessionarias AS co
    ON vd.id_concessionarias = co.id_concessionarias
GROUP BY co.concessionaria
HAVING 	count(*) > 5
ORDER BY 2 DESC;

-- Liste os três veículos mais caros disponíveis.
SELECT nome as veiculo, valor
FROM veiculos
ORDER BY 2 DESC
LIMIT 3;

-- Selecione todos os veículos adicionados no último mês.
SELECT nome, data_inclusao
FROM veiculos
WHERE data_inclusao > CURRENT_TIMESTAMP - INTERVAL '1 month';

-- Liste todas as cidades e qualquer concessionária nelas, se houver.
SELECT ci.cidade, co.concessionaria
FROM cidades as ci
RIGHT JOIN concessionarias as co
ON ci.id_cidades = co.id_cidades
ORDER BY 1, 2;

-- Encontre clientes que compraram veículos 'SUV Premium Híbrida' ou veículos com valor acima de 60.000,00.
SELECT cl.cliente, vi.tipo, vi.nome AS veiculo, vi.valor
FROM vendas AS vd
INNER JOIN clientes AS cl
    ON vd.id_clientes = cl.id_clientes
INNER JOIN veiculos AS vi
    ON vd.id_veiculos = vi.id_veiculos
WHERE vi.tipo = 'SUV Premium Híbrida' OR vi.valor > 60000.00
ORDER BY 1;
```