unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  IdDNSServer, IdDNSResolver, IdComponent, IdUDPServer, IdSocketHandle,
  IdGlobal;

type

  { TfrmAnaSayfa }

  TfrmAnaSayfa = class(TForm)
    Button1: TButton;
    Button2: TButton;
    IdDNSResolver1: TIdDNSResolver;
    IdUDPServer1: TIdUDPServer;
    Label1: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
  private
    IstekSayisi: Integer;
    procedure IstekSayisiniGuncelle;
  public

  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

{$R *.lfm}

{ TfrmAnaSayfa }
uses IdDNSCommon;

procedure TfrmAnaSayfa.FormCreate(Sender: TObject);
begin

  IstekSayisi := 0;
  IdUDPServer1.Active := True;
end;

procedure TfrmAnaSayfa.Button1Click(Sender: TObject);
begin

  Memo1.Lines.Clear;
  IstekSayisi := 0;
  IstekSayisiniGuncelle;
end;

procedure TfrmAnaSayfa.Button2Click(Sender: TObject);
var
  a: TIdBytes;
  i: SizeInt;
begin

  //a := IPAddrToDNSStr('192.168.1.1');
  a := DomainNameToDNSStr('merhaba.com');
  i := Length(a);
  Memo1.Lines.Add(i.ToString);
end;

procedure TfrmAnaSayfa.IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  UVeri: Integer;
  DNSHeader: TDNSHeader;
begin

  UVeri := Length(AData);

  Memo1.Lines.Add('Uzunluk: ' + UVeri.ToString);

  if(UVeri > 0) then
  begin

    DNSHeader := TDNSHeader.Create;

    if(DNSHeader.ParseQuery(AData) = 0) then
    begin

      Memo1.Lines.Add('ID: ' + DNSHeader.ID.ToString);
      Memo1.Lines.Add('BitCode: ' + DNSHeader.BitCode.ToString);
      Memo1.Lines.Add('QDCount: ' + DNSHeader.QDCount.ToString);
      Memo1.Lines.Add('ANCount: ' + DNSHeader.ANCount.ToString);
      Memo1.Lines.Add('NSCount: ' + DNSHeader.NSCount.ToString);
      Memo1.Lines.Add('ARCount: ' + DNSHeader.ARCount.ToString);

//      IdDNSResolver1.ParseAnswers(DNSHeader, AData);

      //Memo1.Lines.Add(IdDNSResolver1.QueryResult.DomainName + ' adı için IP adresi isteniyor...');

      Inc(IstekSayisi);
      IstekSayisiniGuncelle;
    end;

    FreeAndNil(DNSHeader);
  end;
end;

procedure TfrmAnaSayfa.IstekSayisiniGuncelle;
begin

  Label1.Caption := Format('Toplam İstek Sayısı: %d', [IstekSayisi]);
end;

end.

