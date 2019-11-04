CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGVARANALYSIS" AS
FUNCTION FIRSTPOSITION( USERID IN VARCHAR2) RETURN NUMBER;
FUNCTION FNCGETDUEDAT(NUMLOCATIONCODE IN NUMBER ,DATWORKDATE IN DATE ,DATGETRATE IN DATE ,DATDUEDATE IN DATE) RETURN DATE;

FUNCTION GETRATEINDEX( DATWORKDATE IN DATE,DATfromDATE in date default null) RETURN NUMBER;

FUNCTION FNCPOSITIONGENERATE( USERID IN VARCHAR2, ASONDATE IN DATE) RETURN NUMBER ;
 RETURN NUMBER;
 FUNCTION FNCGETVAR(USERID IN VARCHAR2 ,datfromdate in date,DATWORKDATE IN DATE) RETURN NUMBER;
   Function fncStressPositionGenerate
    ( USERID IN VARCHAR2,  ASONDATE IN DATE, STRESSREFERENCENUMBER IN VARCHAR2,
    VARCOMPCODE VARCHAR2 DEFAULT '30199999' ,  VARCURCODE VARCHAR2 DEFAULT '30499999' ,
    VARPRODCODE VARCHAR2 DEFAULT '33399999' ,VARSUBPRODCODE VARCHAR2 DEFAULT '33899999' )
     return number ;
 Function fncStressGetRate
    ( CurrencyCode in Number,
      ForCurrency in Number,
      AsonDate in Date,
      BidAsk in Number,
      RateType in number := 0,
      DueDate in Date := null,
      Rateserial In Number := 0)
      Return Number ;

 FUNCTION FNCPOPULATESTRESSRATE(VARREFERENCENUMBER IN VARCHAR2 ,DATWORKDATE IN DATE)
 RETURN NUMBER;
 Function fncGetRate
    ( CurrencyCode in Number,
      ForCurrency in Number,
      AsonDate in Date,
      BidAsk in Number,
      DueDate in Date := null,
      RateSerial in Number := 0,duedateadd in number :=0)
      Return Number;

function fncSTRESSFutureMTMRate(
             DealMaturityDate in date,
             Exchangecode in number,
             BaseCurrency in number,
             OtherCurrency in number,
             asondate in date,
             rundate in date default null) 
             RETURN number ;
function fncpopulateratealert(DATWORKDATE in date)
return number;
procedure prcpopulateratealert (DatdayOpenDate in date :=null);
END PKGVARANALYSIS;
 
 
 
 
 
 
 
 
 
 
/