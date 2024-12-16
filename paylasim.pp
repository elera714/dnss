unit paylasim;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils;

type
  TDNSAdresListesi = record
    DNSAdi,
    IPAdresi: string;
  end;

// örnek DNS ad - ip listesi
const
  DNSAdresListesi: array[0..1] of TDNSAdresListesi = (
    (DNSAdi: 'turkiye.gov.tr'; IPAdresi: '94.55.118.33'),
    (DNSAdi: 'lazarus-ide.org'; IPAdresi: '37.97.187.115'));

function DNSAdSorgula(ADNSAdi: string): string;

implementation

function DNSAdSorgula(ADNSAdi: string): string;
var
  DNS: TDNSAdresListesi;
  i: Integer;
begin

  Result := '';
  i := SizeOf(DNSAdresListesi);
  if(i < 1) then Exit;

  for DNS in DNSAdresListesi do
  begin

    if(DNS.DNSAdi = ADNSAdi) then Exit(DNS.IPAdresi);
  end;
end;

end.
