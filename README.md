# Pedido de Venda — Delphi VCL + FireDAC + Firebird

Aplicação desktop para digitação e gravação de pedidos de venda, desenvolvida para o
teste técnico "Analista Desenvolvedor Delphi".

- Tela única: consulta de cliente e de produto, inclusão/edição/exclusão de itens pelo
  teclado, total no rodapé e gravação transacional.
- Manutenção pedida no teste: campo **Observação** (evolução) e **recálculo do total ao
  excluir com DEL** (correção). Os dois aparecem em commits próprios.
- Bônus: carregar, atualizar e cancelar pedido; testes DUnitX.

## Sumário

1. [Versões e pré-requisitos](#1-versões-e-pré-requisitos)
2. [Requisitos do teste x decisões de implementação](#2-requisitos-do-teste-x-decisões-de-implementação)
3. [Organização das camadas](#3-organização-das-camadas)
4. [Banco de dados](#4-banco-de-dados)
5. [Configuração da conexão (config.ini)](#5-configuração-da-conexão-configini)
6. [Compilação e execução](#6-compilação-e-execução)
7. [Distribuição do cliente Firebird](#7-distribuição-do-cliente-firebird)
8. [Regras de cálculo e arredondamento](#8-regras-de-cálculo-e-arredondamento)
9. [Gravação e transações](#9-gravação-e-transações)
10. [Uso da tela](#10-uso-da-tela)
11. [Testes automatizados](#11-testes-automatizados)
12. [Roteiro de testes manuais](#12-roteiro-de-testes-manuais)
13. [Verificações e limitações](#13-verificações-e-limitações)
14. [Histórico de commits](#14-histórico-de-commits)

---

## 1. Versões e pré-requisitos

Não havia projeto base indicando versões. Por isso adotei:

| Item | Versão adotada |
|---|---|
| IDE / compilador | Delphi 10.3 Rio (VCL, FireDAC, DUnitX incluídos) |
| Plataforma | Win32 |
| Banco | Firebird 2.5 (testado no 2.5.6), dialeto 3, charset UTF8 |
| Componentes | Somente nativos (VCL, FireDAC). Sem ORM ou bibliotecas de terceiros |

O código não usa variáveis inline nem outros recursos posteriores ao 10.3.

Pré-requisitos para executar:

- Servidor Firebird 2.5 instalado e em execução (porta padrão 3050). Para o 3.0, ver seção 7.
- `bin\fbclient.dll` **32 bits**, já incluído no repositório (ver seção 7).

## 2. Requisitos do teste x decisões de implementação

**Requisitos do PDF**

- Cliente: código informado pelo operador, com nome/cidade/UF somente leitura. Cliente
  inexistente é validado.
- Item: código do produto, quantidade e valor unitário (sugerido pelo preço de venda e
  editável). A descrição é somente leitura. Botão "Inserir/Atualizar Item".
- Grade com Cód. Produto, Descrição, Quantidade, Vlr. Unitário e Vlr. Total. Produtos
  repetidos ficam em linhas distintas.
- Na grade: ENTER carrega o item para edição (confirmação no mesmo botão) e DEL exclui
  com confirmação.
- Total do pedido no rodapé.
- "Gravar Pedido" grava cabeçalho e itens com transação (commit/rollback) e tratamento de erros.
- Tabelas CLIENTE, PRODUTO, PEDIDO e PEDIDO_ITEM. Número do pedido por sequence, ID do item
  autoincremento, FKs e índices em PEDIDO(CODIGO_CLIENTE), PEDIDO_ITEM(NUMERO_PEDIDO) e
  (opcional) PEDIDO_ITEM(CODIGO_PRODUTO).
- Carga com 10 ou mais clientes e produtos.
- Evolução: PEDIDO.OBSERVACAO. Correção: total recalculado imediatamente ao excluir com DEL.
- Conexão configurada dinamicamente pelo `config.ini` (Database, Username, Password, Server,
  Port, ClientLibrary). Queries parametrizadas. `fbclient.dll` distribuído em `bin\`.
- Entregáveis: código-fonte, `db.sql`, `config.ini.example` e README.

**Decisões de implementação** (não exigidas pelo PDF)

- Arquitetura MVC com Services e Repositories, interfaces e composição por construtor em
  um único ponto (`TCompositionRoot`).
- Valor unitário deve ser **maior que zero** (premissa de negócio). O banco aceita
  `PRECO_VENDA = 0` no cadastro, mas o item exige valor positivo.
- Quantidade com até 3 casas decimais, valores com 2 casas e arredondamento "metade para
  cima" (seção 8).
- Observação: `VARCHAR(200)`, opcional e gravada como NULL quando vazia.
- A data de emissão é a data do sistema na criação do pedido e é preservada nas
  atualizações.
- Depois de gravar com sucesso, a tela inicia automaticamente um novo pedido vazio.
- Gravação bloqueada enquanto houver item em edição não confirmado.
- `PEDIDO_ITEM.ID` usa generator + trigger, porque `IDENTITY` não existe no Firebird 2.5. O número
  do pedido usa `SEQUENCE`.
- Atualização de pedido carregado (bônus): o cabeçalho é atualizado e os itens são
  excluídos e reinseridos na mesma transação.

## 3. Organização das camadas

```
PedidoVenda.dpr / .dproj          Programa principal (Win32)
src/
  App.CompositionRoot.pas         Composição das dependências e ownership
  Domain/
    Entities/                     TCliente, TProduto, TPedido, TPedidoItem, TRegrasPedido
    Exceptions/                   EValidacaoException, ERegistroNaoEncontradoException
    Interfaces/                   IClienteRepository, IProdutoRepository,
                                  IPedidoRepository, IPedidoItemRepository, ITransacao
  Application/
    Services/                     IConsultaCadastroService, IPedidoService e implementações
  Infrastructure/
    Infra.Exceptions.pas          EInfraestruturaException, EConfiguracaoException,
                                  EConexaoBancoException
    Configuration/                Leitura e validação do config.ini
    Database/                     TConexaoFirebird (FireDAC) e TTransacaoFireDAC
    Repositories/                 Repositórios FireDAC (SQL parametrizado)
  Presentation/
    Controllers/                  TPedidoVendaController (estado da tela, sem VCL)
    Views/                        TfrmPedidoVenda (.pas/.dfm), conversão de entrada
database/
  db.sql                          Esquema final + carga de dados
  migrations/001_...sql           Adiciona OBSERVACAO a bancos do esquema anterior
tests/                            Projeto DUnitX separado (PedidoVendaTests.dpr)
bin/                              fbclient.dll 32 bits distribuído com a aplicação
config.ini.example
```

Responsabilidades e dependências:

- **Domain** não depende de VCL, FireDAC nem INI. Concentra as regras: validação do item,
  cálculo do total do item e do pedido, limites, identidade local do item e validação para
  gravação.
- **Application** coordena os casos de uso e depende só das interfaces do domínio.
  `TPedidoService` é **o único responsável pela transação**.
- **Infrastructure** contém a configuração, a conexão FireDAC, os SQL e a implementação de
  `ITransacao`. Os repositórios não fazem commit.
- **Presentation**: o controller guarda o estado da tela (pedido em digitação, cliente
  validado, produto consultado, item em edição) e chama os serviços. O formulário lê os
  campos, mostra o estado e pede confirmações. Os eventos dos botões não têm SQL, regra de
  negócio nem controle de transação.

Ownership:

- `TCompositionRoot` é dono de `TConexaoFirebird` e do controller. No destrutor, libera o
  controller primeiro e a conexão depois.
- Repositórios, transação e serviços são usados **somente por interface** (contagem de
  referência) e nunca são liberados manualmente.
- `TPedido` é dono dos itens (`TObjectList`). Entidades retornadas por repositórios e
  serviços pertencem a quem as recebe.
- O formulário não é dono do controller. O `.dpr` libera o formulário antes do
  `TCompositionRoot`.

## 4. Banco de dados

### Criação

1. Crie o banco (exemplo com o `isql` do Firebird, como SYSDBA ou outro usuário com permissão):

   ```
   isql -user SYSDBA -password <senha>
   SQL> CREATE DATABASE 'localhost:C:\dados\PEDIDOS.FDB' PAGE_SIZE 8192 DEFAULT CHARACTER SET UTF8;
   SQL> EXIT;
   ```

2. Execute o script:

   ```
   isql -user SYSDBA -password <senha> localhost:C:\dados\PEDIDOS.FDB -i database\db.sql
   ```

O `db.sql` cria o **esquema final**, já com `PEDIDO.OBSERVACAO`. A migration
`database/migrations/001_adicionar_observacao_pedido.sql` serve apenas para bancos criados
com a versão anterior do script, sem a observação. **Não a execute sobre um banco criado
pelo `db.sql` atual**: ela falha porque a coluna já existe. Execute-a uma única vez.

### Estrutura, tamanhos e precisão

| Tabela.Coluna | Tipo | Regras |
|---|---|---|
| CLIENTE.CODIGO | INTEGER | PK, > 0 |
| CLIENTE.NOME | VARCHAR(100) | NOT NULL |
| CLIENTE.CIDADE | VARCHAR(60) | NOT NULL |
| CLIENTE.UF | CHAR(2) | NOT NULL, duas letras maiúsculas |
| PRODUTO.CODIGO | INTEGER | PK, > 0 |
| PRODUTO.DESCRICAO | VARCHAR(120) | NOT NULL |
| PRODUTO.PRECO_VENDA | NUMERIC(9,2) | NOT NULL, >= 0 |
| PEDIDO.NUMERO_PEDIDO | INTEGER | PK, valor de `SEQ_PEDIDO_NUMERO` |
| PEDIDO.DATA_EMISSAO | DATE | NOT NULL |
| PEDIDO.CODIGO_CLIENTE | INTEGER | NOT NULL, FK → CLIENTE |
| PEDIDO.VALOR_TOTAL | NUMERIC(18,2) | NOT NULL, > 0 |
| PEDIDO.OBSERVACAO | VARCHAR(200) | opcional |
| PEDIDO_ITEM.ID | INTEGER | PK, autoincremento por `SEQ_PEDIDO_ITEM_ID` + `TRG_PEDIDO_ITEM_BI` |
| PEDIDO_ITEM.NUMERO_PEDIDO | INTEGER | NOT NULL, FK → PEDIDO |
| PEDIDO_ITEM.CODIGO_PRODUTO | INTEGER | NOT NULL, FK → PRODUTO |
| PEDIDO_ITEM.QUANTIDADE | NUMERIC(9,3) | NOT NULL, > 0 (máx. 999.999,999) |
| PEDIDO_ITEM.VLR_UNITARIO | NUMERIC(9,2) | NOT NULL, > 0 (máx. 9.999.999,99) |
| PEDIDO_ITEM.VLR_TOTAL | NUMERIC(18,2) | NOT NULL, = `ROUND(QUANTIDADE * VLR_UNITARIO, 2)` |

### Índices

O Firebird cria automaticamente um índice para cada PK e FK. Os índices pedidos no teste
são os índices das FKs, nomeados com `USING INDEX`:

- `IDX_PEDIDO_CODIGO_CLIENTE` em PEDIDO(CODIGO_CLIENTE)
- `IDX_PEDIDO_ITEM_NUMERO_PEDIDO` em PEDIDO_ITEM(NUMERO_PEDIDO)
- `IDX_PEDIDO_ITEM_CODIGO_PRODUTO` em PEDIDO_ITEM(CODIGO_PRODUTO), o opcional

Não há `CREATE INDEX` adicional, porque seria redundante com esses índices. Para conferir:

```sql
SELECT RDB$INDEX_NAME, RDB$RELATION_NAME FROM RDB$INDICES WHERE RDB$SYSTEM_FLAG = 0;
```

### Numeração e lacunas

O número do pedido vem de `NEXT VALUE FOR SEQ_PEDIDO_NUMERO`, obtido dentro da transação
de gravação. A sequence é segura para concorrência, ao contrário de `SELECT MAX(...) + 1`.
Um valor consumido **não volta em rollback**, então falhas na gravação deixam
**lacunas na numeração**. Esse comportamento é esperado.

### Carga de dados

O script insere 12 clientes (códigos 1 a 12) e 12 produtos (códigos 1 a 12).

## 5. Configuração da conexão (config.ini)

Modelo (`config.ini.example`):

```ini
[Database]
Database=CAMINHO_DO_BANCO
Username=USUARIO_EXEMPLO
Password=SENHA_EXEMPLO
Server=localhost
Port=3050
ClientLibrary=bin\fbclient.dll
```

Como a aplicação usa o arquivo:

- `config.ini` é procurado **somente na pasta do executável** (`ParamStr(0)`), nunca no
  diretório de trabalho atual.
- O projeto gera `PedidoVenda.exe` **na raiz do repositório** (`DCC_ExeOutput=.\`). Assim:
  - **Pela IDE**: copie `config.ini.example` para `config.ini` na raiz do projeto, ao lado
    de `PedidoVenda.dproj`. É também o local pedido no teste.
  - **Fora da IDE / distribuição**: `config.ini` fica na mesma pasta de `PedidoVenda.exe`.
- Caminhos relativos são resolvidos a partir da pasta do executável:
  - `ClientLibrary=bin\fbclient.dll` aponta para `<pasta do exe>\bin\fbclient.dll`.
  - `Database` terminado em `.fdb` e relativo também é resolvido a partir dessa pasta.
    Valores sem extensão `.fdb` são tratados como **alias** do `databases.conf` do servidor
    e enviados sem alteração. Caminhos absolutos são usados como estão. Lembre que o
    caminho do banco é interpretado pelo servidor Firebird.
- Validações, cada uma com mensagem que indica o arquivo e a chave:
  - arquivo ausente;
  - seção `[Database]` ausente;
  - chave vazia (todas são obrigatórias);
  - `Port` fora de 1–65535;
  - `ClientLibrary` inexistente.
- Falha de conexão mostra servidor, porta e banco, além do erro do FireDAC. A **senha
  nunca é exibida nem registrada**.
- A conexão é configurada em tempo de execução: `TFDPhysFBDriverLink.VendorLib =
  ClientLibrary` e os parâmetros do `TFDConnection` (DriverID=FB, Protocol=TCPIP,
  CharacterSet=UTF8).

`config.ini` e bancos (`*.fdb`) estão no `.gitignore`.

## 6. Compilação e execução

1. Abra `PedidoVenda.dproj` no Delphi 10.3. Se a IDE recusar o `.dproj`, abra o
   `PedidoVenda.dpr`: as units estão referenciadas com caminho no `uses ... in`.
2. Selecione a plataforma **Win32** (Debug ou Release) e compile (Shift+F9).
3. Garanta `config.ini` e `bin\fbclient.dll` (32 bits) na raiz do projeto e execute (F9).

Linha de comando (prompt do RAD Studio):

```
msbuild PedidoVenda.dproj /p:Config=Release /p:Platform=Win32
```

Observações:

- As DCUs vão para `dcu\<Plataforma>\<Config>`.
- O `.dpr` não declara `{$R *.res}`, porque arquivos `.res` são binários e não são
  versionados. Para ícone ou informações de versão, adicione a diretiva: a IDE gera o `.res`.
- Em Debug, `ReportMemoryLeaksOnShutdown` fica ativo quando a aplicação roda pela IDE.

## 7. Distribuição do cliente Firebird

O `fbclient.dll` precisa ter a **mesma arquitetura do executável**, não a do servidor.
Como o executável é **Win32**, use sempre uma DLL **32 bits**, mesmo com servidor 64 bits. Uma
DLL de arquitetura diferente causa erro ao carregar a biblioteca cliente na conexão.

O repositório inclui `bin\fbclient.dll` **2.5.2 (32 bits)**, como pede o teste.

- Essa DLL depende do runtime do Visual C++ 2005 x86 (`MSVCR80.dll`). Se ele não estiver instalado,
  instale o runtime ou copie o `fbclient.dll` e os arquivos `msvcr80.dll`, `msvcp80.dll` e
  `Microsoft.VC80.CRT.manifest` do kit Win32 do Firebird 2.5 para `bin\`.
- Para servidor Firebird 3.0, troque a DLL pelo `fbclient.dll` 32 bits do kit Win32 do 3.0, junto
  com `msvcp100.dll` e `msvcr100.dll`, ou use o da pasta `WOW64` da instalação 64 bits. Na
  configuração padrão, o 3.0 não aceita a autenticação de um cliente 2.5.

Estrutura de distribuição:

```
PedidoVenda.exe
config.ini
bin\fbclient.dll
```

O FireDAC é compilado no executável e não exige outras DLLs.

## 8. Regras de cálculo e arredondamento

As regras ficam centralizadas em `TRegrasPedido` (`src/Domain/Entities/Domain.Regras.pas`):

- **Total do item** = Quantidade × Valor unitário, arredondado para **2 casas, metade para
  cima** (0,005 → 0,01).
- **Total do pedido** = soma dos totais dos itens já arredondados, sem novo
  arredondamento. Exemplo: dois itens de 1,5 × 0,05 totalizam 0,08 + 0,08 = 0,16.
- **Precisão**: quantidade com até **3** casas (NUMERIC(9,3)); valor unitário e totais com
  **2** casas.
- **Tipos**: `Currency` na aplicação. O cálculo usa aritmética inteira (milésimos ×
  centavos) e não depende de ponto flutuante. Com os limites adotados, o produto cabe em
  `Int64`.
- **Mesma regra no banco**: o `ROUND(x, 2)` do Firebird também arredonda a metade para cima.
  O `CHECK CK_PEDIDO_ITEM_VLR_TOTAL` rejeita um item cujo total não siga a regra.
- **Limites** compatíveis com o banco: quantidade 0,001–999.999,999; valor unitário
  0,01–9.999.999,99; total do pedido até 99.999.999.999.999,99.
- Os totais são calculados a partir das entidades, nunca do texto formatado dos controles.
  A grade e o rodapé são reconstruídos do pedido a cada inclusão, alteração ou exclusão.
- Entrada e exibição usam a configuração regional do Windows (`FormatSettings`). Valores
  colocados nos campos para edição saem sem separador de milhar, para serem lidos de volta
  sem ambiguidade.

## 9. Gravação e transações

`TPedidoService.GravarPedido`:

1. Revalida o pedido em memória: cliente, ao menos um item, regras de cada item, tamanho da
   observação e total recalculado. Também confere no banco se o cliente existe.
2. Inicia a transação (`ITransacao.Iniciar`).
3. Pedido novo: obtém o número pela sequence, insere o cabeçalho e insere os itens com
   **uma única query preparada**, trocando apenas os parâmetros.
   Pedido carregado (bônus): `UPDATE` do cabeçalho, exclusão e reinserção dos itens.
4. Faz commit. Em qualquer falha faz **rollback** e repassa a exceção.
5. O número só é atribuído ao pedido **depois do commit**. Em seguida, o controller inicia
   um novo pedido e a tela informa o número gravado.

Todos os repositórios e a transação usam o mesmo `TFDConnection`. Em caso de erro, a tela
mantém cliente, itens e observação para correção e nova tentativa.

Gravações duplicadas são evitadas assim: o botão fica desabilitado durante a gravação, o
controller tem proteção contra reentrada e, após o sucesso, o pedido em tela é substituído
por um novo vazio. Um clique repetido encontra o pedido sem cliente e sem itens e é
rejeitado pela validação.

## 10. Uso da tela

- **Cliente**: digite o código e tecle ENTER ou TAB. Alterar o código invalida o cliente
  exibido.
- **Item**: digite o código do produto e tecle ENTER. A descrição e o valor unitário
  (preço de venda) são preenchidos. Informe a quantidade, ajuste o valor se quiser e clique
  em **Inserir/Atualizar Item**. Os campos são limpos para a próxima inclusão.
- **Grade**: ENTER carrega o item selecionado para edição, preservando quantidade e valor.
  Confirme no mesmo botão ou use **Cancelar Edição**. DEL pede confirmação e exclui somente
  a linha selecionada.
- **Gravar Pedido**: grava e inicia um novo pedido.
- **Bônus**: informe o número em "Nº Pedido" e clique em **Carregar Pedido** (ou tecle
  ENTER). **Novo Pedido** descarta o pedido atual, com confirmação se houver alterações.
  **Cancelar Pedido** exclui definitivamente o pedido carregado.

Cada item tem um Id próprio em memória, atribuído pelo `TPedido`. Ele não depende da
posição na grade, do código do produto ou do ID do banco. Por isso produtos repetidos são
editados e excluídos de forma independente.

## 11. Testes automatizados

Projeto separado: `tests/PedidoVendaTests.dproj` (DUnitX, console). Ele não usa Forms nem
banco: repositórios e transação são substituídos por implementações em memória
(`tests/Tests.Fakes.pas`). Os testes cobrem:

- cálculo do item e arredondamento, incluindo quantidade fracionária e limites;
- validações de quantidade e valor;
- produtos repetidos, alteração e exclusão independentes, exclusão do último item;
- gravação com commit, rollback em falha no 2º item, número atribuído só após o commit,
  lacuna na sequência e observação;
- controller: sugestão de preço em edição, gravação sem cliente, com item em edição,
  repetida e após falha, exclusão do item em edição;
- bônus: carregar com produtos repetidos, pedido inexistente, atualização e cancelamento.

Execução: abra `tests\PedidoVendaTests.dproj`, compile em Win32 e execute
`tests\bin\PedidoVendaTests.exe`. A dependência é o DUnitX distribuído com o Delphi 10.3.
O `.dproj` procura em `$(DUnitX)` e em `$(BDS)\source\DUnitX`.

## 12. Roteiro de testes manuais

Pré-condição: banco criado com `db.sql`, `config.ini` válido e aplicação aberta.
Consultas de conferência no `isql` estão indicadas onde se aplicam.

| # | Cenário | Passos | Resultado esperado |
|---|---|---|---|
| 1 | Cliente existente | Código 1 + ENTER | Nome, cidade e UF preenchidos (somente leitura) |
| 2 | Cliente inexistente | Código 999 + ENTER | Aviso "Cliente 999 não encontrado"; nome/cidade/UF vazios |
| 3 | Troca de cliente | Após o cenário 1, alterar o código para 99 sem sair do campo | Dados do cliente 1 somem; gravar exige nova consulta |
| 4 | Produto existente | Produto 1 + ENTER | Descrição e Vlr. Unitário 27,90 preenchidos e editáveis |
| 5 | Produto inexistente | Produto 999 + ENTER | Aviso; descrição vazia; Inserir não inclui item |
| 6 | Quantidade inválida | Quantidade 0, -1, "abc" ou 1,2345 | Aviso específico; nada incluído |
| 7 | Valor inválido | Valor 0, "x" ou 1,234 | Aviso específico; nada incluído |
| 8 | Limites | Quantidade 1000000 ou valor 10000000 | Aviso de limite máximo |
| 9 | Produtos repetidos | Incluir produto 1 com qtd 2 e depois produto 1 com qtd 3 | Duas linhas distintas; total 139,50 |
| 10 | Edição independente | Selecionar a 2ª linha do cenário 9, ENTER, qtd 5, Inserir/Atualizar | Somente a 2ª linha muda (qtd 5); a 1ª continua com 2; total 195,30 |
| 11 | Preço preservado na edição | Incluir produto 1 com valor 20,00; ENTER na linha; sair do código do produto | Valor 20,00 mantido (não volta para 27,90) |
| 12 | Exclusão cancelada | Selecionar linha, DEL, responder "Não" | Nada muda |
| 13 | Exclusão confirmada | Selecionar linha, DEL, "Sim" | Somente aquela linha sai; **total atualizado na hora** |
| 14 | Exclusão do último item | Excluir todas as linhas | Grade vazia e total R$ 0,00 |
| 15 | Exclusão do item em edição | ENTER numa linha e DEL na mesma linha | Linha removida, campos do item limpos, "Novo item" |
| 16 | ENTER/DEL sem seleção | Grade vazia, ENTER e DEL | Nenhuma ação, nenhuma mensagem |
| 17 | Arredondamento fracionário | Produto 9, qtd 2,345, valor 49,90 | Vlr. Total 117,02 (117,0155 arredondado) |
| 18 | Arredondamento na metade | Qtd 1,5, valor 0,05 | Vlr. Total 0,08 |
| 19 | Gravação completa | Cliente 1, 2 itens, observação "Entregar pela manhã", Gravar | Mensagem "Pedido nº N gravado"; tela limpa. `SELECT * FROM PEDIDO WHERE NUMERO_PEDIDO = N` e `SELECT * FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = N` conferem cabeçalho, observação, itens e totais |
| 20 | Gravação sem cliente/itens | Gravar sem cliente ou sem itens | Aviso; nada gravado |
| 21 | Observação no limite | Digitar mais de 200 caracteres | Campo limita a 200 |
| 22 | Falha nos itens com rollback | No isql: `INSERT INTO PRODUTO VALUES (99, 'Teste rollback', 1.00); COMMIT;`. Na tela: cliente 1, item produto 1, item produto 99. No isql: `DELETE FROM PRODUTO WHERE CODIGO = 99; COMMIT;`. Gravar | Erro de FK no 2º item; nenhum PEDIDO nem PEDIDO_ITEM novo (conferir no isql); o número consumido gera lacuna no próximo pedido |
| 23 | Dados preservados após falha | Após o cenário 22 | Cliente, itens e observação continuam na tela; excluir o item 99 e gravar de novo funciona |
| 24 | Gravação repetida | Clicar várias vezes rapidamente em Gravar | Apenas um pedido gravado; cliques seguintes avisam que falta cliente |
| 25 | Config ausente | Renomear `config.ini` e abrir | Mensagem com o caminho esperado e instrução de copiar o exemplo; aplicação não abre |
| 26 | Config inválida | `Port=abc`, chave vazia ou `ClientLibrary` inexistente | Mensagem indicando a chave/arquivo; senha não aparece |
| 27 | Banco inacessível | Serviço Firebird parado ou `Database` errado | Mensagem de conexão com servidor/porta/banco e detalhe do FireDAC, sem a senha |
| 28 | DLL de arquitetura errada | `ClientLibrary` apontando para um fbclient.dll 64 bits | Erro de carregamento da biblioteca cliente na conexão |
| B1 | Carregar pedido | Nº de um pedido gravado + Carregar Pedido | Cliente, observação e itens (repetidos em linhas próprias) exibidos; situação "Pedido nº N carregado" |
| B2 | Carregar inexistente | Nº 99999 + Carregar | Aviso "Pedido 99999 não encontrado"; pedido atual mantido |
| B3 | Descarte de alterações | Com itens não gravados, Carregar ou Novo Pedido | Pergunta de confirmação; "Não" mantém a tela |
| B4 | Atualizar carregado | Carregar, alterar item e observação, Gravar | "Pedido nº N atualizado"; mesmo número; itens sem duplicação (`SELECT COUNT(*) FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = N`) |
| B5 | Cancelar pedido | Carregar, Cancelar Pedido, "Sim" | Pedido e itens excluídos do banco; tela com novo pedido |
| B6 | Cancelar com recusa | Cancelar Pedido, "Não" | Nada muda |

## 13. Verificações e limitações

Verificações feitas no Windows com Delphi 10.3 e Firebird 2.5.6:

- Aplicação e testes compilados e executados pelo Delphi 10.3, em Win32/Debug.
- Testes DUnitX: 57 de 57 aprovados, sem vazamentos.
- `database/db.sql` executado em um banco novo: 12 clientes, 12 produtos e índices conferidos.
- Fluxo real pelo controller e pelos repositórios FireDAC contra esse banco, usando
  `bin\fbclient.dll`: consulta com acentos, gravação com produto repetido e quantidade fracionária,
  carga, atualização, observação nula, cancelamento, rollback por FK com dados preservados e
  lacuna na sequence.
- A tela abre conectada ao banco e fecha normalmente.

Limitações conhecidas:

- Atualização de pedido carregado: em edições concorrentes do mesmo pedido, prevalece a
  última gravação. Uma gravação simultânea gera conflito de lock no Firebird, tratado com
  rollback e mensagem de erro.
- Itens de um pedido atualizado recebem novos IDs no banco, porque são excluídos e
  reinseridos.
- Não há cadastro de clientes e produtos (fora do escopo, conforme o teste).

## 14. Histórico de commits

Os commits foram feitos conforme cada etapa foi concluída:

1. Estrutura inicial, script do banco e exemplo de configuração (esquema sem OBSERVACAO).
2. Domínio.
3. Serviços de aplicação.
4. Infraestrutura.
5. Apresentação e ponto de composição. Nessa versão, o DEL removia a linha da grade sem
   recalcular o total.
6. Testes DUnitX.
7. **Evolução**: campo Observação (esquema final, migration, domínio, persistência e tela).
8. **Correção**: recálculo imediato do total ao excluir com DEL, encerramento da edição do
   item excluído e testes de regressão.
9. Bônus: carregar, atualizar e cancelar pedido.
10. Documentação.
11. Compatibilidade do `db.sql` com Firebird 2.5 (generator + trigger).
12. Inclusão de `bin\fbclient.dll` na distribuição.
13. Atualização da documentação com as verificações em Delphi e Firebird reais.
