CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncGetPremium (asonDate Date,BusinessUnit number,UserID varchar2) RETURN Number 
AS 
  numPremium    number(15,6);
  noDays        number(3);
BEGIN
  noDays := asonDate - trunc(asonDate,'MONTH');
  SELECT Round((sum((pkgForexProcess.fncGetOutstanding(deal_deal_number,
        deal_serial_number,GConst.UTILTRADEDEAL,GConst.AMOUNTFCY,asonDate) * 
        (deal_forward_rate /(deal_maturity_date - deal_execute_date)) * noDays))/
        sum(pkgForexProcess.fncGetOutstanding(deal_deal_number,
        deal_serial_number,GConst.UTILTRADEDEAL,GConst.AMOUNTFCY,asonDate))),6)
    into numPremium
  FROM TRTRAN001
  where  deal_execute_date <= asonDate
  and deal_hedge_trade in (GConst.HEDGEDEAL, GCONST.FTDEAL)
  and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
  and deal_record_status in(GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
  and ((deal_complete_date is null) or (deal_complete_date > asonDate))
  and deal_deal_type not in(25400001)
  AND deal_backup_deal    = BusinessUnit;
return numPremium;
end;
/