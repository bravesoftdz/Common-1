unit u_dbDistinctClasses;
/// ��������������� ������ ��� ����������� ������� ������ � ����� ������
/// ��������� SQL � ������ ���������� � ����� �.�. � ��� ����� ���������� � �������
interface

uses System.Types, System.UITypes, System.Classes, System.Variants,
     FMX.Types,
     Data.DB,
     FireDAC.Comp.Client;

type
   TDbDistinctCombiner=class(TComponent)
    private
     FConn:TFDConnection;
     procedure SetConnection(Value:TFDConnection);
    public
      constructor Create(AOwner:TComponent); override;
      /// <summary>
      ///      ����� � ��������� ���� ������ �������� ���� ��� 1  ��� 2
      ///      - � ��� ����� ������������ �����, �������� � ���� 1 � ������� ���������� ��� 1(��� �������)
      /// </summary>
      function GetIncMaxNumFromFieldText(const aDS:TDataSet; const aFieldname: String):Integer;
      /// <summary>
      ///     ����� � ���� (�� ��������� ������ ������ � ����� � ���� TABLENAME1=FIELDNAME1,TblName2=FieldName2)
      ///     ���� �� ���� ������ - true or (Not found = false)
      /// </summary>
      function IsExistsRecordsFromID(aID:Integer; const ATblNamesFieldsStr:string):Boolean;
      ///
      /// <summary>
      ///    �������� �������-������� � ���������� ������ ��� ���. ����������
      /// </summary>
      function CreateFDQuery(const AQName,ACommaFieldsStr,aAfterWhereStr:string; aEntID:Integer=0):TFDQuery;
      function CreateFDTable(const ATblName:string; aEntID:Integer=0):TFDTable;
     ///
     property FDConnection:TFDConnection read FConn write SetConnection;
   end;



implementation

uses System.SysUtils;


{ TDbDistinctCombiner }

constructor TDbDistinctCombiner.Create(AOwner: TComponent);
begin
  inherited;
  FConn:=nil;
end;

function TDbDistinctCombiner.CreateFDQuery(const AQName,
  ACommaFieldsStr,aAfterWhereStr: string; aEntID: Integer): TFDQuery;
 var LS,LWS:String;
begin
    if aAfterWhereStr<>'' then
     LWS:=' WHERE ('+aAfterWhereStr+')'
  else LWS:='';
  if (aEntID<>0) then
     LS:='((ENT_ID=0) OR (ENT_ID='+IntToStr(aEntID)+'))'
  else LS:='';
  if LS<>'' then
     if LWS<>'' then
        LWS:=LWS+' AND '+LS
     else
        LWS:=' WHERE '+LS;
  Result:=TFDQuery.Create(Self.Owner);
  Result.SQL.Text:='SELECT '+ACommaFieldsStr+' FROM '+AQName+LWS;
  Result.Connection:=FConn;
end;

function TDbDistinctCombiner.CreateFDTable(const ATblName: string;
  aEntID: Integer): TFDTable;
begin
 Result:=TFDTable.Create(Owner);
 Result.Connection:=FConn;
 Result.TableName:=ATblName;
 if aEntID<>0 then
  begin
   Result.Filter:='((ENT_ID=0) OR (ENT_ID='+IntToStr(aEntID)+'))';
   Result.Filtered:=True;
  end;
end;


function TDbDistinctCombiner.GetIncMaxNumFromFieldText(const aDS: TDataSet;
  const aFieldname: String): Integer;
   var LBM:TBookmark;
      LNum:integer;
            function L_GetNumFromStr(const AStr:string):Integer;
            var ii:Integer;
                LSS:string;
               begin
                 LSS:='';
                 Result:=0;
                 ii:=Length(AStr);
                 while ii>0 do
                   begin
                     if (LSS<>'') and (AStr[ii]=' ') then
                         begin
                           TryStrToInt(LSS,Result);
                           Break;
                         end
                     else
                       if AStr[ii]<>' ' then
                          LSS:=Trim(AStr[ii]+LSS);
                     Dec(ii);
                   end;
               end;
begin
      Result:=1;
      LBM:=aDS.GetBookmark;
      aDS.DisableControls;
      try
        aDS.First;
        while not(aDS.Eof) do
          begin
           if (aDS.FieldByName(aFieldname).IsNull=false) then
              LNum:=1+L_GetNumFromStr(aDS.FieldByName(aFieldname).AsWideString)
           else LNum:=-1;
           if LNum>Result then
              Result:=LNum;
           aDS.Next;
          end;
       finally
        aDS.GotoBookmark(LBM);
        aDS.EnableControls;
        aDS.FreeBookmark(LBM);
      end;
end;

function TDbDistinctCombiner.IsExistsRecordsFromID(aID: Integer;
  const ATblNamesFieldsStr: string): Boolean;
var LTblDesc:TStringList;
    il:Integer;
    LTblName,LFldName:string;
    LFQ:TFDQuery;
begin
 Result:=False;
 if ATblNamesFieldsStr='' then Exit;
 LTblDesc:=TStringList.Create;
 LFQ:=TFDQuery.Create(nil);
 try
   LFQ.Connection:=FConn;
   LTblDesc.CommaText:=ATblNamesFieldsStr;
   il:=0;
   while il<LTblDesc.Count do
     begin
       LTblName:=Trim(LTblDesc.Names[il]);
       LFldName:=Trim(LTblDesc.ValueFromIndex[il]);
       if (LTblName<>'') and (LFldName<>'') then
         begin
           LFQ.Active:=False;
           LFQ.Open('SELECT COUNT(*) FROM '+LTblName+' WHERE ('+LFldName+'='+IntToStr(aID)+');');
           if (LFQ.Fields[0].IsNull=False) and (LFQ.Fields[0].AsInteger>0) then
              begin
                Result:=True;
                Break;
              end;
         end;
       Inc(il);
     end;
 finally
   LFQ.Free;
   LTblDesc.Free;
 end;
end;

procedure TDbDistinctCombiner.SetConnection(Value: TFDConnection);
begin
 FConn:=Value;
end;

end.
