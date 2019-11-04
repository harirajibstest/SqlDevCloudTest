CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate".PKGRISKMONITORING AS 

Function fncRiskLimit
    ( AsonDate in Date,
      RiskType in number,
      CrossCurrency in number := 12400000)
      return number;

Function fncRiskGenerate
    ( AsonDate in date,
      DealType in number)
      return number;

Function fncRiskPopulate
    (AsonDate in date,
    DealType in number)
    return number;
    
Function fncRiskPopulateGAP
    (asonDate in date)
    return number;

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
PROCEDURE prcDueDateAlert
    (EmailTrigger in number default 12400002);

END PKGRISKMONITORING;
/