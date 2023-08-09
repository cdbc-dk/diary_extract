program ds_extract;
{$mode objfpc}{$H+} // compile on command line:
uses                // fpc -Fu/home/bc/src/bc_rtl/ -Fu/home/bc/src/bc_str/ -Fi/home/bc/src/bc_rtl/inc/ -FUlib/ ds_extract.lpr
  cthreads,Classes,sysutils,bc_advstring, ds_main,LazUTF8; { for console-apps, put bc_str in uses }
const
  db3 = 'db/daily_diary.db3'; // getappdir+db3;
  sql = 'select id_dd,date_dd,cast(text_dd as varchar(1024)) as str_text_dd from daily_diary order by date_dd asc;';
type  // 'SELECT * FROM daily_diary ORDER BY date_dd ASC;' 1024~4096~8192
  TLetters = set of char;
var
  hObj: TddHandle;
  lV: dpchar;
  I,Cnt: ptrint;
  Opt: TLetters;
  Options,Db: string;
  Debug,Reformat: boolean;
{$R *.res}
begin
  Db:= bcGetAppDir+db3; Opt:= [];
// copy(ParamStr(1),2,high(byte)); { skip '-' }
  if ParamCount >= 1 then begin
    if pos('r',ParamStr(1)) > 0 then Include(Opt,'r');
    Reformat:= (pos('r',ParamStr(1)) > 0);
    if pos('d',ParamStr(1)) > 0 then Include(Opt,'d');
    Debug:= (pos('d',ParamStr(1)) > 0);
    if ParamCount > 1 then Options:= ParamStr(2);
  end;
  writeln(' * * Data extraction from daily diary within a date-range * *');
  writeln(' * you can "reformat" by specifying -r in 1.st parameter.');
  writeln(' * you can "debug" by specifying -d or both -dr in 1.st parameter.');
  writeln(' * in debug-mode you can add date1?date2?filename.ext as 2.nd parameter');
  writeln(' * example: ds_extract -dr 06.03.2023?19.03.2023?w1011.log',#10);
  hObj:= ds_Init(bcStrNew(Db),lV);
  writeln('--> Engine handle created: ',hObj,' ',IntToHex(hObj));
  writeln('--> Working on: ',Db);
  writeln('--> Engine version: ',lV); // lV gets allocated in init, must free with bcStrDispose or bcStrFree
  bcStrDispose(lV); // free the (d)isposable (p)char
  Cnt:= ds_ExtractData(hObj,bcStrNew(sql));
  writeln('--> Record count: ',Cnt);
  hObj:= ds_Fini(hObj); // free the object handle itself, returns the new value for handle = 0
  writeln('--> Engine handle destroyed: ',hObj,' ',IntToHex(hObj));
  writeln('--> Done!');
  if 'd' in Opt then begin
    WriteLn('Options are: > ',Options,' <');
    Cnt:= bcGetFieldTokenCount(Options,'?');
    for I:= 0 to Cnt-1 do writeln(I,' ',bcGetFieldToken(I+1,Options,'?'));
  end;
end.

