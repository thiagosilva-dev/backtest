-- ---------------------------------------------------------------------------------------------------------------
-- SELECIONA OS DADOS TRATADOS DE ACORDO COM O LAYOUT SOLICITADO PARA REALIZAÇÃO DE PROCEDIMENTO BACKTEST DE RENDA
-- --------------------------------------
-- AUTOR: THIAGO SILVA
-- DATA: 05/11/2020
-- VERSÃO: 1.00
-- ---------------------------------------
SELECT
	REPLACE(REPLACE(cb.consulta_cpf, '.', ''), '-', '') AS CPF,
	REPLACE(cb.consulta_data, '-', '') AS 'DATA',
	(SELECT SUM(ROUND(EXTRACTVALUE(cb.consulta_string, '//RENDA_ESTIMADA'), 2))) AS RENDA

FROM consultas_base cb

WHERE cb.consulta_tipo = 7
	AND (SELECT EXTRACTVALUE(cb.consulta_string, '//RENDA_ESTIMADA')) > 0
 	AND cb.consulta_data BETWEEN '2020-01-01' AND '2020-01-31'

GROUP BY
	cb.consulta_cpf
ORDER BY
	cb.consulta_data,
	cb.consulta_cpf