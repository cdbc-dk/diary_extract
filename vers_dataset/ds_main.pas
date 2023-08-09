unit ds_main;
{$mode ObjFPC}{$H+}
{$define debug}                  {$ifdef debug} {*} {$endif}
interface

uses
  Classes, SysUtils,bc_advstring,bc_litedb,bc_memdataset,bc_datetime,BufDataset;
type
  TddHandle = ptruint;

function ds_Init(aDbName: dpchar; out aVersion: dpchar): TddHandle;
function ds_ExtractData(aHandle: TddHandle;aSql: dpchar): ptrint; // returns -1 on error, else record-count
function ds_Fini(aHandle: TddHandle): TddHandle;

implementation

var p:pointer;
    bds: TBufDataset;

function ds_Init(aDbName: dpchar; out aVersion: dpchar): TddHandle;
begin
  TLiteDb(Result):= TLiteDb.Create(bcStrFree(aDbName));
  aVersion:= bcStrNew(TLiteDb(Result).Version);
end;

function ds_ExtractData(aHandle: TddHandle; aSql: dpchar): ptrint;
var
  Db: TLiteDb;
  ds: TMemDataset;
begin
  Db:= TLiteDb(aHandle); ds:= TMemDataset.Create(nil);
  try
    Db.QuerySQL(bcStrFree(aSql),ds);
    Result:= ds.RecordCount;
    if Result > 0 then begin
      ds.First;
      while not ds.EOF do begin
        writeln(ds.FieldByName('id_dd').AsInteger);
        writeln(bcIntDateToStr(ds.FieldByName('date_dd').AsInteger));
        writeln(ds.FieldByName('str_text_dd').AsString,#10);
        ds.Next;
      end;
    end;
  finally bcFreeThenNil(ds); end;
end;

function ds_Fini(aHandle: TddHandle): TddHandle;
begin
  TLiteDb(aHandle).Free;
  Result:= 0;
end;

end.

