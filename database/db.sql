/*
  Pedido de Venda - script do banco de dados (Firebird 2.5 ou superior, dialeto 3)

  Uso (com o banco já criado; ver README.md):
    isql -user SYSDBA -password <senha> localhost:C:\dados\PEDIDOS.FDB -i database\db.sql

  Este arquivo contém o ESQUEMA FINAL. Não execute as migrations de
  database/migrations sobre um banco criado por este script.

  Tamanhos e precisão (espelhados nas constantes de Domain.Regras.pas):
    CLIENTE.NOME             VARCHAR(100)
    CLIENTE.CIDADE           VARCHAR(60)
    CLIENTE.UF               CHAR(2)       - duas letras maiúsculas
    PRODUTO.DESCRICAO        VARCHAR(120)
    PRODUTO.PRECO_VENDA      NUMERIC(9,2)  - 0,00 a 9.999.999,99
    PEDIDO_ITEM.QUANTIDADE   NUMERIC(9,3)  - 0,001 a 999.999,999
    PEDIDO_ITEM.VLR_UNITARIO NUMERIC(9,2)  - 0,01 a 9.999.999,99
    PEDIDO_ITEM.VLR_TOTAL    NUMERIC(18,2) - ROUND(QUANTIDADE * VLR_UNITARIO, 2)
    PEDIDO.VALOR_TOTAL       NUMERIC(18,2) - soma de PEDIDO_ITEM.VLR_TOTAL
    PEDIDO.OBSERVACAO        VARCHAR(200)  - opcional (NULL quando vazia)
*/

SET SQL DIALECT 3;
SET NAMES UTF8;

/* ------------------------------------------------------------------
   Sequência do número do pedido.
   Valores obtidos por NEXT VALUE FOR não são devolvidos em rollback:
   falhas na gravação podem deixar lacunas na numeração (comportamento
   esperado e seguro para concorrência, ao contrário de MAX(...) + 1).
   ------------------------------------------------------------------ */
CREATE SEQUENCE SEQ_PEDIDO_NUMERO;

/* ------------------------------------------------------------------ */
CREATE TABLE CLIENTE (
  CODIGO  INTEGER      NOT NULL,
  NOME    VARCHAR(100) NOT NULL,
  CIDADE  VARCHAR(60)  NOT NULL,
  UF      CHAR(2)      NOT NULL,
  CONSTRAINT PK_CLIENTE PRIMARY KEY (CODIGO),
  CONSTRAINT CK_CLIENTE_CODIGO CHECK (CODIGO > 0),
  CONSTRAINT CK_CLIENTE_UF CHECK (UF SIMILAR TO '[A-Z]{2}')
);

/* ------------------------------------------------------------------ */
CREATE TABLE PRODUTO (
  CODIGO       INTEGER      NOT NULL,
  DESCRICAO    VARCHAR(120) NOT NULL,
  PRECO_VENDA  NUMERIC(9,2) NOT NULL,
  CONSTRAINT PK_PRODUTO PRIMARY KEY (CODIGO),
  CONSTRAINT CK_PRODUTO_CODIGO CHECK (CODIGO > 0),
  CONSTRAINT CK_PRODUTO_PRECO CHECK (PRECO_VENDA >= 0)
);

/* ------------------------------------------------------------------
   Os índices exigidos pelo teste são os próprios índices das FKs:
   o Firebird cria automaticamente um índice para cada FOREIGN KEY.
   USING INDEX apenas dá nome a esse índice; criar outro CREATE INDEX
   sobre as mesmas colunas seria redundante.
   ------------------------------------------------------------------ */
CREATE TABLE PEDIDO (
  NUMERO_PEDIDO   INTEGER       NOT NULL,
  DATA_EMISSAO    DATE          NOT NULL,
  CODIGO_CLIENTE  INTEGER       NOT NULL,
  VALOR_TOTAL     NUMERIC(18,2) NOT NULL,
  OBSERVACAO      VARCHAR(200),
  CONSTRAINT PK_PEDIDO PRIMARY KEY (NUMERO_PEDIDO),
  CONSTRAINT FK_PEDIDO_CLIENTE FOREIGN KEY (CODIGO_CLIENTE)
    REFERENCES CLIENTE (CODIGO)
    USING INDEX IDX_PEDIDO_CODIGO_CLIENTE,
  CONSTRAINT CK_PEDIDO_VALOR_TOTAL CHECK (VALOR_TOTAL > 0)
);

/* ------------------------------------------------------------------
   ID autoincremento por generator + trigger (ver TRG_PEDIDO_ITEM_BI).
   IDENTITY só existe a partir do Firebird 3; esta forma funciona também
   no 2.5.
   ------------------------------------------------------------------ */
CREATE SEQUENCE SEQ_PEDIDO_ITEM_ID;

CREATE TABLE PEDIDO_ITEM (
  ID              INTEGER       NOT NULL,
  NUMERO_PEDIDO   INTEGER       NOT NULL,
  CODIGO_PRODUTO  INTEGER       NOT NULL,
  QUANTIDADE      NUMERIC(9,3)  NOT NULL,
  VLR_UNITARIO    NUMERIC(9,2)  NOT NULL,
  VLR_TOTAL       NUMERIC(18,2) NOT NULL,
  CONSTRAINT PK_PEDIDO_ITEM PRIMARY KEY (ID),
  CONSTRAINT FK_PEDIDO_ITEM_PEDIDO FOREIGN KEY (NUMERO_PEDIDO)
    REFERENCES PEDIDO (NUMERO_PEDIDO)
    USING INDEX IDX_PEDIDO_ITEM_NUMERO_PEDIDO,
  CONSTRAINT FK_PEDIDO_ITEM_PRODUTO FOREIGN KEY (CODIGO_PRODUTO)
    REFERENCES PRODUTO (CODIGO)
    USING INDEX IDX_PEDIDO_ITEM_CODIGO_PRODUTO,
  CONSTRAINT CK_PEDIDO_ITEM_QUANTIDADE CHECK (QUANTIDADE > 0),
  CONSTRAINT CK_PEDIDO_ITEM_VLR_UNITARIO CHECK (VLR_UNITARIO > 0),
  /* Mesma regra da aplicação: arredondamento a 2 casas, metade para cima
     (ROUND do Firebird arredonda .5 afastando de zero). */
  CONSTRAINT CK_PEDIDO_ITEM_VLR_TOTAL
    CHECK (VLR_TOTAL = ROUND(QUANTIDADE * VLR_UNITARIO, 2))
);

SET TERM ^ ;

CREATE TRIGGER TRG_PEDIDO_ITEM_BI FOR PEDIDO_ITEM
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = NEXT VALUE FOR SEQ_PEDIDO_ITEM_ID;
END^

SET TERM ; ^

COMMIT;

/* ------------------------------------------------------------------
   Carga de dados para teste
   ------------------------------------------------------------------ */
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (1, 'Mercado Bom Preço Ltda', 'São Paulo', 'SP');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (2, 'Padaria Pão Dourado', 'Campinas', 'SP');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (3, 'Comercial Andrade & Filhos', 'Belo Horizonte', 'MG');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (4, 'Distribuidora Sul Ltda', 'Porto Alegre', 'RS');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (5, 'Armazém Paraná', 'Curitiba', 'PR');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (6, 'Supermercado Litoral', 'Florianópolis', 'SC');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (7, 'Empório Carioca', 'Rio de Janeiro', 'RJ');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (8, 'Atacadão Nordeste', 'Recife', 'PE');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (9, 'Mercearia Central', 'Goiânia', 'GO');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (10, 'Loja Conveniência Norte', 'Manaus', 'AM');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (11, 'Hortifruti Bahia', 'Salvador', 'BA');
INSERT INTO CLIENTE (CODIGO, NOME, CIDADE, UF) VALUES (12, 'Cooperativa Cerrado', 'Brasília', 'DF');

INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (1, 'Arroz Tipo 1 - 5 kg', 27.90);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (2, 'Feijão Carioca - 1 kg', 8.49);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (3, 'Açúcar Refinado - 1 kg', 4.99);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (4, 'Café Torrado e Moído - 500 g', 18.75);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (5, 'Óleo de Soja - 900 ml', 7.29);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (6, 'Leite Integral UHT - 1 L', 5.35);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (7, 'Farinha de Trigo - 1 kg', 6.10);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (8, 'Macarrão Espaguete - 500 g', 4.25);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (9, 'Queijo Muçarela (kg)', 49.90);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (10, 'Presunto Cozido (kg)', 39.99);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (11, 'Banana Prata (kg)', 6.99);
INSERT INTO PRODUTO (CODIGO, DESCRICAO, PRECO_VENDA) VALUES (12, 'Detergente Líquido - 500 ml', 2.79);

COMMIT;
