unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  ADODB, DBGrids, DB, Grids;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    procedure FormCreate(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
const
  { Connection string }
  ConnString =
  'Provider=SQLOLEDB.1;Persist Security Info=False;' +
  'User ID=%s;Password=%s;Data Source=%s;Use Procedure for Prepare=1;' +
  'Auto Translate=True;Packet Size=4096;Use Encryption for Data=False;'+
  'Tag with column collation when possible=False';

  { SQL Query }
  SQLStr = 'SELECT * FROM dbo.t_Wetterstationen';

  { User access }
  UserName = 'MaisProgModell';
  PassWord = ':KYGiQQfe9AbF:DxtPhrFpmee-Y!';
  Server = '85.25.20.218';

var
  ADOConn  : TADOConnection;
  ADOQuery : TADOQuery;
  DataSrc  : TDataSource;
  Param    : TParameter;

begin

  { Create an ADO connection. }
  ADOConn := TADOConnection.Create(Self);
  { Set up the provider engine }

  { Set up the connection string. }
  ADOConn.ConnectionString := Format(ConnString,
    [UserName, PassWord, Server]);

  { Disable login prompt. }
  ADOConn.LoginPrompt := False;

  try
    ADOConn.Connected := True;
  except
    on e: EADOError do
    begin
      MessageDlg('Error while connecting', mtError,
                  [mbOK], 0);

      Exit;
    end;
  end;

  { Create the query. }
  ADOQuery := TADOQuery.Create(Self);
  ADOQuery.Connection := ADOConn;
  ADOQuery.SQL.Add(SQLStr);

  { Update the parameter that was parsed from the SQL query: AnId. }
  //Param := ADOQuery.Parameters.ParamByName('AnId');
  //Param.DataType := ftInteger;
  //Param.Value := 1;

  { Set the query to Prepared--it will improve performance. }
  ADOQuery.Prepared := true;

  try
    ADOQuery.Active := True;
  except
    on e: EADOError do
    begin
      MessageDlg('Error while doing query', mtError,
                  [mbOK], 0);

      Exit;
    end;
  end;

  { Create the data source. }
  DataSrc := TDataSource.Create(Self);
  DataSrc.DataSet := ADOQuery;
  DataSrc.Enabled := true;

  { Finally, initialize the grid. }
  DBGrid1.DataSource := DataSrc;
end;


end.
