-- ---------------------------------------------------------------------------------
-- SELECIONA CONTEUDO DO SELECT TRATADO NA TABELA TEMPORARIA DE BACKTEST POSITIVO
-- --------------------------------------
-- AUTOR: THIAGO SILVA
-- DATA: 05/11/2020
-- VERSÃO: 1.00
-- ---------------------------------------
SELECT
	bnt.CPF,
	bnt.DATA,
	SUM(bnt.VALOR) AS VALOR,
	bnt.PARCELAS,
	bnt.INDICACAO,
	bnt.PRODUTO,
	bnt.PERFORMANCE	
FROM backtest_negativo_temp bnt
WHERE bnt.PERFORMANCE IS NOT NULL
	AND bnt.CPF <> ''
GROUP BY
	bnt.CPF,
	bnt.INDICACAO,
	bnt.PERFORMANCE
ORDER BY	
	bnt.CPF,
	bnt.`DATA`