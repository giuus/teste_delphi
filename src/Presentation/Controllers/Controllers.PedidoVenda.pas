unit Controllers.PedidoVenda;

{ Coordena as ações da tela de pedido de venda.

  Mantém o estado da tela (pedido em digitação, cliente validado, produto
  consultado e item em edição) sem depender de VCL, o que permite testá-lo
  com serviços falsos. Não contém SQL nem controle de transação. }

interface

uses
  Domain.Cliente,
  Domain.Produto,
  Domain.Pedido,
  Services.Interfaces;

type
  TFuncaoData = function: TDateTime;

  TPedidoVendaController = class
  private
    FConsultaService: IConsultaCadastroService;
    FPedidoService: IPedidoService;
    FDataAtual: TFuncaoData;
    FPedido: TPedido;
    FCliente: TCliente;
    FProduto: TProduto;
    FIdItemEmEdicao: Integer;
    FAlterado: Boolean;
    FGravando: Boolean;
    procedure SubstituirPedido(ANovoPedido: TPedido);
    procedure SubstituirCliente(ANovoCliente: TCliente);
    procedure SubstituirProduto(ANovoProduto: TProduto);
    function ProdutoValidado: TProduto;
  public
    constructor Create(const AConsultaService: IConsultaCadastroService;
      const APedidoService: IPedidoService; const ADataAtual: TFuncaoData = nil);
    destructor Destroy; override;

    procedure NovoPedido;

    /// Consulta e guarda o cliente. Em caso de falha o cliente anterior é
    /// descartado e a exceção é propagada para a tela.
    function ConsultarCliente(ACodigo: Integer): TCliente;
    /// Chamado quando o operador altera o código: o cliente deixa de valer.
    procedure DescartarCliente;

    /// Consulta o produto do item. ASugerirPreco indica se o preço de venda
    /// deve ser copiado para o valor unitário: não é sugerido ao reconsultar
    /// o mesmo produto do item em edição, preservando o valor já negociado.
    function ConsultarProduto(ACodigo: Integer; out ASugerirPreco: Boolean): TProduto;
    procedure DescartarProduto;

    procedure AlterarObservacao(const AObservacao: string);

    /// Inclui um novo item ou atualiza o item em edição. Retorna o Id do item.
    function SalvarItem(AQuantidade, AValorUnitario: Currency): Integer;
    function IniciarEdicaoItem(AIdItem: Integer): TPedidoItem;
    procedure CancelarEdicaoItem;
    procedure ExcluirItem(AIdItem: Integer);

    /// Grava o pedido (novo ou carregado) e, após o commit, inicia um novo
    /// pedido vazio. Retorna o número gravado.
    function GravarPedido: Integer;

    /// Substitui o pedido atual por um pedido gravado. Em caso de falha o
    /// pedido atual permanece inalterado. A confirmação de descarte das
    /// alterações locais é responsabilidade da tela (PossuiAlteracoes).
    procedure CarregarPedido(ANumero: Integer);
    /// Exclui o pedido carregado e inicia um novo. Retorna o número excluído.
    function CancelarPedido: Integer;

    function EmEdicaoItem: Boolean;
    property Pedido: TPedido read FPedido;
    property Cliente: TCliente read FCliente;
    property Produto: TProduto read FProduto;
    property IdItemEmEdicao: Integer read FIdItemEmEdicao;
    property PossuiAlteracoes: Boolean read FAlterado;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions;

function DataDoSistema: TDateTime;
begin
  Result := Date;
end;

constructor TPedidoVendaController.Create(const AConsultaService: IConsultaCadastroService;
  const APedidoService: IPedidoService; const ADataAtual: TFuncaoData);
begin
  inherited Create;
  if AConsultaService = nil then
    raise EArgumentNilException.Create('AConsultaService');
  if APedidoService = nil then
    raise EArgumentNilException.Create('APedidoService');
  FConsultaService := AConsultaService;
  FPedidoService := APedidoService;
  if Assigned(ADataAtual) then
    FDataAtual := ADataAtual
  else
    FDataAtual := DataDoSistema;
  NovoPedido;
end;

destructor TPedidoVendaController.Destroy;
begin
  FProduto.Free;
  FCliente.Free;
  FPedido.Free;
  inherited Destroy;
end;

procedure TPedidoVendaController.SubstituirPedido(ANovoPedido: TPedido);
begin
  FPedido.Free;
  FPedido := ANovoPedido;
end;

procedure TPedidoVendaController.SubstituirCliente(ANovoCliente: TCliente);
begin
  FCliente.Free;
  FCliente := ANovoCliente;
end;

procedure TPedidoVendaController.SubstituirProduto(ANovoProduto: TProduto);
begin
  FProduto.Free;
  FProduto := ANovoProduto;
end;

procedure TPedidoVendaController.NovoPedido;
begin
  SubstituirPedido(TPedido.Create(FDataAtual()));
  SubstituirCliente(nil);
  SubstituirProduto(nil);
  FIdItemEmEdicao := 0;
  FAlterado := False;
end;

function TPedidoVendaController.ConsultarCliente(ACodigo: Integer): TCliente;
begin
  SubstituirCliente(nil);
  FPedido.CodigoCliente := 0;
  SubstituirCliente(FConsultaService.ConsultarCliente(ACodigo));
  FPedido.CodigoCliente := FCliente.Codigo;
  FAlterado := True;
  Result := FCliente;
end;

procedure TPedidoVendaController.DescartarCliente;
begin
  if FCliente = nil then
    Exit;
  SubstituirCliente(nil);
  FPedido.CodigoCliente := 0;
  FAlterado := True;
end;

function TPedidoVendaController.ConsultarProduto(ACodigo: Integer;
  out ASugerirPreco: Boolean): TProduto;
var
  LItemEmEdicao: TPedidoItem;
begin
  SubstituirProduto(nil);
  SubstituirProduto(FConsultaService.ConsultarProduto(ACodigo));

  LItemEmEdicao := nil;
  if EmEdicaoItem then
    LItemEmEdicao := FPedido.LocalizarItem(FIdItemEmEdicao);
  ASugerirPreco := (LItemEmEdicao = nil) or (LItemEmEdicao.CodigoProduto <> FProduto.Codigo);
  Result := FProduto;
end;

procedure TPedidoVendaController.DescartarProduto;
begin
  SubstituirProduto(nil);
end;

procedure TPedidoVendaController.AlterarObservacao(const AObservacao: string);
begin
  FPedido.Observacao := AObservacao;
  FAlterado := True;
end;

function TPedidoVendaController.ProdutoValidado: TProduto;
begin
  if FProduto = nil then
    raise EValidacaoException.Create('Informe e consulte um produto válido.');
  Result := FProduto;
end;

function TPedidoVendaController.SalvarItem(AQuantidade, AValorUnitario: Currency): Integer;
var
  LProduto: TProduto;
  LDados: TDadosItemPedido;
begin
  LProduto := ProdutoValidado;
  LDados := TDadosItemPedido.Criar(LProduto.Codigo, LProduto.Descricao,
    AQuantidade, AValorUnitario);

  if EmEdicaoItem then
  begin
    FPedido.AtualizarItem(FIdItemEmEdicao, LDados);
    Result := FIdItemEmEdicao;
  end
  else
    Result := FPedido.AdicionarItem(LDados).Id;

  FAlterado := True;
  CancelarEdicaoItem;
end;

function TPedidoVendaController.IniciarEdicaoItem(AIdItem: Integer): TPedidoItem;
var
  LItem: TPedidoItem;
begin
  LItem := FPedido.ObterItem(AIdItem);
  // Reconsulta o produto para garantir que ele ainda existe; o preço de
  // venda atual não substitui o valor unitário do item.
  SubstituirProduto(nil);
  SubstituirProduto(FConsultaService.ConsultarProduto(LItem.CodigoProduto));
  FIdItemEmEdicao := LItem.Id;
  Result := LItem;
end;

procedure TPedidoVendaController.CancelarEdicaoItem;
begin
  FIdItemEmEdicao := 0;
  SubstituirProduto(nil);
end;

procedure TPedidoVendaController.ExcluirItem(AIdItem: Integer);
begin
  FPedido.RemoverItem(AIdItem);
  // Excluir o item que estava em edição encerra a edição; caso contrário
  // um "Inserir/Atualizar" posterior tentaria atualizar um item inexistente.
  if AIdItem = FIdItemEmEdicao then
    CancelarEdicaoItem;
  FAlterado := True;
end;

function TPedidoVendaController.GravarPedido: Integer;
begin
  // Proteção contra reentrada (ex.: novo clique enquanto grava).
  if FGravando then
    raise EValidacaoException.Create('A gravação do pedido já está em andamento.');
  if FCliente = nil then
    raise EValidacaoException.Create('Informe e consulte um cliente válido antes de gravar.');
  if EmEdicaoItem then
    raise EValidacaoException.Create(
      'Há um item em edição. Confirme com "Inserir/Atualizar Item" ou cancele a edição antes de gravar.');

  FGravando := True;
  try
    FPedido.CodigoCliente := FCliente.Codigo;
    Result := FPedidoService.GravarPedido(FPedido);
  finally
    FGravando := False;
  end;

  // Só chega aqui após o commit. Iniciar um novo pedido impede que o mesmo
  // conteúdo seja gravado de novo por um clique repetido.
  NovoPedido;
end;

procedure TPedidoVendaController.CarregarPedido(ANumero: Integer);
var
  LPedido: TPedido;
  LCliente: TCliente;
begin
  LPedido := FPedidoService.CarregarPedido(ANumero);
  try
    LCliente := FConsultaService.ConsultarCliente(LPedido.CodigoCliente);
  except
    LPedido.Free;
    raise;
  end;
  SubstituirPedido(LPedido);
  SubstituirCliente(LCliente);
  SubstituirProduto(nil);
  FIdItemEmEdicao := 0;
  FAlterado := False;
end;

function TPedidoVendaController.CancelarPedido: Integer;
begin
  if not FPedido.Persistido then
    raise EValidacaoException.Create('Carregue um pedido gravado para cancelá-lo.');
  Result := FPedido.Numero;
  FPedidoService.CancelarPedido(Result);
  NovoPedido;
end;

function TPedidoVendaController.EmEdicaoItem: Boolean;
begin
  Result := FIdItemEmEdicao > 0;
end;

end.
