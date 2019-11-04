CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoutstandingcontracts (categorycd,contractno,vendor,quantity,price,contractdate,paymentterm,bank,contractvalue,outstandingamount) AS
select
Pkgreturncursor.Fncgetdescription(Conr_Product_Category,1) As "CATEGORYCD",
CONR_USER_REFERENCE  as "CONTRACTNO",
pkgreturncursor.fncgetdescription(conr_BUYER_SELLER,2) as "VENDOR",
To_Char(Conr_Total_Quantity,'999,999.99') As "QUANTITY",
conr_PRODUCT_RATE as "PRICE",
To_Char(Conr_Reference_Date,'dd-mm-yy') As "CONTRACTDATE",
 Pkgreturncursor.Fncgetdescription(Conr_Payment_Terms,1) As "PAYMENTTERM",
   Pkgreturncursor.Fncgetdescription(conr_local_bank,2) As  "BANK",      
to_char(CONR_BASE_AMOUNT,'999,999,999.99') as "CONTRACTVALUE", 
To_Char(Conr_Base_Amount- (nvl((Select 
                           sum(brel_reversal_fcy)
                          From Trtran002 a ,Trtran003 b
                          Where a.Trad_Trade_Reference=b.brel_Trade_Reference
                          And a.Trad_Contract_No=CONR_USER_REFERENCE
                         -- and to_char(a.trad_maturity_date,'yyyymm')= to_char(b.brel_entry_date,'yyyymm')
                          And a.Trad_Record_Status In (10200005,10200006)
                          And b.Brel_Record_Status Not In (10200005,10200006)),0)),'999,999,999.99') as "OUTSTANDINGAMOUNT"
from
trtran002c
 
 
 
 
 
 
 
 
 
 
 
 
 ;