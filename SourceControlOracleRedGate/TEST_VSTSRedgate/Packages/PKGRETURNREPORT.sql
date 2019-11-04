CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGRETURNREPORT" AS
  /* ramya updates 7-02-08*/
  /* TODO enter package declarations (types, exceptions, methods etc) here */

  Procedure prcExtractReport
    (   ParamData   in  Gconst.gClobType%Type,
        ErrorData   out NoCopy Gconst.gClobType%Type,
        ProcessData out NoCopy Gconst.gClobType%Type,
        GenCursor   out Gconst.DataCursor,
        NextCursor  out Gconst.DataCursor,
        CursorNo3   out Gconst.DataCursor,
        CursorNo4   out Gconst.DataCursor,
        CursorNo5   out Gconst.DataCursor,
        CursorNo6   out Gconst.DataCursor);

  function GetSystemDate return date;
    function getCondition
  ( periodtype  number,
    refdate  date,
    flag number
   ) return date;
Function getCompanyName(userid varchar) return varchar2 ;

function fncConvRs
             (num in number,
             numofDec in number default 2,
             currency in number default 30400003)
             return varchar;
   function  fncgetprofitloss(
              baseamount in  number,
              m2mrate   in number,
              exchangerate in number,
               buysell in number)
              return number  ;
  function  fungetdealconsolidation(
                      frmdate in date)
                      return number;

function getRolloverStatus (
                      dealnumber varchar2,
                      asonDate date)
                      return varchar2;

--function  fnc_frwcontract
--  (frmDate date,ToDate date) return number;
--
--function  fnc_optioncontract
--          (frmDate date,ToDate date) return number;


function getTradeOutstanding(
                      dealnumber in varchar2,
                      frmDate date,
                      todate date,
                      canceldate date,
                      serialno number)
                      return number;
function fncGetProductDetails(
                productCode in number,
                maturityDate in date,
                exchCode in number,
                pickValue in number )
                return varchar;
function fncGetOustanding
(frmDate date,
finalCondition varchar) return number;

function  fnc_optioncontract
          (frmDate date default to_date('01/03/1900', 'dd/mm/yyyy'), ToDate date default sysdate) return number;

--function  fnc_optioncontractnew
--          (frmDate date default to_date('01/03/1900', 'dd/mm/yyyy'), ToDate date default sysdate) return number;

function  fnc_frwcontract
         (frmDate date default to_date('01/03/1900', 'dd/mm/yyyy'), ToDate date default sysdate) return number;
FUNCTION fnc_updateoptionrownum
return number;

function  fncOrderHedgeDetails(
             companyCode    number,
             buySell        number,
             currencyCode   number,
             counterParty   number)
  return number;

  function  fnc_totlinkagerep
          (frmDate date default to_date('01/03/1900', 'dd/mm/yyyy'),
           ToDate date default sysdate)
   return number;

   Function getCompanyNameFooter return varchar2 ;

function fncFundFlow (frmDate in date )
         return number;

END PKGRETURNREPORT;
/