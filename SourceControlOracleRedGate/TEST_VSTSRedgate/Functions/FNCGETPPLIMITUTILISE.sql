CREATE OR REPLACE function "TEST_VSTSRedgate".fncGetPPLimitUtilise(asonDate in Date,buysell in number,numtype in number)
return number as 
  numAmount Number(15,2) := 0;
  numAmount1 number(15,2) := 0;
  numAmount2 number (15,2) := 0;
  numAmount3 number(15,2) := 0;
  numAmount4 number (15,2) := 0;    
  datTemp    date ;
  begin
  
  if (to_char(asonDate,'MM') >3) then              
              datTemp:= '31-MAR-' ||to_char(asonDate,'YY');              
         else        
             datTemp:= '31-MAR-' || to_char(to_number(to_char(asonDate,'YY'))-1);       
  end if;
       
  if numtype = 1 then ---Outstanding values(Running /values)
    BEGIN
    select   NVL(SUM(pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,asonDate)),0) 
    into numAmount1  from trtran001 
    where ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE >asonDate)
                          or DEAL_PROCESS_COMPLETE = 12400002)
                          and deal_buy_sell = buysell
                          and deal_hedge_trade=26000003
                          and deal_record_status not in (10200005,10200006);
   Exception
    when no_data_found then

      numAmount1 := 0;                          
                          
    END; 
--    BEGIN
--    select 
--      NVL(sum(pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,datTemp)),0) 
--    into numAmount2  from trtran001 
--        where ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE >datTemp)
--                          or DEAL_PROCESS_COMPLETE = 12400002)
--                          and deal_buy_sell = buysell 
--                          and deal_hedge_trade=26000003
--                          and deal_record_status not in (10200005,10200006);
--       Exception
--        when no_data_found then
--
--      numAmount2 := 0;                             
--      END;
      BEGIN
      SELECT   NVL(sum(pkgForexProcess.fncGetOutstanding(COPT_DEAL_NUMBER,COPT_SERIAL_NUMBER,15,1,asondate,NULL,1)),0)  
      INTO numAmount3
      From trtran071 , trtran072
      where  COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
       AND ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >asondate) or copt_PROCESS_COMPLETE = 12400002)
        and (COPT_EXECUTE_DATE <= asondate)
        and  COPT_RECORD_STATUS not in (10200005,10200006)
        and cosu_record_status NOT IN (10200005,10200006)
        AND COPT_hedge_trade=26000003
         and COSU_BUY_SELL=buysell;
         
       Exception
        when no_data_found then

       numAmount3 := 0;          
       END; 
--       BEGIN
--        SELECT  NVL( sum(pkgForexProcess.fncGetOutstanding(COPT_DEAL_NUMBER,COPT_SERIAL_NUMBER,15,1,datTemp,NULL,1)),0)  
--       INTO numAmount4
--       From trtran071 , trtran072
--      where COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
--      and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >datTemp) or copt_PROCESS_COMPLETE = 12400002)
--      and (COPT_EXECUTE_DATE <= datTemp)
--      AND COPT_hedge_trade=26000003
--      and COPT_RECORD_STATUS not in (10200005,10200006)
--         and COSU_BUY_SELL=buysell ;  
--             Exception
--        when no_data_found then
--
--       numAmount4 := 0;          
--       END;   
     numAmount := numAmount1 + numAmount2+numAmount3+numAmount4;
   end if;
    if numtype = 2 then                     
       SELECT nvl(sum(case when cdel_cancel_type =27000001 then CDEL_CANCEL_AMOUNT else 0 end),0)
        into numAmount1   FROM TRTRAN006,TRTRAN001
        WHERE DEAL_DEAL_NUMBER = CDEL_DEAL_NUMBER 
        AND deal_hedge_trade=26000003 and deal_buy_sell=buysell
        AND DEAL_RECORD_STATUS NOT IN (10200005,10200006) 
        AND cdel_record_status NOT IN (10200005,10200006)
        and cdel_cancel_date between datTemp and asonDate;
             
       SELECT nvl(sum(CORV_BASE_AMOUNT),0)
        into numAmount2   FROM trtran073,trtran071,trtran072
        WHERE copt_DEAL_NUMBER = corv_DEAL_NUMBER 
        and copt_deal_number = cosu_deal_number
        AND copt_hedge_trade=26000003 and cosu_buy_sell=buysell
        AND copt_RECORD_STATUS NOT IN (10200005,10200006) 
        AND corv_record_status NOT IN (10200005,10200006)
        AND cosu_record_status NOT IN (10200005,10200006)
        and CORV_EXERCISE_DATE between datTemp and asonDate;        
        
     numAmount := nvl(numAmount1,0) + nvl(numAmount2,0);
    
  end if;
  
    if numtype = 3 then                     
       SELECT sum(case when cdel_cancel_type =27000002 then CDEL_CANCEL_AMOUNT else 0 end) 
       into numAmount1  FROM TRTRAN006,TRTRAN001
        WHERE DEAL_DEAL_NUMBER = CDEL_DEAL_NUMBER 
        AND deal_hedge_trade=26000003 and   deal_buy_sell=buysell
        AND DEAL_RECORD_STATUS NOT IN (10200005,10200006)
        AND cdel_record_status NOT IN (10200005,10200006)
        and cdel_cancel_date between datTemp and asonDate;
        
     numAmount := numAmount1;
    
  end if;
    return numAmount; 
  
  end  fncGetPPLimitUtilise;
/