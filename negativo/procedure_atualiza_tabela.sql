-- ---------------------------------------------------------------------------------
-- INSERE CONTEUDO DO SELECT TRATADO NA TABELA DE BACKTEST NEGATIVO
-- --------------------------------------
-- AUTOR: THIAGO SILVA
-- DATA: 05/11/2020
-- VERSÃO: 1.00
-- ---------------------------------------
USE credital_siscred;

DELIMITER //
CREATE PROCEDURE atualiza_tabela(IN data_inicial DATE, data_final DATE)
BEGIN
    DELETE FROM backtest_negativo_temp;
    INSERT INTO backtest_negativo_temp (
        CODIGO,
	    CPF,
	    DATA,
	    VALOR,
	    PARCELAS,
	    INDICACAO,
	    PRODUTO,
	    PERFORMANCE
    )
    (
        SELECT    
	        dc.debitoC_numero AS CODIGO,    
    	    REPLACE(REPLACE(dc.debitoC_cpf, '.', ''), '-', '') AS CPF,
            REPLACE(dc.debitoC_dataconsulta, '-', '') AS DATA,
	        CASE WHEN
    		    (SELECT ROUND(SUM(c.CartaoPar_valorparcela), 2)
			        FROM cartao_parcelas c
			        WHERE c.CartaoPar_consulta = dc.debitoC_numero
    				    AND c.CartaoPar_cpf = dc.debitoC_cpf
				        AND c.CartaoPar_login = dc.debitoC_login
				        AND c.CartaoPar_pago = cp.CartaoPar_pago
				        AND c.CartaoPar_pagoAcordo = cp.CartaoPar_pagoAcordo
	 			        AND dc.debito_situacao = 2
		        ) IS NULL THEN ROUND(dc.debitoC_valorcompra)
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
	        CASE
		        WHEN cp.CartaoPar_Totalparcela IS NULL THEN dc.debitoC_max_parcela
		        ELSE cp.CartaoPar_Totalparcela
	        END AS PARCELAS,
        	CASE
		        WHEN ((dc.debitoC_numero > 10) AND (dc.debito_situacao = 2)) THEN 'A1'
		        WHEN ((dc.debitoC_numero > 10) AND (dc.debito_situacao = 3)) THEN 'A2'
        		WHEN ((dc.debitoC_numero IN (5, 4) AND dc.debito_situacao IN (1, 4))) THEN 'R1'
	        END AS INDICACAO,
        	(SELECT 'VENDAS A CREDITO') AS PRODUTO,	
	        CASE
        		WHEN (SELECT COUNT(c.CartaoPar_id) FROM cartao_parcelas c WHERE c.CartaoPar_consulta = dc.debitoC_numero) < 1 THEN 0
        		WHEN cp.CartaoPar_Situacao = -1 THEN 0		
		        WHEN cp.CartaoPar_pago = -1 AND cp.CartaoPar_dtpagamento <> '0-0-0' THEN 0
		        WHEN cp.CartaoPar_pagoAcordo = -1 AND cp.CartaoPar_dtpagamento <> '0-0-0' THEN 0		
                WHEN cp.CartaoPar_dtpagamento <> '0-0-0' AND cp.CartaoPar_Situacao = 0 THEN 0
		        WHEN cp.CartaoPar_pago = 0 AND cp.CartaoPar_dtpagamento = '0-0-0' THEN
			        CASE
                        WHEN ((DATEDIFF(NOW(), cp.CartaoPar_datavencimento)) <= 30) THEN 0
				        WHEN ((DATEDIFF(NOW(), cp.CartaoPar_datavencimento)) > 30) THEN 1
			        END
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
            AND dc.debitoC_dataconsulta BETWEEN @periodo_inicial AND @periodo_final
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
    )
END; //
DELIMITER ;

SET @periodo_inicial = '2014-01-01';
SET @periodo_final = '2014-06-30';

CALL atualiza_tabela(@periodo_inicial, @periodo_final);
