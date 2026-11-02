/*
  Migration 001 - Evolução: campo Observação no cabeçalho do pedido.

  Aplica-se SOMENTE a bancos criados com a versão anterior do db.sql
  (sem PEDIDO.OBSERVACAO). O database/db.sql atual já contém o esquema
  final; executar esta migration sobre ele falha ("unsuccessful metadata
  update", a coluna já existe) e NÃO deve ser feito. Execute uma única vez.

  isql -user SYSDBA -password <senha> localhost:C:\dados\PEDIDOS.FDB -i database\migrations\001_adicionar_observacao_pedido.sql
*/

SET SQL DIALECT 3;
SET NAMES UTF8;

/* Mesmo limite da tela (TRegrasPedido.TAMANHO_MAXIMO_OBSERVACAO). */
ALTER TABLE PEDIDO ADD OBSERVACAO VARCHAR(200);

COMMIT;
