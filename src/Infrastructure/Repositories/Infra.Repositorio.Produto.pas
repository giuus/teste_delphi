unit Infra.Repositorio.Produto;

interface

uses
  Domain.Produto,
  Domain.Interfaces.Repositorios,
  Infra.Repositorio.Base;

type
  TProdutoRepository = class(TRepositorioFireDAC, IProdutoRepository)
  public
    function BuscarPorCodigo(ACodigo: Integer): TProduto;
  end;

implementation

uses
  FireDAC.Comp.Client;

const
  SQL_BUSCAR_POR_CODIGO =
    'SELECT CODIGO, DESCRICAO, PRECO_VENDA FROM PRODUTO WHERE CODIGO = :CODIGO';

function TProdutoRepository.BuscarPorCodigo(ACodigo: Integer): TProduto;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := CriarQuery(SQL_BUSCAR_POR_CODIGO);
  try
    LQuery.ParamByName('CODIGO').AsInteger := ACodigo;
    LQuery.Open;
    if not LQuery.IsEmpty then
      Result := TProduto.Create(
        LQuery.FieldByName('CODIGO').AsInteger,
        LQuery.FieldByName('DESCRICAO').AsString,
        LQuery.FieldByName('PRECO_VENDA').AsCurrency);
  finally
    LQuery.Free;
  end;
end;

end.
