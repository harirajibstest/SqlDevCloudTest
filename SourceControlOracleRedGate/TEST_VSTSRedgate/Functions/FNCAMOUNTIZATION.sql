CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".FNCAMOUNTIZATION (dealnumber in varchar,DatMonthDate in date) RETURN Number 
AS 
   numAmount number(15,2);
   datFirstDayDate date;
BEGIN

   --datFirstDayDate := to_date('01-' ||  to_char(DatMonthDate,'mon') || '-' || to_char(DatMonthDate,'YYYY'));
--   select (case when (to_char(datMonthdate,'YYYYmm') < to_char(deal_execute_date,'YYYYmm')) or
--                (to_char(datMonthdate,'YYYYmm') > to_char(deal_maturity_date,'YYYYmm')) then 
--                 0
--              when (to_char(deal_execute_date,'YYYYmm')=to_char(datMOnthdate,'YYYYmm')) then 
--               abs(((deal_base_amount* (deal_forward_rate+deal_margin_rate))*(last_day(datMonthdate)-deal_execute_date))
--                /  (deal_maturity_date-deal_execute_date))
--              when (to_char(deal_maturity_date,'YYYYmm')=to_char(datMOnthdate,'YYYYmm')) then
--                abs(((deal_base_amount* (deal_forward_rate+deal_margin_rate))*((last_day(add_months(datMonthdate,-1))+1 - deal_maturity_date)-1))
--                / (deal_maturity_date-deal_execute_date))
--              else abs((deal_base_amount* (deal_forward_rate+deal_margin_rate))* (((last_day(add_months(datMonthdate,-1))+1 - last_day(datMonthdate))-1)
--                /  (deal_maturity_date-deal_execute_date))) end )
--          into numAmount
--          from trtran001 
--    where deal_deal_number =dealnumber
--    and deal_record_status not in (10200005,10200006); 
    
   select (case when (to_char(datMonthdate,'YYYYmm') < to_char(deal_execute_date,'YYYYmm')) or
                (to_char(datMonthdate,'YYYYmm') > to_char(deal_maturity_date,'YYYYmm')) then 
                 0
             when (to_char(deal_execute_date,'YYYYmm')=to_char(deal_maturity_date,'YYYYmm')) then 
               abs(((deal_base_amount* (deal_forward_rate+deal_margin_rate))*(deal_maturity_date-deal_execute_date))
                /  (deal_maturity_date-deal_execute_date))   
              when (to_char(deal_execute_date,'YYYYmm')=to_char(datMOnthdate,'YYYYmm')) then 
               abs(((deal_base_amount* (deal_forward_rate+deal_margin_rate))*(last_day(datMonthdate)-deal_execute_date))
                /  (deal_maturity_date-deal_execute_date))
              when (to_char(deal_maturity_date,'YYYYmm')=to_char(datMOnthdate,'YYYYmm')) then
                abs((deal_base_amount* (deal_forward_rate+deal_margin_rate))*(((last_day(add_months(datMonthdate,-1))+1 - deal_maturity_date))-1)
                / (deal_maturity_date-deal_execute_date))
              else abs((deal_base_amount* (deal_forward_rate+deal_margin_rate))* (((last_day(add_months(datMonthdate,-1))+1 - last_day(datMonthdate))-1)
                /  (deal_maturity_date-deal_execute_date))) end )
          into numAmount
          from trtran001 
    where deal_deal_number =dealnumber
    and deal_record_status not in (10200005,10200006); 
   
  RETURN numAmount;
END fncAmountization;
 
 
 
 
/