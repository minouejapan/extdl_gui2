{
  青空文庫形式テキストファイルをマークダウン形式に変換する
}
program az2md;

{$mode delphi}
{$codepage utf8}

uses
  Classes, SysUtils, RegExpr, LazUTF8;

var
  InFile, OutFile: TStringList;
  InName, OutName, FName, BaseDir, OutDir: string;

{$R *.res}

// MD形式への変換処理
procedure DlProc;
var
  i, n: integer;
  ln, tmp: string;
begin
  n := InFile.Count;
  if n < 3 then
    Exit;
  tmp := InFile.Text;
  // 青空文庫エンコード
  tmp := UTF8StringReplace(tmp, '※［＃始め二重山括弧、1-1-52］',   '《',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '※［＃終わり二重山括弧、1-1-53］', '》', [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '※［＃縦線、1-1-35］',             '｜',  [rfReplaceAll]);
  // マークダウン形式の誤作動防止
  tmp := UTF8StringReplace(tmp, '~~',                              '～',  [rfReplaceAll]);
  // マークダウン形式でのエスケープ文字
  tmp := UTF8StringReplace(tmp, '\',                               '\\',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '*',                               '\*',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '_',                               '\_',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '[',                               '\[',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, ']',                               '\]',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '(',                               '\(',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, ')',                               '\)',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '{',                               '\{',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '}',                               '\}',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '#',                               '\#',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '+',                               '\+',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '-',                               '\-',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '.',                               '\.',  [rfReplaceAll]);
  tmp := UTF8StringReplace(tmp, '!',                               '\!',  [rfReplaceAll]);
  InFile.Text := tmp;
  ln := InFile[0]; // タイトル名
  OutFile.Add('# ' + ln);
  ln := InFile[1]; // 作者名
  OutFile.Add('<div align="right">' + ln + '</div>');
  OutFile.Add('  ');
  i := 2;
  while i < n do
  begin
    ln := InFile[i];
    if ln = '' then // 空行をスキップする
    begin
      Inc(i); Continue;
		end;
		if (ln = '') or (ln = '［＃改ページ］') then
      OutFile.Add('')
    else if ln = '［＃ここから罫囲み］' then
      //OutFile.Add('<p font size = "2">')
    else if ln = '［＃ここで罫囲み終わり］' then
      //OutFile.Add('</p>')
    else if ln = '［＃水平線］' then
      OutFile.Add('***')
    else if ExecRegExpr('［＃表紙の図（.*?）入る］', ln) then
    begin
      ln := ReplaceRegExpr('［＃表紙の図（', ln, '![挿絵](');
      ln := ReplaceRegExpr('）入る］', ln, ')');
      OutFile.Add(ln);
    end else if ExecRegExpr('［＃リンクの図（.*?）入る］', ln) then
    begin
      ln := ReplaceRegExpr('［＃リンクの図（', ln, '![挿絵](');
      ln := ReplaceRegExpr('）入る］', ln, ')');
      OutFile.Add(ln);
    end else if ExecRegExpr('［＃大見出し］.*?［＃大見出し終わり］', ln) then
     begin
       ln := ReplaceRegExpr('［＃大見出.*?］', ln, '');
       OutFile.Add('## ' + ln + #13#10);
		end else if ExecRegExpr('［＃中見出し］.*?［＃中見出し終わり］', ln) then
    begin
      ln := ReplaceRegExpr('［＃中見出.*?］', ln, '');
      OutFile.Add('### ' + ln + #13#10);
    end else if Pos('｜', ln) > 0 then
    begin
      ln := ReplaceRegExpr('｜', ln, '<ruby>');
      ln := ReplaceRegExpr('《', ln, '<rp>（</rp><rt>');
      ln := ReplaceRegExpr('》', ln, '</rt><rp>）</rp></ruby>');
      OutFile.Add(ln + '  ');
		end else
      OutFile.Add(ln + '  ');
    Inc(i);
	end;
end;

// 処理メイン
begin
  if (ParamCount = 0) or (not FileExists(ParamStr(1))) then
  begin
    Writeln('使用方法:');
    Writeln('  az2md 青空文庫準拠テキストファイル名');
    //Readln;
    Exit;
	end;
  InName  := SysToUTF8(ParamStr(1));
  FName   := ExtractFileName(InName);
  BaseDir := ExtractFilePath(InName);
  OutDir  := BaseDir + ChangeFileExt(ExtractFileName(InName), '');
  OutName := OutDir + '\' + ChangeFileExt(FName, '.md'); // ファイル名のサブフォルダに加工後のファイルを保存する
  if not DirectoryExists(OutDir) then
    ForceDirectories(OutDir);
  InFile  := TStringList.Create;
  OutFile := TStringList.Create;
  try
    InFile.LoadFromFile(InName, TEncoding.UTF8);
    // 挿絵画像ダウンロード・リンク先置換処理
    DlProc;
    OutFile.SaveToFile(OutName, TEncoding.UTF8);
    Writeln(OutName + 'に保存しました.');
	finally
    OutFile.Free;
    InFile.Free;
	end;
end.

