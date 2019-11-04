CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewcanceldeals (companycode,dealnumber,hedgetrade,dealamount,dealdate,basecurrency,othercurrency,initiator,trader,serialnumber,canceldate,cancelamount,profitloss,dealtype) AS
select deal_company_code CompanyCode, deal_deal_number DealNumber, deal_hedge_trade HedgeTrade, deal_base_amount DealAmount, deal_execute_date DealDate,
deal_base_currency BaseCurrency, deal_other_currency OtherCurrency, deal_backup_deal Initiator, deal_init_code Trader,
cdel_reverse_serial SerialNumber, cdel_cancel_date CancelDate, cdel_cancel_amount CancelAmount,cdel_profit_loss ProfitLoss, 'Forward' DealType
from trtran001, trtran006
where deal_deal_number = cdel_deal_number
and deal_record_status between 10200001 and 10200004
and cdel_record_status between 10200001 and 10200004
union all
select cfut_company_code, cfut_deal_number, cfut_hedge_trade, cfut_base_amount DealAmount, cfut_execute_date,cfut_base_currency,
cfut_other_currency, cfut_backup_deal, cfut_init_code,
cfrv_reverse_serial, cfrv_execute_date, cfrv_cancel_amount,cfrv_profit_loss, 'Future' DealType
from trtran061, trtran063
where cfut_deal_number = cfrv_deal_number
and cfut_record_status between 10200001 and 10200004
and cfrv_record_status between 10200001 and 10200004
union all
select copt_company_code, copt_deal_number, copt_hedge_trade, copt_base_amount DealAmount, copt_execute_date,copt_base_currency,
copt_other_currency, copt_backup_deal, copt_init_code,
corv_serial_number, corv_exercise_date, corv_base_amount,pkgForexProcess.Fncgetprofitlossoptnetpandl(corv_deal_number, corv_serial_number), 'Option' DealType
from trtran071, trtran073
where copt_deal_number = corv_deal_number
and copt_record_status between 10200001 and 10200004
And Corv_Record_Status Between 10200001 And 10200004
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;