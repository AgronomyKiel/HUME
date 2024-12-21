// File ExtEditCtrl.pas              Last Update: 2004-08-13
//
// Programmer: A.C. Wolff, Almelo - The Netherlands (ac_wolff@hotmail.com)
//            (c) 2002-2004 A.C. Wolff All rights reserved.
//
// This module contains constants and TExtEditCtrl = class(TLabeledEdit) with
// methods and properties  for the handling and validation of LabeledEdit controls.
// The text in the edit-box can be justified with property Alignment
//
// The code for the alignment property is based on Daniel Wischnewski's
// article http://www.delphi3000.com/articles/article_2940.asp
//
// 2003-06-30: ValidateInput corrected: in case of a MinValueError or
//             MaxValueError the wrong value was saved.
// 2003-07-25 TInputChar items WebComputerNameCharC, WebFolderNameCharC, URLCharC added.
// 2003-10-06: 2003-10-06 corrected for PosCurrencyChar
// 2003-10-25: Procedure Undo and Redo added for extern validation in VlidataInput
//             the statement FOldInput:= Text; removed.
// 2004-08-13: The handling of empty fields improved.
unit ExtEditCtrl;

interface 

uses 
Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, 
  StdCtrls, ExtCtrls, Variants;

type
TInputChar = (
  AnyCharC,        // All chars are allowed, see also function ValidChar
  PosIntCharC,     // Characters form a positive integer
  IntCharC,        // Characters form a positive or negative integer
  PosRealCharC,    // Characters form a positive real number
  RealCharC,       // Characters form a positive or negative real number
  CurrencyCharC,   // Characters form Currency value
  PosCurrencyCharC,// Characters form a positive Currency value
  LetterCharC,     // Only letters are allowed
  SQLMaskCharC,    // All characters are allowed except | ' " ;
  FileNameCharC,      // For file name
  FolderNameCharC,    // For folder name '\' as separator)
  WebFolderNameCharC, // For folders on the web ('/' as separator)
  URLCharC,           // For Web adresses
  HexCharC,           // Upper and lower case hexadecimal characters
  WebComputerNameCharC);  // For webcomputernames: no '/' and ':' allowed

  TExtEditCtrl = class(TLabeledEdit)
  private
    FAlignment: TAlignment;
    FCancelButton: TObject;
    FInputChar: TInputChar;
    FDataChangedPtr: ^Boolean;
    FOldInput: string;
    FErrorMsg: string;
    FSkipChar: Boolean;
    FInvalidValue: Boolean;
    FEmptyFieldAllowed: Boolean;
    FNrofDecimals: Integer;
    FRealValue: double;
    FCurrencyValue: Currency;
    FIntValue: integer;
    FStringValue: string;
    FMinValue, FMaxvalue: variant;
    procedure SetAlignment(const Value: TAlignment);
    function ValidChar(key: Char): boolean;
    procedure ValidateInput;
    procedure SetValue(const Value: variant);
    function GetValue: variant;
    function IsInvalid: Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CreateWnd; override;
    procedure ExtEnter(Sender: TObject);
    procedure ExtExit(Sender: TObject);
    procedure ExtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ExtKeyPress(Sender: TObject; var Key: Char);
    Procedure GetDataChangedPtr(Var DataChanged: Boolean);
    Procedure Undo();
    Procedure Redo();
    property CancelButton: TObject read FCancelButton write FCancelButton;
    property Value: Variant read GetValue write SetValue;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property InputType: TInputChar read FInputChar write FInputChar default AnyCharC;
    property ErrorMsg: String read FErrorMsg write FErrorMsg;
    property NrofDecimals: integer read FNrofDecimals write FNrofDecimals default -1;
    property MinValue: Variant read FMinValue write FMinValue;
    property MaxValue: Variant read FMaxValue write FMaxValue;
    property EmptyFieldAllowed: boolean read FEmptyFieldAllowed write FEmptyFieldAllowed default false;
    property InvalidValue: Boolean Read IsInvalid;
end;

procedure Register; 

implementation 

{R EditExt.dcr}

procedure Register; 
begin 
  RegisterComponents('Wolff', [TExtEditCtrl]);
end; 

{ TExtEditCtrl }

  Const
(** Dutch text: **
    ButtonsText= #13#10 +  'Klik ''OK'' om het te corrigeren of op ''Cancel'' om de oude waarde terug te zetten.';
    DefaultErrorMsg= 'Ongeldige invoer.' + ButtonsText;
    DefaultMinErrorMsg= 'Waarden beneden %s zijn niet toegestaan.' + ButtonsText;
    DefaultMaxErrorMsg= 'Waarden boven %s zijn niet toegestaan.' + ButtonsText;
    DefaultEmptyErrorMsg= 'Een leeg veld is niet toegestaan.';
 **)
    ButtonsText= #13#10 + 'Click ''OK'' to correct it; click ''Cancel'' to undo.';
    DefaultErrorMsg= 'Invalid input.' + ButtonsText;
    DefaultMinErrorMsg= 'Values below %s are not allowed.' + ButtonsText;
    DefaultMaxErrorMsg= 'Values above %s are not allowed.' + ButtonsText;
    DefaultEmptyErrorMsg= 'An empty field is not allowed.';
  (**)
function TExtEditCtrl.ValidChar(key: Char): boolean;
//
// This function returns True if key is no character which
// is forbidden in the InputType group.
//
  Var
    DecPointPos: integer;
    OK: boolean;
begin
  case FInputChar of
     PosRealCharC:
       ValidChar:= (key in ['0'..'9',Char(VK_Back),DecimalSeparator]) and
        not ((key=DecimalSeparator)and(pos(DecimalSeparator,text)>0));
     RealCharC:
        ValidChar:= (key in ['-','0'..'9',Char(VK_Back),DecimalSeparator]) and
        not ((key='-')and(SelStart>0)) and
        not ((key=DecimalSeparator)and(pos(DecimalSeparator,text)>0));
     PosCurrencyCharC, CurrencyCharC:
       begin
        DecPointPos:= pos(DecimalSeparator,text);
        if FInputChar=PosCurrencyCharC then
          OK:= (key in ['0'..'9',Char(VK_Back),DecimalSeparator])
        else
          OK:= (key in ['-','0'..'9',Char(VK_Back),DecimalSeparator]);
        ValidChar:= OK and
        not ((key='-')and(SelStart>0)) and
        not ((key=DecimalSeparator)and(DecPointPos>0)) and
        not ((key in ['0'..'9'])and(DecPointPos>0)and(SelStart>DecPointPos+1));
       end;
     PosIntCharC:
        ValidChar:= (key in ['0'..'9',Char(VK_Back)]);
     IntCharC:
        ValidChar:= (key in ['-','0'..'9',Char(VK_Back)]) and
                   not ((key='-')and(SelStart>0));
     LetterCharC:
        ValidChar:= (key in ['a'..'z','A'..'Z',Char(VK_Back)]);
     SQLMaskCharC:  //(InStr(0,'''|; //', CharToCheck) = 0
        ValidChar:= not (key in ['''','"','|',';']);
     FileNameCharC:
        ValidChar:= (key in ['0'..'9','a'..'z','A'..'Z',
                         '_','-','(',')','[',']','{','}','.','#',Char(VK_Back)])
                       and not ((key='.')and(pos('.',text)>0));
     FolderNameCharC:
        ValidChar:= (key in ['0'..'9','a'..'z','A'..'Z', ' ',
                       '_','-','(',')','[',']','{','}','\',':',Char(VK_Back)]);
     WebFolderNameCharC:
        ValidChar:= (key in ['0'..'9','a'..'z','A'..'Z',
                       '_','-','(',')','[',']','{','}','/','.',':',Char(VK_Back)]);
     URLCharC:
       ValidChar:= (key in ['0'..'9','a'..'z','A'..'Z',
                       '_','-','(',')','[',']','{','}','/','.',':',Char(VK_Back)]);
     HexCharC:
        ValidChar:= (key in ['0'..'9','A'..'F','a'..'f',Char(VK_Back)]);
     WebComputerNameCharC:
        ValidChar:= (key in ['0'..'9','a'..'z','A'..'Z',
                       '_','-','(',')','[',']','{','}','.',Char(VK_Back)]);
    Else
        ValidChar:= True;
   end; { case }
end; { function }

procedure TExtEditCtrl.ValidateInput;
var
   EmptyFieldError, MinValueError, MaxValueError, ConvError: Boolean;
   ErrMsg: String;
   Buttons: TMsgDlgButtons;
   RealValue: double;
   CurrencyValue: Currency;
   IntValue: integer;
   StringValue: string;
   Value: variant;
begin
  MinValueError:= false;
  MaxValueError:= false;
  if ((Text <> FOldInput) and Modified) or ((Length(Text)=0) and (not FEmptyFieldAllowed)) then
    begin
      FInvalidvalue:= false;
      ConvError:= false;
      EmptyFieldError:= false;
      if Text<>'' then
      begin
        Try
          Case FInputChar of
            PosRealCharC, RealCharC:
              begin
                RealValue:= StrToFloat(Text);
                Value:= RealValue;
              end;
            PosIntCharC, IntCharC:
              begin
                IntValue:= StrToInt(Text);
                Value:= IntValue;
              end;
            HexCharC:
              begin
                IntValue:= StrToInt('$'+ Text);
                Value:= IntValue;
              end;
            PosCurrencyCharC, CurrencyCharC:
              begin
                CurrencyValue:= StrToCurr(Text);
                Value:= CurrencyValue;
              end;
          else
              begin
                StringValue:= Text;
                Value:= StringValue;
              end;
          end;
        except
          //On EConvertError do
            ConvError:= True;
        end;
        if (not ConvError) then
        begin
          if (FInputChar=CurrencyCharC) or (FInputChar=PosCurrencyCharC)  then
            begin
              // Show decimals after e.g. input of '10':
              Text:= FormatCurr('#0.00',CurrencyValue);  // Resets Modified !!
              Modified:= True;
            end;
          if VarType(FMinValue)<>varEmpty then
             MinValueError:= (Value < FMinValue);
          if VarType(FMaxValue)<>varEmpty then
             MaxValueError:= (Value > FMaxValue);
        end;
      end
      else
        EmptyFieldError:= not FEmptyFieldAllowed;

      if (ConvError or MinValueError or MaxValueError or EmptyFieldError)
             and (Screen.ActiveControl<>FCancelButton) then
      begin
        FInvalidvalue:= true;
        Buttons:= [mbOK,mbCancel];
        if Length(FErrorMsg)>0 then
          ErrMsg:= FErrorMsg
        else
          if MinValueError then
            ErrMsg:= Format(DefaultMinErrorMsg,[FMinValue])
          else
            if MaxValueError then
              ErrMsg:= Format(DefaultMaxErrorMsg,[FMaxValue])
            else
              if EmptyFieldError then
                begin
                  if length(FOldInput)=0 then
                    begin
                      Buttons:= [mbOK];
                      ErrMsg:= DefaultEmptyErrorMsg  // Makes no sense to say that old text is used again
                    end
                  else
                    ErrMsg:= DefaultEmptyErrorMsg  + ButtonsText;
                end
              else
                ErrMsg:= DefaultErrorMsg;
        If MessageDlg(ErrMsg,mtError,Buttons,0) = mrCancel then
          begin
            Text:= FOldInput;
            if EmptyFieldError and (Length(FOldInput)=0) then
              SetFocus // Keep also FInvalidvalue:= true because field is still empty
            else
              FInvalidvalue:= false;
          end
        else
          SetFocus;
      end;
      if (not FInvalidvalue) and Modified then
      begin
        if FDataChangedPtr <> nil then
          FDataChangedPtr^:= True;
        // FOldInput:= Text;         // ?? Prevents validation in application
          Case FInputChar of
            PosRealCharC, RealCharC:
              FRealValue:= RealValue;
            PosIntCharC, IntCharC,HexCharC:
              FIntValue:= IntValue;
            PosCurrencyCharC, CurrencyCharC:
              FCurrencyValue:= CurrencyValue;
          else
              FStringValue:= StringValue;
          end;
      end;
    end;
end;

procedure TExtEditCtrl.SetValue(const Value: variant);
begin
  if VarType(Value)=varEmpty then
  begin
    Text:= '';
    FRealvalue:= 0;
    FIntValue:= 0;
    FCurrencyValue:= 0;
    FStringvalue:= '';
  end
  else
  Case FInputChar of
    PosRealCharC, RealCharC:
      begin
        FRealValue:= Value;
        IF FNrofDecimals < 0 then
          Text:= FloatToStr(FRealValue)
        else
          Text:= FloatToStrF(FRealValue,ffFixed,18,FNrofDecimals);
      end;
    PosIntCharC, IntCharC:
      begin
        FIntValue:= Value;
        Text:= IntToStr(FIntValue);
      end;
    HexCharC:
      begin
        FIntValue:= Value;
        Text:= IntToHex(FIntValue,4);
      end;
    PosCurrencyCharC, CurrencyCharC:
      begin
        FCurrencyValue:= Value;
        // Text:= FormatCurr('# ### ##0.00',FCurrencyValue);
        // Text:= Format('%m',[FCurrencyValue]);
        // Text:= CurrToStr(FCurrencyValue); // Show no decimal for value 1000
        Text:= FormatCurr('#0.00',FCurrencyValue);
      end;
  else
      begin
        FStringValue:= Value;
        Text:= FStringValue;
      end;
  end;
end;

function TExtEditCtrl.GetValue(): variant;
Var V: Variant;
begin
  If Length(Text) > 0 then
    Case FInputChar of
              PosRealCharC, RealCharC: GetValue:= FRealValue;
      PosIntCharC, IntCharC, HexCharC: GetValue:= FIntValue;
      PosCurrencyCharC, CurrencyCharC: GetValue:= FCurrencyValue;
    else
      GetValue:= FStringValue;
    end
  else
    GetValue:= VarAsType(V,varEmpty);
end;

procedure TExtEditCtrl.GetDataChangedPtr(Var DataChanged: Boolean);
begin
  FDataChangedPtr:= Addr(DataChanged);
end;

function TExtEditCtrl.IsInvalid: Boolean;
begin
  IF not FInvalidValue then   // To prevent that errormsg comes twice
    ValidateInput;
  Result:= FInvalidValue;
end;

constructor TExtEditCtrl.Create(AOwner: TComponent);
begin 
  inherited Create(AOwner);
  FAlignment := taLeftJustify;
  if not Assigned(OnEnter) then
    OnEnter:= ExtEnter;
  if not Assigned(OnKeyDown) then
    OnKeyDown:= ExtKeyDown;
  if not Assigned(OnKeyPress) then
    OnKeyPress:= ExtKeyPress;
  if not Assigned(OnExit) then
    OnExit:= ExtExit;
  FNrofDecimals:= -1;  // Means display with FloatToStr (else FloatToStrF)
end; 

procedure TExtEditCtrl.CreateParams(var Params: TCreateParams); 
const
  Alignments: array[TAlignment] of Cardinal = (ES_LEFT, ES_RIGHT, ES_CENTER);
begin 
  inherited CreateParams(Params);
  Params.Style := Params.Style or {ES_MULTILINE or} Alignments[FAlignment];
end; 

procedure TExtEditCtrl.SetAlignment(const Value: TAlignment);
begin 
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    RecreateWnd;
  end; 
end; 

procedure TExtEditCtrl.ExtEnter(Sender: TObject);
begin
  If not FInvalidValue then
    FOldInput:= Text;
end; { sub }

procedure TExtEditCtrl.ExtKeyPress(Sender: TObject; var Key: Char);
begin
  if FSkipChar then
    FSkipChar:= False
  else
    if Not ValidChar(Key) Then
    begin
      Key:= #0;
      Beep;
    end; { if }
end; { sub }

procedure TExtEditCtrl.ExtExit(Sender: TObject);
begin
  ValidateInput;
end; { sub }

procedure TExtEditCtrl.ExtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Check for  Copy Cut and Paste (Ctrl+C, Ctrl+X and Ctrl+V) and Undo (Ctrl+Z)
  FSkipChar:= false;
  // Next is done to force a call to ValidateInput after correction via
  // Cut/Paste/backspace etc. if InValidValue is called in e.g. FormCloseQuery
  FInvalidValue:= false;
  if Shift=[ssCtrl] then
    if (Key = Ord('C')) or (Key = Ord('X')) or (Key = Ord('V')) then
      FSkipChar:= True
    else
      if (Key = Ord('Z')) then
      begin
        FSkipChar:= True;
        Text:= FOldInput;
      end;
end;

procedure TExtEditCtrl.Undo;
begin
  // Next 2 statements could be replaced by: inherited Undo;
  Text:= FOldInput;
  Modified:= false;
  FInvalidvalue:= false;
end;

procedure TExtEditCtrl.Redo;
begin
  FInvalidvalue:= true;
  SetFocus;
end;

procedure TExtEditCtrl.CreateWnd;
// Required in case the Text property is set
begin
  inherited CreateWnd;
  IF Length(Text)>0 then
    begin
      if InputType = HexCharC then
        SetValue('$'+Text)  // To prevent conversion problems
      else
        SetValue(Text);
    end;
end;

end.

