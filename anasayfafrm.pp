unit anasayfafrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus, IdDNSResolver, IdComponent, IdUDPServer, IdSocketHandle, IdGlobal;

type
  TfrmAnaSayfa = class(TForm)
    btnTemizle: TButton;
    cbSunucuAktif: TCheckBox;
    idDNSYanitlayici: TIdDNSResolver;
    IdUDPSunucu: TIdUDPServer;
    lblYanitlananIstekSayisi: TLabel;
    lblYanitlanamayanIstekSayisi: TLabel;
    mmSonuc: TMemo;
    pnlUst: TPanel;
    pnlAlt: TPanel;
    procedure btnTemizleClick(Sender: TObject);
    procedure cbSunucuAktifChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure IdUDPSunucuUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
  private
    YanitlananIstekSayisi,
    YanitlanamayanIstekSayisi: Integer;
    procedure IstekSayisiniGuncelle;
    procedure Ekle2Byte(var AHedef: TIdBytes; const ADeger: Word);
    procedure Ekle4Byte(var AHedef: TIdBytes; const ADeger: DWord);
  public

  end;

var
  frmAnaSayfa: TfrmAnaSayfa;

implementation

{$R *.lfm}
uses IdDNSCommon, IdStack, paylasim;

procedure TfrmAnaSayfa.FormCreate(Sender: TObject);
begin

  YanitlananIstekSayisi := 0;
  YanitlanamayanIstekSayisi := 0;

  cbSunucuAktif.Checked := True;
end;

procedure TfrmAnaSayfa.FormShow(Sender: TObject);
begin

  IdUDPSunucu.Active := cbSunucuAktif.Checked;
end;

procedure TfrmAnaSayfa.btnTemizleClick(Sender: TObject);
begin

  mmSonuc.Lines.Clear;
  YanitlananIstekSayisi := 0;
  YanitlanamayanIstekSayisi := 0;
  IstekSayisiniGuncelle;
end;

procedure TfrmAnaSayfa.cbSunucuAktifChange(Sender: TObject);
begin

  IdUDPSunucu.Active := cbSunucuAktif.Checked;
end;

procedure TfrmAnaSayfa.IdUDPSunucuUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  DNSHeader: TDNSHeader;
  DNSYanit: TIdBytes;
  i: Integer;
  DNSAdi, IPAdres, s: string;
  ID, BitCode, QDCount, ANCount,
  NSCount, ARCount, SorguTipi,
  SorguSinifi: Word;
  IpAdresDW: LongWord;
begin

  i := Length(AData);
  if(i > 0) then
  begin

    DNSHeader := TDNSHeader.Create;

    if(DNSHeader.ParseQuery(AData) = 0) then
    begin

      idDNSYanitlayici.ParseAnswers(DNSHeader, AData);

      DNSAdi := idDNSYanitlayici.QueryResult.DomainName;

      mmSonuc.Lines.Add(Format('"%s" DNS adı için IP adresi isteniyor...', [DNSAdi]));
      mmSonuc.Lines.Add(Format('İstemci IP Adresi: %s:%d', [ABinding.PeerIP, ABinding.PeerPort]));

      IPAdres := DNSAdSorgula(DNSAdi);
      if(Length(IPAdres) > 0) then
      begin

        // tek bir sorgu ayanıtı isteniyorsa, cevapla
        QDCount := DNSHeader.QDCount;
        if(QDCount = 1) then
        begin

          SorguTipi := GStack.NetworkToHost(idDNSYanitlayici.QueryResult.QueryType);
          if(SorguTipi = TypeCode_A) then
          begin

            SorguSinifi := GStack.NetworkToHost(idDNSYanitlayici.QueryResult.QueryClass);
            if(SorguSinifi = Class_IN) then
            begin

              ID := DNSHeader.ID;
              BitCode := $8180;       // DNS yanıt
              ANCount := 1;           // yanıt sayısı
              NSCount := 0;
              ARCount := 0;

              SetLength(DNSYanit, 12);
              CopyTIdWord(GStack.NetworkToHost(ID), DNSYanit, 0);
              CopyTIdWord(GStack.NetworkToHost(BitCode), DNSYanit, 2);
              CopyTIdWord(GStack.NetworkToHost(QDCount), DNSYanit, 4);
              CopyTIdWord(GStack.NetworkToHost(ANCount), DNSYanit, 6);
              CopyTIdWord(GStack.NetworkToHost(NSCount), DNSYanit, 8);
              CopyTIdWord(GStack.NetworkToHost(ARCount), DNSYanit, 10);

              mmSonuc.Lines.Add(Format('Yanıt IP Adresi: %s', [IPAdres]));
              mmSonuc.Lines.Add('--------------------------------------------');

              // sorgulanması istenen DNS adı
              while Length(DNSAdi) > 0 do begin
                s := Fetch(DNSAdi, '.');
                i := Length(s);
                AppendByte(DNSYanit, i);
                AppendString(DNSYanit, s, i);
              end;
              AppendByte(DNSYanit, 0);        // 0 sonlandırama

              // tip ve sınıf kodu
              Ekle2Byte(DNSYanit, TypeCode_A);
              Ekle2Byte(DNSYanit, Class_IN);

              // $c0, $0c
              Ekle2Byte(DNSYanit, $C00C);
              Ekle2Byte(DNSYanit, TypeCode_A);
              Ekle2Byte(DNSYanit, Class_IN);

              // yaşam süresi (TTL), 12 dakika
              Ekle4Byte(DNSYanit, 12 * 60);

              // DNS adresinin IP adres karşılığı
              Ekle2Byte(DNSYanit, $0004);           // veri uzunluğu, 4 bytelık IP adresi
              IpAdresDW := IPv4ToDWord(IPAdres);
              Ekle4Byte(DNSYanit, IpAdresDW);

              AThread.Binding.SendTo(ABinding.PeerIP, ABinding.PeerPort, DNSYanit);

              Inc(YanitlananIstekSayisi);
            end
            else
            begin

              mmSonuc.Lines.Add('Hata: uygulama Class_IN sorgu haricinde yanıtlama yapamaz!');
              mmSonuc.Lines.Add('--------------------------------------------');
              Inc(YanitlanamayanIstekSayisi);
            end;
          end
          else
          begin

            mmSonuc.Lines.Add('Hata: uygulama TypeCode_A sorgu haricinde yanıtlama yapamaz!');
            mmSonuc.Lines.Add('--------------------------------------------');
            Inc(YanitlanamayanIstekSayisi);
          end;
        end
        else
        begin

          mmSonuc.Lines.Add('Hata: çoklu sorgu yanıtı isteniyor!');
          mmSonuc.Lines.Add('--------------------------------------------');
          Inc(YanitlanamayanIstekSayisi);
        end;
      end
      else
      begin

        mmSonuc.Lines.Add('Hata: istenen DNS adresi adres listesinde mevcut değil!');
        mmSonuc.Lines.Add('--------------------------------------------');
        Inc(YanitlanamayanIstekSayisi);
      end;

      SetLength(DNSYanit, 0);
    end
    else
    begin

      mmSonuc.Lines.Add('Hata: DNS veri yapısı istenen biçimde değil!');
      mmSonuc.Lines.Add('--------------------------------------------');
      Inc(YanitlanamayanIstekSayisi);
    end;

    IstekSayisiniGuncelle;

    FreeAndNil(DNSHeader);
  end;
end;

procedure TfrmAnaSayfa.IstekSayisiniGuncelle;
begin

  lblYanitlananIstekSayisi.Caption := Format('Yanıtlanan İstek Sayısı: %d', [YanitlananIstekSayisi]);
  lblYanitlanamayanIstekSayisi.Caption := Format('Yanıtlanamayan İstek Sayısı: %d', [YanitlanamayanIstekSayisi]);
end;

procedure TfrmAnaSayfa.Ekle2Byte(var AHedef: TIdBytes; const ADeger: Word);
begin

  AppendByte(AHedef, Byte(ADeger shr 8));
  AppendByte(AHedef, Byte(ADeger and $FF));
end;

procedure TfrmAnaSayfa.Ekle4Byte(var AHedef: TIdBytes; const ADeger: DWord);
begin

  AppendByte(AHedef, Byte(ADeger shr 24));
  AppendByte(AHedef, Byte(ADeger shr 16));
  AppendByte(AHedef, Byte(ADeger shr 8));
  AppendByte(AHedef, Byte(ADeger and $FF));
end;

end.

