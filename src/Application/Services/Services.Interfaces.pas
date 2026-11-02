unit Services.Interfaces;

interface

uses
  Domain.Cliente,
  Domain.Produto,
  Domain.Pedido;

type
  /// Consultas a registros previamente cadastrados (sem manutenção de cadastro).
  IConsultaCadastroService = interface
    ['{595C4100-5F37-4C86-A6FA-90677B137B73}']
    /// Levanta ERegistroNaoEncontradoException se não existir.
    /// O chamador é dono do objeto retornado.
    function ConsultarCliente(ACodigo: Integer): TCliente;
    function ConsultarProduto(ACodigo: Integer): TProduto;
  end;

  IPedidoService = interface
    ['{A03A1C17-4083-457C-B10D-223F5960F146}']
    /// Grava cabeçalho e itens em uma única transação e retorna o número do
    /// pedido. Pedido novo: o número só é atribuído ao objeto depois do
    /// commit. Pedido carregado: atualiza o mesmo número, substituindo os itens.
    function GravarPedido(APedido: TPedido): Integer;
    /// Cabeçalho e itens de um pedido gravado. O chamador é dono do objeto.
    function CarregarPedido(ANumero: Integer): TPedido;
    /// Exclusão física de itens e cabeçalho em uma transação.
    procedure CancelarPedido(ANumero: Integer);
  end;

implementation

end.
