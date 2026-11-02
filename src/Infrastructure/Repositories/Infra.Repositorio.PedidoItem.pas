unit Infra.Repositorio.PedidoItem;

interface

uses
  Domain.Pedido,
  Domain.Interfaces.Repositorios,
  Infra.Repositorio.Base;

type
  TPedidoItemRepository = class(TRepositorioFireDAC, IPedidoItemRepository)
  public
    procedure InserirItens(ANumeroPedido: Integer; APedido: TPedido);
    procedure ExcluirPorPedido(ANumeroPedido: Integer);
    procedure CarregarItens(APedido: TPedido);
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client;

const
  // ID é omitido: gerado pela coluna IDENTITY.
  SQL_INSERIR =
    'INSERT INTO PEDIDO_ITEM (NUMERO_PEDIDO, CODIGO_PRODUTO, QUANTIDADE, VLR_UNITARIO, VLR_TOTAL) ' +
    'VALUES (:NUMERO_PEDIDO, :CODIGO_PRODUTO, :QUANTIDADE, :VLR_UNITARIO, :VLR_TOTAL)';

  SQL_EXCLUIR_POR_PEDIDO =
    'DELETE FROM PEDIDO_ITEM WHERE NUMERO_PEDIDO = :NUMERO_PEDIDO';

  // ORDER BY ID preserva a ordem de inclusão, inclusive de produtos repetidos.
  SQL_LISTAR_POR_PEDIDO =
    'SELECT I.CODIGO_PRODUTO, P.DESCRICAO, I.QUANTIDADE, I.VLR_UNITARIO ' +
    'FROM PEDIDO_ITEM I JOIN PRODUTO P ON P.CODIGO = I.CODIGO_PRODUTO ' +
    'WHERE I.NUMERO_PEDIDO = :NUMERO_PEDIDO ORDER BY I.ID';

procedure TPedidoItemRepository.InserirItens(ANumeroPedido: Integer; APedido: TPedido);
var
  LQuery: TFDQuery;
  LIndice: Integer;
  LItem: TPedidoItem;
begin
  // Uma única query preparada é reutilizada para todos os itens; a cada
  // execução apenas os valores dos parâmetros mudam.
  LQuery := CriarQuery(SQL_INSERIR);
  try
    LQuery.ParamByName('NUMERO_PEDIDO').DataType := ftInteger;
    LQuery.ParamByName('CODIGO_PRODUTO').DataType := ftInteger;
    LQuery.ParamByName('QUANTIDADE').DataType := ftCurrency;
    LQuery.ParamByName('VLR_UNITARIO').DataType := ftCurrency;
    LQuery.ParamByName('VLR_TOTAL').DataType := ftCurrency;
    LQuery.Prepare;

    for LIndice := 0 to APedido.QuantidadeItens - 1 do
    begin
      LItem := APedido.Itens[LIndice];
      LQuery.ParamByName('NUMERO_PEDIDO').AsInteger := ANumeroPedido;
      LQuery.ParamByName('CODIGO_PRODUTO').AsInteger := LItem.CodigoProduto;
      LQuery.ParamByName('QUANTIDADE').AsCurrency := LItem.Quantidade;
      LQuery.ParamByName('VLR_UNITARIO').AsCurrency := LItem.ValorUnitario;
      LQuery.ParamByName('VLR_TOTAL').AsCurrency := LItem.ValorTotal;
      LQuery.ExecSQL;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TPedidoItemRepository.ExcluirPorPedido(ANumeroPedido: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery(SQL_EXCLUIR_POR_PEDIDO);
  try
    LQuery.ParamByName('NUMERO_PEDIDO').AsInteger := ANumeroPedido;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TPedidoItemRepository.CarregarItens(APedido: TPedido);
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery(SQL_LISTAR_POR_PEDIDO);
  try
    LQuery.ParamByName('NUMERO_PEDIDO').AsInteger := APedido.Numero;
    LQuery.Open;
    while not LQuery.Eof do
    begin
      // O total do item é recalculado pela regra do domínio.
      APedido.AdicionarItem(TDadosItemPedido.Criar(
        LQuery.FieldByName('CODIGO_PRODUTO').AsInteger,
        LQuery.FieldByName('DESCRICAO').AsString,
        LQuery.FieldByName('QUANTIDADE').AsCurrency,
        LQuery.FieldByName('VLR_UNITARIO').AsCurrency));
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

end.
