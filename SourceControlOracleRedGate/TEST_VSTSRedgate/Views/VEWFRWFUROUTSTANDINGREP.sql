CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfrwfuroutstandingrep (company,dealnumber,executedate,maturitydate,initiator,tradtype,trader,currency,buysell,baseamount,exchangerate,spot,"FORWARD",margin,counterparty,outstanding,m2mrate,washrate,mtmamount,remark,status) AS
SELECT Companyname AS Company,
    Dealnumber,
    Dealdate                                      AS Executedate,
    Maturity                                      AS Maturitydate,
    Trans                                         AS Initiator,
    Hedgetrade                                    AS Tradtype,
    Pkgreturncursor.Fncgetdescription(Initcode,2) AS Trader,
    Currency,
    Buysell,
    Dealamount AS Baseamount,
    Exrate     AS Exchangerate,
    Spot       AS Spot,
    Forward    AS Forward,
    MARGIN     AS Margin,
    Bankname   AS Counterparty,
    Balancefcy AS Outstanding,
    M2mrate,
    Washrate,
    Mtmpandlinr  AS Mtmamount,
    Dealref      AS Remark,
    Recordstatus AS Status
  FROM Vewforwardfuture
  WHERE ((Status   = 12400001
  AND CompleteDate >Fncasondate())
  OR Status        = 12400002)
 
 
 
 ;