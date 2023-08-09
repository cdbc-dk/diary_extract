(* for cli-apps: instead of compiling the whole lcl, add bc_str to project->options->paths -Fu
   i.e.: no use for: /usr/lib64/lazarus/components/lazutils/
                     /usr/lib64/lazarus/lcl/widgetset/
                     /usr/lib64/lazarus/lcl/
*)
unit u_ddextract;
{$mode ObjFPC}{$H+}
{$modeswitch TypeHelpers}
interface

uses
  Classes, SysUtils, bc_advstring, bc_datetime, bom_dd;
const
  ddError = -1;
  ddOK    = 0;
  ddBusy  = 1;
type
  { disposable pchar, knows its own length (bcStrNew,bcStrDispose,bcStrFree,etc...) }
  dpchar = bc_advstring.dpchar;
  { TbcStringHelper is adding functionality to fpcs stringhelper }
  TbcStringHelper = type helper(TStringHelper) for Ansistring
    function bcClear: string;
  end;

function ddInit(out aVersion: dpchar): dpchar; // db-filename
function ddLoad: HRESULT; // count of entries in db
function ddExtract(dtStart,dtDone,aFilename: dpchar;aPagebreak: boolean;aReformat: boolean = false): HRESULT; // -1: error, 0: OK, 1: busy
function ddFini: HRESULT; // -1: error, 0: OK, 1: busy

implementation

type
  PUserRec = ^TUserRec;
  TUserRec = record
    urMin,
    urMax: ptrint;
    urReformat: boolean;
  end;

var
  dd: TDDCollection; // our little private bom :o)
  sl: TStringList; // our global result
  test: string; //bm
{ bcInsertPageBreaksInStringlist patitions a stringlist with pagebreaks (#12)
  at every aLineCount lines, the default is maxlines pr. page in pdf with fontsize 12 }
procedure bcInsertPageBreaksInStringlist(aList: TStrings;aLineCount: ptruint = 58);
var
  lmod: ptrint;
  Idx: ptruint; // qword
begin
  for Idx:= 0 to aList.Count-1 do begin
    lmod:= Idx mod aLineCount;   // 5;
    if ((lmod = 0) and (Idx > 0)) then begin
      aList.Insert(Idx,#12);
    end;
  end;
end; { bcInsertPageBreaksInStringlist }

{ library code start - - - - - - - - - - - - }
function ddInit(out aVersion: dpchar): dpchar; // db-filename
begin
  sl:= TStringList.Create;
  dd:= TDDCollection.Create(TDDCollectionItem);
  aVersion:= bcStrNew(dd.EngineVersion); { (d)isposable (p)char }
  Result:= bcStrNew(dd.DbName); { (d)isposable (p)char }
end;

function ddLoad: HRESULT;
begin
  dd.ReadDataWithBlob(true); //false = descending dates v, true = ascending dates ^
  Result:= dd.ItemCount;
end;

procedure HandleCallback({%H-}aSender: TObject;anItem: TDDCollectionItem;aUserData: pointer;var aCancel: boolean);
var
  S,lday: string;
  Len: ptrint;
  ur: PUserRec;
begin
  ur:= aUserData; // PUserRec(aUserData);
  if ur = nil then begin aCancel:= true; exit; end;
  if bcIsWithinRange(ur^.urMin,anItem.Date.AsInteger,ur^.urMax) then begin // is date in range all-inclusive
    Len:= anItem.Text.Size; // size of blob
    SetLength(S,Len); // buffer
    FillChar(S[1],Len,0); // clear buffer
    anItem.Text.Position:= 0; // reset blob VERY IMPORTANT!!!
    anItem.Text.Read(S[1],Len); // read buffer
    anItem.Text.Position:= 0; // reset blob, nice for the next pass :o)
    lday:= anItem.Date.DayName; // pick the dayname, saves a roundtrip (request from Randi)
    sl.Append(lday+' '+anItem.Date.AsString+':');
    if ur^.urReformat then sl.Append('  '+bcReformatString(S,80))
    else sl.Append(S);
    sl.Append(bcMakeStringField('__',74,txaCenter,'_')); // add item-separator __/\__
    sl.Append('');                                       // add blank separator
    writeln(lday+' '+anItem.Date.AsString+':');
    if ur^.urReformat then writeln('  '+bcReformatString(S,80))
    else writeln(S);
    writeln(bcMakeStringField('__',74,txaCenter,'_'));    // add item-separator __/\__
    writeln('');                                          // add blank separator
    SetLength(S,0);
  end;
  ur:= nil;
end;

function ddExtract(dtStart,dtDone,aFilename: dpchar;aPagebreak: boolean;aReformat: boolean = false): HRESULT;
var
  iDo,iSt: TIsoDate;
  rec: TUserRec;
begin
  sl.Clear; Result:= -1;
  iSt:= TIsoDate.Create(bcStrFree(dtStart)); iDo:= TIsoDate.Create(bcStrFree(dtDone));
  try
    sl.Append(#10#10);
    sl.Append(bcMakeStringField('Logbog for Benny Christensen',74,txaCenter,' '));
    sl.Append(#10);
    sl.Append(bcMakeStringField(iSt.AsString+' - '+iDo.AsString,74,txaCenter,' '));
    sl.Append(#10#10);
    rec.urMin:= iSt.AsInteger; rec.urMax:= iDo.AsInteger; rec.urReformat:= aReformat;
    dd.OnIterate:= @HandleCallback;
    dd.Iterate(@rec);
    sl.Append(#10#10);
    sl.Append(bcMakeStringField('To be continued...',74,txaCenter,' '));
    if aPagebreak then bcInsertPageBreaksInStringlist(sl,55); //bm
    sl.SaveToFile(bcStrFree(aFilename));
    Result:= ddOK;                            writeln(#10+'Linecount: ',sl.Count); //bm
  finally iSt.Free; iDo.Free; end;
exit;  //test
  writeln(#10+' testing reformat: '+#10);
  writeln(bcReformatString(test,80));
end;

function ddFini: HRESULT;
begin
  bcFreeThenNil(sl);
  bcFreeThenNil(dd);
  Result:= ddOK;
end;
{ library code end - - - - - - - - - - - - }

{ TbcStringHelper }
function TbcStringHelper.bcClear: string;
begin
  Self:= Empty;
  Result:= Self;
end;

end.

