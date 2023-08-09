program diary_extract;
{$mode objfpc}{$H+}

uses
  cthreads, Classes,bc_advstring, u_ddextract;
var
  Dbf,Ss,Sd,Sf,Sv,Options: string;
  dp: dpchar;
  Debug,Pagebreak,Reformat: boolean;
{$R *.res}
begin
  Options:= ParamStr(1);// copy(ParamStr(1),2); { skip '-' 3.rd param omitted, means rest of text }
  if Options <> '' then begin
    Debug:= (pos('d',Options) > 0);
    Pagebreak:= (pos('p',Options) > 0);
    Reformat:= (pos('r',Options) > 0);
  end;
  writeln('> V.2.0.1 = 01.30.04.2023');
  writeln('Data extraction from daily diary within a date-range...');
  writeln(' * you can "debug" by specifying -d in first parameter.');
  writeln(' * you can "pagebreak" by specifying -p or both -dp in first parameter.');
  writeln(' * you can "reformat" by specifying -r or all three -dpr in first parameter.',#10);
  Dbf:= bcStrFree(ddInit(dp));
  try
    Sv:= bcStrFree(dp);
    writeln('Storage loaded successfully, Engine version: ',Sv);
    writeln('Connected to: ',Dbf);
    writeln('Data loaded successfully, item count: ',ddLoad,#10);
    if Debug then begin
      Ss:= '06.03.2023'; Sd:= '31.12.2023'; Sf:= 'debug_2023.txt';
    end else begin
      write('Enter start date (dd.mm.yyyy): '); readln(Ss);
      write('Enter end date (dd.mm.yyyy): '); readln(Sd);
      write('Enter target filename: '); readln(Sf);
    end;
    if ddExtract(bcStrNew(Ss),bcStrNew(Sd),bcStrNew(Sf),Pagebreak,Reformat) <> ddOK then
      writeln('Error in ddExtract...');
  finally ddFini; end;
  writeln('Done!');
end.
// select * from daily_diary where ((date_dd >= 132580101) and (date_dd <= 132580110)) ORDER BY date_dd ASC;
