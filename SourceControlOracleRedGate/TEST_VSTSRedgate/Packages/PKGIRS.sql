CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGIRS" 
as
function fncIRSGetInterestRate(
        VarReference in varchar2,
        intSerialNumber in number,
        datStartDate in date,
        datEndDate in Date,
        intIntType in number,
        datAson    in Date,
        frwdMonth in number :=0)
        return number ;

function fncIRSIntCalcforperiod(
      datintStartDate in Date,
      datintendDate in Date,
      varReference in varchar,
      SerialNumber in number,
      numIntRate in number,
      numIntDaysType in number)
      return  number;

function fncIRSIntCalcualtion (
         datintStartDate in date,
         datintendDate in Date, 
         numPrincipalAmount in number,
         numIntRate in  number,
         numIntChargeType in number)
         return number;

function fncIRSOutstanding(
      datintStartDate in Date,
      datintendDate in Date,
      varReference in varchar,
      SerialNumber in number)
      return  number;    

function days360(
       p_start_date           date,
       p_end_date             date,
       p_rule_type            char default 'F'
       )
    RETURN number;   

function fncGetInterestRate(
        datStartDate in date,
        datAson    in Date,
        RateType in number,
        currencyCode Number)
        return number ;
        
end PKGIRS;
 
 
 
 
/