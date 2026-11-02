unit Infra.Repositorio.Cliente;

interface

uses
  Domain.Cliente,
  Domain.Interfaces.Repositorios,
  Infra.Repositorio.Base;

type
  TClienteRepository = class(TRepositorioFireDAC, IClienteRepository)
  public
    function BuscarPorCodigo(ACodigo: Integer): TCliente;
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client;

const
  SQL_BUSCAR_POR_CODIGO =
    'SELECT CODIGO, NOME, CIDADE, UF FROM CLIENTE WHERE CODIGO = :CODIGO';

function TClienteRepository.BuscarPorCodigo(ACodigo: Integer): TCliente;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := CriarQuery(SQL_BUSCAR_POR_CODIGO);
  try
    LQuery.ParamByName('CODIGO').AsInteger := ACodigo;
    LQuery.Open;
    if not LQuery.IsEmpty then
      Result := TCliente.Create(
        LQuery.FieldByName('CODIGO').AsInteger,
        LQuery.FieldByName('NOME').AsString,
        LQuery.FieldByName('CIDADE').AsString,
        Trim(LQuery.FieldByName('UF').AsString));
  finally
    LQuery.Free;
  end;
end;

end.
