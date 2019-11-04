CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewunderlyings (company,bank,tradedate,traderef,customer,trans,product,notional,delivery1,delivery2,pterms) AS
select pkgReturnCursor.fncGetDescription(trad_company_code,2) Company,
pkgReturnCursor.fncGetDescription(trad_local_bank,2) Bank,
trad_reference_date TradeDate, trad_user_reference TradeRef,
pkgReturnCursor.fncGetDescription(trad_buyer_seller,2) Customer,
pkgReturnCursor.fncGetDescription(trad_import_export,2) Trans,
pkgReturnCursor.fncGetDescription(trad_product_code,2) Product,
trad_trade_fcy Notional, trad_maturity_from Delivery1,
trad_maturity_date Delivery2, trad_maturity_month Pterms
from trtran002
order by trad_reference_date
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;