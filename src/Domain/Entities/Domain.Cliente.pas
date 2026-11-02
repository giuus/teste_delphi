unit Domain.Cliente;

interface

type
  TCliente = class
  private
    FCodigo: Integer;
    FNome: string;
    FCidade: string;
    FUF: string;
  public
    constructor Create(ACodigo: Integer; const ANome, ACidade, AUF: string);
    property Codigo: Integer read FCodigo;
    property Nome: string read FNome;
    property Cidade: string read FCidade;
    property UF: string read FUF;
  end;

implementation

constructor TCliente.Create(ACodigo: Integer; const ANome, ACidade, AUF: string);
begin
  inherited Create;
  FCodigo := ACodigo;
  FNome := ANome;
  FCidade := ACidade;
  FUF := AUF;
end;

end.
