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

end.
