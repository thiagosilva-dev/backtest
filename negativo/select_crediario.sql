-- ---------------------------------------------------------------------------------------------------------------
-- SELECIONA OS DADOS TRATADOS DE ACORDO COM O LAYOUT SOLICITADO PARA REALIZAÇÃO DE PROCEDIMENTO BACKTEST NEGATIVO
-- --------------------------------------
-- AUTOR: THIAGO SILVA
-- DATA: 05/11/2020
-- VERSÃO: 1.00
-- ---------------------------------------

USE credital_siscred;

SET @DATA_INICIAL := '2014-07-01';
SET @DATA_FINAL := '2014-12-31';

SELECT
    -- codigo de controle interno da compra
	dc.debitoC_numero AS CODIGO,
    -- cpf do comprador
	REPLACE(REPLACE(dc.debitoC_cpf, '.', ''), '-', '') AS CPF,
	-- data de compra
    REPLACE(dc.debitoC_dataconsulta, '-', '') AS DATA,
	-- valor da compra
	CASE WHEN
		(SELECT ROUND(SUM(c.CartaoPar_valorparcela), 2)
			FROM cartao_parcelas c
			WHERE c.CartaoPar_consulta = dc.debitoC_numero
				AND c.CartaoPar_cpf = dc.debitoC_cpf
				AND c.CartaoPar_login = dc.debitoC_login
				AND c.CartaoPar_pago = cp.CartaoPar_pago
				AND c.CartaoPar_pagoAcordo = cp.CartaoPar_pagoAcordo
	 			AND dc.debito_situacao = 2
		) IS NULL THEN 
			ROUND(dc.debitoC_valorcompra)
		ELSE 
			(SELECT ROUND(SUM(c.CartaoPar_valorparcela), 2)
				FROM cartao_parcelas c
				WHERE c.CartaoPar_consulta = dc.debitoC_numero
				AND c.CartaoPar_cpf = dc.debitoC_cpf
				AND c.CartaoPar_login = dc.debitoC_login
				AND c.CartaoPar_pago = cp.CartaoPar_pago
				AND c.CartaoPar_pagoAcordo = cp.CartaoPar_pagoAcordo
 				AND dc.debito_situacao = 2
		) END AS VALOR,
	-- quantidade de parcelas
	CASE 
		WHEN cp.CartaoPar_Totalparcela IS NULL THEN dc.debitoC_max_parcela
		ELSE cp.CartaoPar_Totalparcela
	END AS PARCELAS,
	-- classificação de situação da compra
	CASE     
		-- compra aprovada
		WHEN ((dc.debitoC_numero > 10) AND (dc.debito_situacao = 2)) THEN 'A1'
		-- compra cancelada
		WHEN ((dc.debitoC_numero > 10) AND (dc.debito_situacao = 3)) THEN 'A2'
		-- compra negada
		WHEN ((dc.debitoC_numero IN (5, 4) AND dc.debito_situacao IN (1, 4))) THEN 'R1'
	END AS INDICACAO,
	-- produto ofertado
	(SELECT 'VENDAS A CREDITO') AS PRODUTO,	
	-- classificação de pagamento/inadimplencia
	CASE
		-- analisa compra que nao tenha parcelas cadastradas
		WHEN (SELECT COUNT(c.CartaoPar_id) FROM cartao_parcelas c 
                WHERE c.CartaoPar_consulta = dc.debitoC_numero) < 1 THEN 0		
		-- compra/parcela cancelada
		WHEN cp.CartaoPar_Situacao = -1 THEN 0
		-- pagamento por pacela
		WHEN cp.CartaoPar_pago = -1 AND cp.CartaoPar_dtpagamento <> '0-0-0' THEN 0
		-- pagamento por acordo
		WHEN cp.CartaoPar_pagoAcordo = -1 AND cp.CartaoPar_dtpagamento <> '0-0-0' THEN 0		
		-- pago manualmente (relação de devolvidos)
        WHEN cp.CartaoPar_dtpagamento <> '0-0-0' AND cp.CartaoPar_Situacao = 0 THEN 0
		# WHEN cp.CartaoPar_pagoAcordo = 0 AND cp.CartaoPar_pago = 0 AND cp.CartaoPar_dtpagamento = '0-0-0' THEN 1
        # WHEN cp.CartaoPar_pagoAcordo = 0 AND cp.CartaoPar_pago = 0 AND cp.CartaoPar_dtpagamento = '0-0-0' THEN 1
		-- sem pagamento por parcela (analisa vencimento)
		WHEN cp.CartaoPar_pago = 0 AND cp.CartaoPar_dtpagamento = '0-0-0' THEN
			CASE
				WHEN ((DATEDIFF(NOW(), cp.CartaoPar_datavencimento)) <= 30) THEN 0
				WHEN ((DATEDIFF(NOW(), cp.CartaoPar_datavencimento)) > 30) THEN 1
			END
		-- sem pagamento por acordo (analisa vencimento)
		WHEN cp.CartaoPar_pagoAcordo = 0 AND cp.CartaoPar_dtpagamento = '0-0-0' THEN
			CASE
				WHEN ((DATEDIFF(NOW(), cp.CartaoPar_datavencimento)) <= 30) THEN 0
				WHEN ((DATEDIFF(NOW(), cp.CartaoPar_datavencimento)) > 30) THEN 1
			END		
	END AS PERFORMANCE
FROM debitoscartao dc
	LEFT JOIN cartao_parcelas cp
		ON cp.CartaoPar_consulta = dc.debitoC_numero
			AND cp.CartaoPar_cpf = dc.debitoC_cpf
			AND cp.CartaoPar_login = dc.debitoC_login
			AND cp.CartaoPar_datacadastro = dc.debitoC_dataconsulta
WHERE (dc.debitoC_numero > 10 AND dc.debito_situacao IN(2, 3) OR (dc.debitoC_numero IN (5, 4) AND dc.debito_situacao IN (1, 4)))
	AND LENGTH(dc.debitoC_cpf) <= 14
    AND dc.debitoC_dataconsulta BETWEEN @DATA_INICIAL AND @DATA_FINAL
    # AND dc.debitoC_dataconsulta BETWEEN '2019/07/01' AND '2019/12/31'
GROUP BY
	dc.debitoC_numero,
	dc.debitoC_cpf,
	dc.debitoC_dataconsulta,
	cp.CartaoPar_pago,
	cp.CartaoPar_pagoAcordo
ORDER BY
	dc.debitoC_cpf,
	dc.debitoC_dataconsulta,
	dc.debitoC_datacadastro,
	dc.debitoC_numero