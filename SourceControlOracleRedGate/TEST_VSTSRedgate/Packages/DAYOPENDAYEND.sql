CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."DAYOPENDAYEND" AS
Procedure prcdayopen(workingdate in date,
                    locationcode in number,
                    numCompanyCode in number);
procedure prcdayclose(workingdate in date,
                     userid varchar);
--procedure prcCheckingReminders
--            (workingDate in date);
procedure prcHolidaysCheck
            (executiondate in date,
             BaseCurrency in number,
             OtherCurrency in number,
             delivaryType in number default 0 ,
             delivaryOption in number default 0,
             delivarydays in number default 0,
             delivarydate in date default sysdate,
             dateFrom in out date,dateTo in out date);

function fncBankHolidayCheck
          (AsonDate in date,
          CounterParty in number) return date;

Function prcCalculateHoldingrate
            (CurrencyCode in Number,
             AsonDate in Date)
             return number;
function fnccalcHedgeAmount
             (hedgecurrency in number,
              basecurrency in number,
              hedgeamount in number,
              baseamount in number,
              exeutiondate in date,
              buyorsell in number) return number;
FUNCTION fnccheckHolidays(fromdate in date,dateType in number default 0) return date;
function fncConvRs
             (num in number,
              numofDec in number)
              return varchar;
function fncCreateParamDate
             (reportid in varchar,
              Condition in varchar,
              asondate in date,
              todate in date) return  Gconst.gClobType%Type;
function getCondition
             (workdate in date,
              numgroup in number,
              numperiod in number default 0 ) return varchar;
procedure prcCalcBrokerCharges
              (workdate in date);
function FNCSAPOTHER(DATWORKDATE IN DATE) return number;
FUNCTION fncforwardoutstanding(DATWORKDATE IN DATE) RETURN NUMBER;
END DAYOPENDAYEND;
/