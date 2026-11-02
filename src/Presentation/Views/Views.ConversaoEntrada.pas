unit Views.ConversaoEntrada;

{ Conversão entre o texto digitado nos campos e os tipos da aplicação,
  respeitando a configuração regional do Windows (separador decimal).
  Valores exibidos para edição não usam separador de milhar, para que o
  mesmo texto possa ser lido de volta sem ambiguidade. }

interface

type
  TConversaoEntrada = class
  public
    class function LerCodigo(const ATexto, ACampo: string): Integer; static;
    class function LerDecimal(const ATexto, ACampo: string; ACasasDecimais: Integer): Currency; static;
    class function FormatarParaEdicao(AValor: Currency; ACasasDecimais: Integer): string; static;
  end;

implementation

uses
  System.SysUtils,
  Domain.Exceptions,
  Domain.Regras;

class function TConversaoEntrada.LerCodigo(const ATexto, ACampo: string): Integer;
begin
  if Trim(ATexto) = '' then
    raise EValidacaoException.CreateFmt('Informe o %s.', [ACampo]);
  if not TryStrToInt(Trim(ATexto), Result) or (Result <= 0) then
    raise EValidacaoException.CreateFmt(
      'O %s deve ser um número inteiro maior que zero.', [ACampo]);
end;

class function TConversaoEntrada.LerDecimal(const ATexto, ACampo: string;
  ACasasDecimais: Integer): Currency;
var
  LTexto: string;
begin
  LTexto := Trim(ATexto);
  if LTexto = '' then
    raise EValidacaoException.CreateFmt('Informe o campo %s.', [ACampo]);
  if not TryStrToCurr(LTexto, Result, FormatSettings) then
    raise EValidacaoException.CreateFmt(
      'Valor inválido em %s: "%s". Use somente números e "%s" como separador decimal.',
      [ACampo, LTexto, FormatSettings.DecimalSeparator]);
  if not TRegrasPedido.PossuiNoMaximoCasas(Result, ACasasDecimais) then
    raise EValidacaoException.CreateFmt('O campo %s aceita no máximo %d casas decimais.',
      [ACampo, ACasasDecimais]);
end;

class function TConversaoEntrada.FormatarParaEdicao(AValor: Currency;
  ACasasDecimais: Integer): string;
begin
  Result := CurrToStrF(AValor, ffFixed, ACasasDecimais, FormatSettings);
end;

end.
