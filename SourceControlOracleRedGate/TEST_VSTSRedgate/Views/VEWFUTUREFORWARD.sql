CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfutureforward (dealnumber,dealref,buysell,companycode,companyname,bankcode,bankname,dealdate,dealamount,currency,exrate,maturity,canceldate,cancelrate,pandlfcy,status,completedate,transcode,trans,hedgetrade,userid,initcode,dealtype) AS
select a."DEALNUMBER",a."DEALREF",a."BUYSELL",a."COMPANYCODE",a."COMPANYNAME",a."BANKCODE",a."BANKNAME",a."DEALDATE",a."DEALAMOUNT",a."CURRENCY",a."EXRATE",a."MATURITY",a."CANCELDATE",a."CANCELRATE",a."PANDLFCY",a."STATUS",a."COMPLETEDATE",a."TRANSCODE",a."TRANS",a."HEDGETRADE",a."USERID",a."INITCODE", 32200001 DealType 
  from vewforwards a
union all
select b."DEALNUMBER",b."DEALREF",b."BUYSELL",b."COMPANYCODE",b."COMPANYNAME",b."BANKCODE",b."BANKNAME",b."DEALDATE",b."DEALAMOUNT",b."CURRENCY",b."EXRATE",b."MATURITY",b."CANCELDATE",b."CANCELRATE",b."PANDLFCY",b."STATUS",b."COMPLETEDATE",b."TRANSCODE",b."TRANS",b."HEDGETRADE",b."USERID",b."INITCODE", 32200002 DealType 
  from vewFutures b
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;