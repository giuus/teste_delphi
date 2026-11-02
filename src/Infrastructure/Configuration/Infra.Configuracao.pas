unit Infra.Configuracao;

{ Leitura do config.ini.

  - O arquivo é procurado somente na pasta do executável (não depende do
    diretório de trabalho atual).
  - ClientLibrary relativo é resolvido a partir dessa pasta.
  - Database relativo terminado em .fdb também é resolvido a partir dessa
    pasta; valores sem extensão .fdb são tratados como alias do servidor
    (databases.conf) e repassados sem alteração.
  - A senha nunca é incluída em mensagens. }

interface

uses
  System.IniFiles;

type
  TConfiguracaoBanco = record
    Database: string;
    Username: string;
    Password: string;
    Server: string;
    Port: Integer;
    ClientLibrary: string;
  end;

  TLeitorConfiguracao = class
  public const
    NOME_ARQUIVO = 'config.ini';
    SECAO = 'Database';
  private
    class function LerObrigatorio(AIni: TMemIniFile; const AChave, AArquivo: string): string; static;
    class function LerPorta(AIni: TMemIniFile; const AArquivo: string): Integer; static;
    class function ResolverCaminho(const ACaminho, ADiretorioBase: string): string; static;
    class function ResolverDatabase(const ADatabase, ADiretorioBase: string): string; static;
  public
    class function DiretorioExecutavel: string; static;
    /// Lê <ADiretorioBase>\config.ini. Levanta EConfiguracaoException com
    /// mensagem descritiva se o arquivo ou algum campo estiver inválido.
    class function Carregar(const ADiretorioBase: string): TConfiguracaoBanco; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Infra.Exceptions;

class function TLeitorConfiguracao.DiretorioExecutavel: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

class function TLeitorConfiguracao.Carregar(const ADiretorioBase: string): TConfiguracaoBanco;
var
  LArquivo: string;
  LIni: TMemIniFile;
begin
  LArquivo := TPath.Combine(ADiretorioBase, NOME_ARQUIVO);
  if not FileExists(LArquivo) then
    raise EConfiguracaoException.CreateFmt(
      'Arquivo de configuração não encontrado:%s%s%s%s' +
      'Copie o config.ini.example para essa pasta com o nome config.ini e ajuste os valores.',
      [sLineBreak, LArquivo, sLineBreak, sLineBreak]);

  LIni := TMemIniFile.Create(LArquivo, TEncoding.UTF8);
  try
    if not LIni.SectionExists(SECAO) then
      raise EConfiguracaoException.CreateFmt('Seção [%s] não encontrada em %s.', [SECAO, LArquivo]);

    Result.Database := ResolverDatabase(LerObrigatorio(LIni, 'Database', LArquivo), ADiretorioBase);
    Result.Username := LerObrigatorio(LIni, 'Username', LArquivo);
    Result.Password := LerObrigatorio(LIni, 'Password', LArquivo);
    Result.Server := LerObrigatorio(LIni, 'Server', LArquivo);
    Result.Port := LerPorta(LIni, LArquivo);
    Result.ClientLibrary := ResolverCaminho(LerObrigatorio(LIni, 'ClientLibrary', LArquivo),
      ADiretorioBase);
  finally
    LIni.Free;
  end;

  if not FileExists(Result.ClientLibrary) then
    raise EConfiguracaoException.CreateFmt(
      'Biblioteca cliente do Firebird não encontrada:%s%s%s%s' +
      'Verifique a chave ClientLibrary em %s. O fbclient.dll deve ter a mesma ' +
      'arquitetura do executável (32 bits).',
      [sLineBreak, Result.ClientLibrary, sLineBreak, sLineBreak, LArquivo]);
end;

class function TLeitorConfiguracao.LerObrigatorio(AIni: TMemIniFile;
  const AChave, AArquivo: string): string;
begin
  Result := Trim(AIni.ReadString(SECAO, AChave, ''));
  if Result = '' then
    raise EConfiguracaoException.CreateFmt('Informe a chave %s na seção [%s] de %s.',
      [AChave, SECAO, AArquivo]);
end;

class function TLeitorConfiguracao.LerPorta(AIni: TMemIniFile; const AArquivo: string): Integer;
var
  LTexto: string;
begin
  LTexto := LerObrigatorio(AIni, 'Port', AArquivo);
  if not TryStrToInt(LTexto, Result) or (Result < 1) or (Result > 65535) then
    raise EConfiguracaoException.CreateFmt(
      'Valor inválido para Port em %s: "%s". Informe um número entre 1 e 65535.',
      [AArquivo, LTexto]);
end;

class function TLeitorConfiguracao.ResolverCaminho(const ACaminho, ADiretorioBase: string): string;
begin
  if TPath.IsPathRooted(ACaminho) then
    Result := ACaminho
  else
    Result := ExpandFileName(TPath.Combine(ADiretorioBase, ACaminho));
end;

class function TLeitorConfiguracao.ResolverDatabase(const ADatabase, ADiretorioBase: string): string;
begin
  if SameText(ExtractFileExt(ADatabase), '.fdb') then
    Result := ResolverCaminho(ADatabase, ADiretorioBase)
  else
    Result := ADatabase;
end;

end.
