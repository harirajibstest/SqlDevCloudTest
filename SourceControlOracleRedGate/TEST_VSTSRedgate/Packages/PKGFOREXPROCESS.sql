CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGFOREXPROCESS" as

--  Created on 23/04/2008

Function fncInsertDeals
    ( AsonDate in Date)
    Return number;

Function fncInsertDeals
    ( AsonDate in Date,
    userid in varchar)
    Return Number;
FUNCTION Fncmintrate
  (Asondate In Date,Basecurrency In Number,Forcurrency In Number) 
    Return Number ;  
    
Function fncGetRate
    ( CurrencyCode in Number,
      ForCurrency in Number,
      AsonDate in Date,
      BidAsk in Number,
      RateType in number := 0,
      DueDate in Date := null,
      RateSerial in Number := 0)
      Return Number;
FUNCTION fncGetCurrSpotDate
            ( CurrencyCode IN Number,
              ForCurrency IN Number,
              DateAson IN Date,
               NumberOfDays in Number Default 4)
              RETURN Date ;
function fncGetIRSRate(Effectivedate date,
                       SettlementDate date,
                       RateType number)
         return number;
--Function fncHoldingRate
--    ( CurrencyCode in Number,
--      AsonDate in Date,
--      ErrorNumber in out nocopy number,
--      UserID in varchar2 := NULL)
--    Return number;

Function fncCalculateRate
    ( RateDetail in clob)
    Return number;

Function fncCalculateRate
    ( RateDate  Date,
      BaseCurrency in Number,
      ForCurrency in Number,
      SerialNumber in Number)
    Return number;

  --  Function fncGetOptionMTM
    --( DealNumber in varchar2,
    --  AsonDate in Date)
    --  return number;
    Function fncGetOptionMTM
    (DEALNUMBER IN VARCHAR2,
      ASONDATE IN DATE,CHECKDATA IN CHAR DEFAULT 'Y')
      return number;

FUNCTION GETCOUNTERPARTY(REFNO IN VARCHAR)
RETURN VARCHAR2 ;

Function fncAllotMonth
    (   AsonDate in Date,
        MaturityDate in Date)
    Return number;

Function fncAllotMonth
    (   CounterParty in number,
        AsonDate in Date,
        MaturityDate in Date)
    Return Number;
Function fncCommAllotMonth
    (   AsonDate in Date,
        MaturityDate in Date)
    Return Number;
Function fncRiskGenerate
    (   AsonDate in date,
        DealType in number)
    Return number;

Function fncRiskPopulate
    (AsonDate in date,
    DealType in number)
    return number;

    function fncPurchaseContractOS
      (TradeReference in varchar,
      AsonDate in date,
      Maturity in Date,
      Contractno in varchar) return number;


Function fncHedgeRisk
    ( WorkDate in Date)
    Return Number;

Function fncRiskLimit
    ( AsonDate in Date,
      RiskType in number,
      CrossCurrency in number := 12400000)
      return number;

Function fncPositionGenerate
    (USERID IN VARCHAR2,
     ASONDATE IN DATE,
     VARCOMPCODE VARCHAR2 DEFAULT '30199999' ,
     varcurcode varchar2 default '30499999' ,
     varprodcode varchar2 default '33399999' ,
     varsubprodcode varchar2 default '33899999',
     varLocationcode varchar2 default '30299999',
     ConvertToCurrency in number := 30400004 ,
     ConvertToLocalCurrency in number := 30400003)
   return number;

    Function fncRbiReport
    ( UserID in varchar2,
      AsonDate in date)
    return number;

Function fncGetSpotDate
    ( CounterParty in number,
      AsonDate in Date,
      AddDays in number := 0)
      return Date;

 Function fncGetSpotDueDate
    ( CounterParty in number,
      AsonDate in Date,
      SubDays in number := 0)
      return Date;


Function fncGetOutstanding
    ( TradeReference in varchar2,
      TradeSerial in number,
      ReversalType in number,
      AmountType in number,
      AsonDate in Date,
      DealReference in varchar2 := NULL,
      subSerial in number :=0)
      return Number;
Function fnccommoditymtmrate
          ( DealMaturityDate in date,
            Exchangecode in number,
            ProductCode in number,
            asondate in date)
      Return number ;

function fncCommMarginAmount
          (Dealnumber in varchar2,
          AsOnDate in date,
          MarginType in number)
    return number;
function fncGetCommPandL
          (Dealnumber in varchar2,
           ProfitType in number)
    return number;
function fncCommDealRate
         (DealNumber in varchar2,
          asondate in date default null )
    return number;
---Currency Futures
Function fncFutureMTMRate
          ( DealMaturityDate in date,
            Exchangecode in number,
            BaseCurrency in number,
            OtherCurrency in Number,
            asondate in date)
      Return number ;

function fncFutureMarginAmount
          (Dealnumber in varchar2,
          AsOnDate in date,
          MarginType in number)
    return number;
function fncGetFuturePandL
          (Dealnumber in varchar2,
           ProfitType in number)
    return number;

function fncFutureDealRate
         (DealNumber in varchar2,
          asondate in date default null )
    return number;
function fncUserDetails
  (varUserIDs in varchar)
    return varchar;
function fncGetprofitLossOptions
  (varReference in varchar,
   refRate in number,
   numBaseAmount in number,
   datEffectDate in date,
   numSerial in out nocopy number,
   numPLFCY in out nocopy number,
   numPLLocal in out nocopy number,
   varRemarks in out nocopy varchar,
   ReverseSerial in number default 1)
   return number;

function fncGetprofitLossOptions  --added on 22/03/12 for OPTMTMEXCHNGSTMT
  (varReference  in varchar,
   refRate       in number,
   numBaseAMount in number,
   datEffectDate in date)
   return number;

function fncCalFuturePandL
    (buysell number,
     Lot number,
     LotRate number,
     ReverseRate number)

    return number;
    function  fncgetprofitloss(
     baseamount in  number,
     m2mrate     in number,
     exchangerate in number,
     buysell in number
     )return number ;

    Function  Fncgetprofitlossoptnetpandl(
     Dealnumber In Varchar2,
     Serialno in number
     )return number ;
     
     Function  Fncgetprofitlossoptnetpandl(
     Dealnumber in varchar2,Serialno in number,
     AsonDate date 
     )return number;
     
 function fncGetMFNav(DatDate date,
                      navCode varchar2)
            return number;
FUNCTION fncLastWorkingDate_Month
            ( CurrencyCode IN Number,
              ForCurrency IN Number,
              DateAson IN Date)
              RETURN Date ;

--RateReturnType
-- 1 Custom Rate
-- 2 Cross Rate
-- 3 Spot Rate / Marketing Plan Rate
-- 4 Budget Rate
PROCEDURE prcgetchargeamount
    (clbdetails in clob ,
    errorcode out number) ;
    
function fncGetCustomRate(
    datEffectiveDate in date,
    numCurrency in number,
    numBuysell in number, -- Import Export
    numRateReturnType in number) return number;
End pkgForexProcess;
/