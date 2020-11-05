-- ---------------------------------------------------------------------------------
-- CRIAÇÃO DE TABELA TEPORARIA PARA REALIZAÇÃO DE PROCEDIMENTO DE BACKTESTE NEGATIVO
-- --------------------------------------
-- AUTOR: THIAGO SILVA
-- DATA: 05/11/2020
-- VERSÃO: 1.00
-- ---------------------------------------

CREATE TABLE backtest_negativo_temp (
	ID INTEGER AUTO_INCREMENT PRIMARY KEY,
	CODIGO INTEGER NOT NULL,	
	CPF VARCHAR(11) NOT NULL,	
	DATA DATE NOT NULL,	
	VALOR DECIMAL(12,2) DEFAULT 0,	
	PARCELAS SMALLINT DEFAULT 0,
	INDICACAO VARCHAR(2),
	PRODUTO VARCHAR(20) NOT NULL,
	PERFORMANCE TINYINT,
);