CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate".PKGFXCURRENTINTERFACE as

    
function fncgetfiscalyear(workdate in date)
return varchar2;

    
--Function fncCompanyCode
--    (   CompanyCode in Number)
--    return varchar2;
    
Function fncExchangeRate
    (   VoucherReference in varchar2, 
        VoucherSerial in number,
        AccountCode in number)
    return number;


Function fncFXExchangeRateBC(datCreateDate in Date)
    return varchar2;
    
    
Function fncAccountHead
   (   BankCode in number ,
        AccountHead in number,
        CreditDebit in number default 14699999,
        CurrencyCode in number default 20599999,
        LOBCode in Number default 32699999,
        EventType in Number default 24899999,
        LoanType in number Default 23699999,
        AccountNumber in varchar2 default 'NA',
        BuySell in number  Default 26899999)
        return varchar2;
    
Function fncAccountNumber
    (   BankCode in number,
        AccountHead in number,
        CreditDebit in number)
    return varchar2;
--    
--Function fncFXExchangeRate(datCreateDate in Date)
--    return varchar2;
    
    
--Function fncGeneralFormat
--    (   VoucherReference in varchar2,
--        VoucherSerial in number)
--    return varchar2;
    
    
Function fncAuditTrail
    (   ErrorText in varchar2,
        datWorkDate in date default sysdate)
    return number;
    


--Function fncCostCenter 
--    (   numCompanyCode in number,
--        numLocationCode in number,
--        numLOBCode in number,
--        numEventType in number
--    )
--    return Varchar2;
--Function fncSettlementStatus(
--    varInvoiceNumber in varchar2
--    )
--    return varchar2;

    
-- Function fncCrossCurrencyGainLoss
--    (  
--        varInvoiceNumber in varchar2,
--        varSerialNumber in number,
--        numAccountHead in number,
--        numCurrencyCode in Number
--    )
--    return number;

    
--  gFileName               varchar2(30);
--  gVoucherReference       Varchar2(25);
--  Gpackagename            Varchar2(30);
--  gFormatTypes            varchar2(50);
--  gTimeStamp              varchar2(25);
--  gInvoiceNumbers         varchar2(256);
--  gVoucherSerial          number(5);
--  gVoucherEvent           number(8);
--  gLocalBank              number(8);
--  gVoucherDate            date;
--  gProcessComplete        number(8);
--  gCompletionDate         date;
--  gCredit                 number(15,4);
--  gDebit                  number(15,4);
    

    
--procedure  prcRunInterface (datCurrentDate in Date);

Function fncFXDealBuysell
    (   varDealNumber in varchar2,
        SerialNumber in Number)
        return number;    
Function fncRunInterface
    (   
      VoucherDate in Date
    )
    return number;

Function fncTreasuryFWD    
    (   datCreateDate in Date)
    return varchar2;
    
Function fncTreasuryOpt    
    (   datCreateDate in Date)
    return varchar2;
    
Function fncTreasuryIRS    
(   datCreateDate in Date)
return varchar2;
--Function fncCCSCashFlow    
--    (   datCreateDate in Date)
--      return varchar2;
      
  gFileName               varchar2(30);
  gVoucherReference       Varchar2(25);
  Gpackagename            Varchar2(30);
  gFormatTypes            varchar2(50);
  gTimeStamp              varchar2(25);
  gInvoiceNumbers         varchar2(256);
  gVoucherSerial          number(5);
  gVoucherEvent           number(8);
  gLocalBank              number(8);
  gVoucherDate            date;
  gProcessComplete        number(8);
  gCompletionDate         date;
  gCredit                 number(15,4);
  gDebit                  number(15,4);
  
  

end PKGFXCURRENTINTERFACE;
/