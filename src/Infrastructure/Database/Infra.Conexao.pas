unit Infra.Conexao;

{ Conexão FireDAC com o Firebird, configurada em tempo de execução a partir
  do config.ini. Uma única instância é compartilhada por todos os
  repositórios e pela transação; ela pertence ao TCompositionRoot, que a
  libera somente depois de liberar os objetos que a utilizam. }

interface

uses
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Phys.Intf,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.DApt,
  FireDAC.Comp.Client,
  Infra.Configuracao;

type
  TConexaoFirebird = class
  private
    FDriverLink: TFDPhysFBDriverLink;
    FConnection: TFDConnection;
    FDescricao: string;
    procedure ConfigurarParametros(const AConfiguracao: TConfiguracaoBanco);
  public
    constructor Create(const AConfiguracao: TConfiguracaoBanco);
    destructor Destroy; override;
    /// Abre a conexão. Falhas viram EConexaoBancoException (sem a senha).
    procedure Conectar;
    property Connection: TFDConnection read FConnection;
  end;

implementation

uses
  System.SysUtils,
  Infra.Exceptions;

constructor TConexaoFirebird.Create(const AConfiguracao: TConfiguracaoBanco);
begin
  inherited Create;
  FDriverLink := TFDPhysFBDriverLink.Create(nil);
  FDriverLink.VendorLib := AConfiguracao.ClientLibrary;

  FConnection := TFDConnection.Create(nil);
  ConfigurarParametros(AConfiguracao);
  FDescricao := Format('%s:%d / %s', [AConfiguracao.Server, AConfiguracao.Port,
    AConfiguracao.Database]);
end;

destructor TConexaoFirebird.Destroy;
begin
  if FConnection <> nil then
    FConnection.Connected := False;
  FConnection.Free;
  FDriverLink.Free;
  inherited Destroy;
end;

procedure TConexaoFirebird.ConfigurarParametros(const AConfiguracao: TConfiguracaoBanco);
begin
  FConnection.LoginPrompt := False;
  FConnection.Params.Clear;
  FConnection.Params.Values['DriverID'] := 'FB';
  FConnection.Params.Values['Protocol'] := 'TCPIP';
  FConnection.Params.Values['Server'] := AConfiguracao.Server;
  FConnection.Params.Values['Port'] := IntToStr(AConfiguracao.Port);
  FConnection.Params.Values['Database'] := AConfiguracao.Database;
  FConnection.Params.Values['User_Name'] := AConfiguracao.Username;
  FConnection.Params.Values['Password'] := AConfiguracao.Password;
  FConnection.Params.Values['CharacterSet'] := 'UTF8';

  // Fora de transações explícitas (consultas), cada comando é confirmado
  // automaticamente. A gravação do pedido usa transação explícita.
  FConnection.TxOptions.Isolation := xiReadCommitted;
  FConnection.TxOptions.AutoCommit := True;
end;

procedure TConexaoFirebird.Conectar;
begin
  try
    FConnection.Connected := True;
  except
    on E: Exception do
      raise EConexaoBancoException.CreateFmt(
        'Não foi possível conectar ao banco de dados (%s).%s' +
        'Verifique o config.ini, se o serviço do Firebird está em execução e se a ' +
        'biblioteca cliente corresponde à arquitetura do executável.%s%sDetalhe: %s',
        [FDescricao, sLineBreak, sLineBreak, sLineBreak, E.Message]);
  end;
end;

end.
