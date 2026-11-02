unit Infra.Repositorio.Base;

interface

uses
  FireDAC.Comp.Client;

type
  /// Base dos repositórios FireDAC. Recebe a conexão compartilhada (não é
  /// dona dela) e nunca controla transação.
  TRepositorioFireDAC = class(TInterfacedObject)
  private
    FConnection: TFDConnection;
  protected
    /// Cria uma query ligada à conexão compartilhada. O chamador libera.
    function CriarQuery(const ASQL: string): TFDQuery;
    property Connection: TFDConnection read FConnection;
  public
    constructor Create(AConnection: TFDConnection);
  end;

implementation

uses
  System.SysUtils;

constructor TRepositorioFireDAC.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if AConnection = nil then
    raise EArgumentNilException.Create('AConnection');
  FConnection := AConnection;
end;

function TRepositorioFireDAC.CriarQuery(const ASQL: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := FConnection;
    Result.SQL.Text := ASQL;
  except
    Result.Free;
    raise;
  end;
end;

end.
