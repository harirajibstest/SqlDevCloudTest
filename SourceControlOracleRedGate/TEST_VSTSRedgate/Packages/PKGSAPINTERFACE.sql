CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGSAPINTERFACE" as

-- procedure PrcPushDataFrmSap;
--
-- Procedure PrcPushDataFrmSynnovate;

 function  fncGetPickCode(KeyGroup in number, SapCode in varchar2) return number;

 function fncgetFianacialYear( datDate in date)   return varchar;

function fncGenerateKeyNum(PONumber in varchar,datDate in date)return varchar;
   
FUNCTION fncGetCalendarDate1(EffectiveDate DATE, CurrencyCode NUMBER, ForCurrency NUMBER) RETURN DATE;
function fncgetcompanycode(companycode in number,numtype in number) return number;
procedure prcCurrentACInterface( datParmDate in date := null);
 function fncGetSchemeNavCode( varreference in varchar,numevent in number ,numcrdr in number )  return varchar2;
  function fncgetAccountCode(
                  LocalBank in number,
                  AccountType in number,
                  AccountEvent in number,
                  VoucherReference in varchar,
                  numcrdr in number)
           return varchar;
  function fncGetCounterpartyName(
                  varreference in varchar,
                   AccountEvent in number)
                return varchar;
 function fncgetusername(varuserid in varchar2) return varchar2;
 function fncgetinvestmenttype(eventtype in number) return varchar2;
 function fncgetcurrentacdetails(
                  varevent in number,referencenumber in varchar2, varaccountnumber in
varchar2,vartype in number) return varchar2;

   procedure prcErrorinsertinto8G(
                 InSRNo in number,
                 Erro_msg in varchar,
                 datWorkDate in date);
 end pkgsapinterface;
 
 
 
 
/