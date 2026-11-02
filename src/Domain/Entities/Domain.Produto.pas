unit Domain.Produto;

interface

type
  TProduto = class
  private
    FCodigo: Integer;
    FDescricao: string;
    FPrecoVenda: Currency;
  public
    constructor Create(ACodigo: Integer; const ADescricao: string; APrecoVenda: Currency);
    property Codigo: Integer read FCodigo;
    property Descricao: string read FDescricao;
    property PrecoVenda: Currency read FPrecoVenda;
  end;

implementation

constructor TProduto.Create(ACodigo: Integer; const ADescricao: string; APrecoVenda: Currency);
begin
  inherited Create;
  FCodigo := ACodigo;
  FDescricao := ADescricao;
  FPrecoVenda := APrecoVenda;
end;

end.
