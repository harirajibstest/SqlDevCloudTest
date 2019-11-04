CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGRETURNCURSOR" 

    is
--  Created on 11/03/2007
--  Last Modified on 19/03/2007


   Function fncgetShortcutNumber
     (ShortCut in number,
      ShortCutKey in number)
      return number;
    Function fncReturnCursor
        (   XMLParam in GConst.gXMLType%Type)
        Return GConst.DataCursor;

    Function fncGetDescription
        (   PickKeyValue in number,
            DescriptionType in number)
        Return varchar2;

    FUNCTION  fncGetSettlementRate 
        ( TradeReference in Varchar2,
          SerialNumber in Number) 
          return number;         


   FUNCTION  fncGetHumanReadableFileSize 
        (P_Size In Number) 
return VARCHAR2     ;

--
--    Function fncGraphCursor
--        (   UserIDs in Varchar2,
--            CurrencyCode in number,
--            AsonDate in Date)
--        Return number;
   Function fncGenerateStatement
    (   WorkDate in date,
        CompanyCode in number,
        BankCode in number,
        FromDate in date,
        ToDate in date,
        Consolidate in number := 12400002)
        Return number;

    Function fncReturnACL
        (   ACLList in varchar2)
        return varchar2;



--    Function fncRiskGenerate
--        (   AsonDate in date,
--            DealType in number)
--    return number;
    Function fncRollover
        (   dealnumber in varchar2,
            ReturnType in number)
        Return number;
    Function fncRollover
        (   dealnumber in varchar2)
        return date;

     function fncDealProfile(DealNumber varchar2)
         return number ;

    Function fncMTMRate
    (   DealNumber  in varchar2,
        DealType in number,
        MTMType in number,
        AskRate in number := 0,
        BidRate in number := 0,
        WashRate in number := 0)
    return number;


    Procedure prcGetDictionary
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out NoCopy Gconst.gClobType%Type,
            ProcessData out NoCopy Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor,
            NextCursor  out Gconst.DataCursor);
            
      


    Procedure prcReturnCursor
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out NoCopy Gconst.gClobType%Type,
            ProcessData out NoCopy  Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor);

    BASEAMOUNT   CONSTANT number(1) := 1;
    EXCHANGERATE CONSTANT number(1) := 2;
    OTHERAMOUNT  CONSTANT number(1) := 3;
    LOCALRATE    CONSTANT number(1) := 4;
    AMOUNTLOCAL  CONSTANT number(1) := 5;
End; -- Package spec
/