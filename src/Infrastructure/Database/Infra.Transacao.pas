unit Infra.Transacao;

interface

uses
  FireDAC.Comp.Client,
  Domain.Interfaces.Transacao;

type
  /// Transação da conexão compartilhada. Não é dona da conexão.
  TTransacaoFireDAC = class(TInterfacedObject, ITransacao)
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);
    procedure Iniciar;
    procedure Confirmar;
    procedure Desfazer;
    function Ativa: Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor TTransacaoFireDAC.Create(AConnection: TFDConnection);
begin
  inherited Create;
  if AConnection = nil then
    raise EArgumentNilException.Create('AConnection');
  FConnection := AConnection;
end;

procedure TTransacaoFireDAC.Iniciar;
begin
  // Transações aninhadas não são usadas: um caso de uso, uma transação.
  if FConnection.InTransaction then
    raise EInvalidOpException.Create('Já existe uma transação em andamento.');
  FConnection.StartTransaction;
end;

procedure TTransacaoFireDAC.Confirmar;
begin
  FConnection.Commit;
end;

procedure TTransacaoFireDAC.Desfazer;
begin
  FConnection.Rollback;
end;

function TTransacaoFireDAC.Ativa: Boolean;
begin
  Result := FConnection.InTransaction;
end;

end.
