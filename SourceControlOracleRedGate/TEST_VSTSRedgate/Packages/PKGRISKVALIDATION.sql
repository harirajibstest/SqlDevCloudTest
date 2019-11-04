CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGRISKVALIDATION" as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
 
--  procedure prcvalidation
--      (varmessage out varchar2) ;
  Function fncBuildQuery
      (numRiskType in number) return varchar2;
  procedure prcRiskPopulateNew
      (AsonDate in date);
  Function fncgetUserEmailID 
      (varUserids in varchar2) return varchar2;
    procedure prcActiononRisk(datWorkDate in date);
  Function fncRiskPopulateGAP
    (asonDate in date)
    return number;
  Procedure PRCExchangeRateVaR  
        (AsonDate in date,
       NoofDays in Number);
      
  function fncGetHedgeRate 
  (datReferenceDate in date,
   CompanyCode in number,
   LocationCode in Number,
   PortfolioCode in Number,
   SubPortfolioCode in Number,
   CurrencyCode in Number,
   ForCurrency in Number,
   MaturityDate in date)
      return number;

Function fncRiskAdjustedMTMRate
       (CurrencyCode in number,
        ForCurrency in Number,
        BuySell in Number,
        AsonDate in Date,
        MaturityDate in date )
      return number;
END PKGRISKVALIDATION;
 
 
 
 
/