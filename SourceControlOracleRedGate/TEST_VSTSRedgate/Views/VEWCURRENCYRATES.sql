CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewcurrencyrates (effectivedate,currencycode,currencyname,usdbid,usdask,inrbid,inrask) AS
select a.rate_effective_date EffectiveDate, a.rate_currency_code CurrencyCode, 
pkgReturnCursor.fncGetDescription(a.rate_currency_code,2) CurrencyName,
a.rate_spot_bid USDBid, a.rate_spot_ask USDAsk,
round(b.rate_spot_bid * a.rate_spot_bid,4) INRBid , round(b.rate_spot_ask * a.rate_spot_ask,4) INRAsk
from trsystem009 a, trsystem009 b
where a.rate_effective_date = b.rate_effective_date
and b.rate_currency_code = 30400003
and b.rate_for_currency = 30400004
and a.rate_currency_code not in (30400004,30400003)
union
select rate_effective_date, 30400004 CurrencyCode,
'USD', 1.00 USDBid, 1.00 USDAsk, rate_spot_bid INRBid, rate_spot_ask INRAsk
from trsystem009
where rate_currency_code = 30400003
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;