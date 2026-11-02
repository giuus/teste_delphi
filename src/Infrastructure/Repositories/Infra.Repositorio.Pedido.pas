unit Infra.Repositorio.Pedido;

interface

uses
  Domain.Pedido,
  Domain.Interfaces.Repositorios,
  Infra.Repositorio.Base;

type
  TPedidoRepository = class(TRepositorioFireDAC, IPedidoRepository)
  public
    function GerarNumero: Integer;
    procedure Inserir(ANumero: Integer; APedido: TPedido);
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client;

const
  // NEXT VALUE FOR é atômico e não sofre concorrência como MAX(...) + 1.
  // Valores consumidos não retornam em rollback (podem surgir lacunas).
  SQL_GERAR_NUMERO =
    'SELECT NEXT VALUE FOR SEQ_PEDIDO_NUMERO AS NUMERO FROM RDB$DATABASE';

  SQL_INSERIR =
    'INSERT INTO PEDIDO (NUMERO_PEDIDO, DATA_EMISSAO, CODIGO_CLIENTE, VALOR_TOTAL, OBSERVACAO) ' +
    'VALUES (:NUMERO_PEDIDO, :DATA_EMISSAO, :CODIGO_CLIENTE, :VALOR_TOTAL, :OBSERVACAO)';

procedure AtribuirObservacao(AParametro: TFDParam; const AObservacao: string);
begin
  AParametro.DataType := ftWideString;
  // Observação vazia é gravada como NULL.
  if AObservacao = '' then
    AParametro.Clear
  else
    AParametro.AsWideString := AObservacao;
end;

function TPedidoRepository.GerarNumero: Integer;
var
  LQuery: TFDQuery;
  LNumero: Int64;
begin
  LQuery := CriarQuery(SQL_GERAR_NUMERO);
  try
    LQuery.Open;
    LNumero := LQuery.FieldByName('NUMERO').AsLargeInt;
  finally
    LQuery.Free;
  end;
  if (LNumero <= 0) or (LNumero > High(Integer)) then
    raise ERangeError.CreateFmt('Valor inválido gerado por SEQ_PEDIDO_NUMERO: %d.', [LNumero]);
  Result := LNumero;
end;

procedure TPedidoRepository.Inserir(ANumero: Integer; APedido: TPedido);
var
  LQuery: TFDQuery;
begin
  LQuery := CriarQuery(SQL_INSERIR);
  try
    LQuery.ParamByName('NUMERO_PEDIDO').AsInteger := ANumero;
    LQuery.ParamByName('DATA_EMISSAO').AsDate := APedido.DataEmissao;
    LQuery.ParamByName('CODIGO_CLIENTE').AsInteger := APedido.CodigoCliente;
    // Total recalculado a partir dos itens, com a mesma regra da tela.
    LQuery.ParamByName('VALOR_TOTAL').AsCurrency := APedido.ValorTotal;
    AtribuirObservacao(LQuery.ParamByName('OBSERVACAO'), APedido.Observacao);
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

end.
