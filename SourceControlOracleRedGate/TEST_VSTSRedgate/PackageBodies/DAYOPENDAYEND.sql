CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."DAYOPENDAYEND" AS

  Procedure prcDayOpen(workingdate in date,locationcode in number,numCompanyCode in number)   AS
      
      date1 date;
      vartemp varchar(4000);
      numrecords number(5);
      numerror number;
      numtemp number;
      varOperation        GConst.gvarOperation%Type;
      varMessage          GConst.gvarMessage%Type;
      varError            GConst.gvarError%Type;
  BEGIN
  
     varOperation:= 'Éntered into day open Cal';
      --to temp2 values ('Éntered into Procedure');commit;
-- for checking any other day is opened 
  
      delete from trsystem031 
      where dayo_process_date=workingdate 
      and DAYO_OPERATION_TYPE= GCONST.DAYOPEN;

      select nvl(count(*),0) into numrecords from holidaytable
      WHERE hday_day_status = GCONST.DAYOPEN
      AND hday_location_code = locationcode;

      varOperation:= 'Checking No of Records' || numrecords;
  
   if numrecords !=0 then
        select hday_calendar_date into date1 from holidaytable
        WHERE hday_day_status = GCONST.DAYOPEN
        AND hday_location_code = locationcode;
    
        insert into trsystem031
        values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),
               1,GCONST.DAYOPEN,GCONST.DAYOPENCHECK,GCONST.OPTIONNO,
               date1 || '  is Opened Please close this before opening another day'); 
   else 
        insert into trsystem031 
        (dayo_process_date,   dayo_batch_number,   dayo_serial_number,   
         dayo_operation_type,   dayo_job_code,   dayo_job_status) 
         values  (workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,
         GCONST.DAYOPEN,GCONST.DAYOPENCHECK,GCONST.OPTIONYES); 
         
           
--         VAROPERATION:=' Update forward outstanding Delivery schedules in monthend' ;    
--         NUMERROR :=DAYOPENDAYEND.FNCFORWARDOUTSTANDING(WORKINGDATE);
 
   end if;
 -- checking currency rates are entered for that day
 
--   for curfields in (select cncy_pick_code as currencyCode,cncy_short_description AS currencyname from currencymaster
--                     where cncy_traded_yn=12400001 and cncy_pick_code !=30400003 and 
--                     cncy_record_status not in(gconst.STATUSINACTIVE,gconst.STATUSDELETED))
--   loop
--             select nvl(count(*),0)  into numrecords from trtran012 
--             where DRAT_CURRENCY_CODE= curfields.currencyCode 
--             and DRAT_EFFECTIVE_DATE=workingdate;
--             
--       if numrecords =0 then
--             insert into trsystem031 values
--                    (workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYOPEN,
--                     GCONST.CURRENCYCHECK,GCONST.OPTIONNO,curfields.currencyname || ' Rates are not Entered'); 
--       else 
--             insert into trsystem031 values
--                     (workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,
--                     GCONST.DAYOPEN,GCONST.CURRENCYCHECK,GCONST.OPTIONYES, ''); 
--      end if;          
--   end loop;
  
  
   
   -- To Check the Reminder For the Day
 
      --prcCheckingReminders(workingDate );
   -- Calculate the Rates for the day
   -- numrecords:=  pkgforexprocess.fncCalculateRate(workingDate,1);
  
--     if numrecords =0 then
--             insert into trsystem031 values
--                     (workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYOPEN,
--                      GCONST.RATESCALC,GCONST.OPTIONNO,' Rates Calculation'); 
--     else 
--             insert into trsystem031 values
--                     (workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,
--                     GCONST.DAYOPEN,GCONST.RATESCALC,GCONST.OPTIONYES, ''); 
--      end if;    
      
--      delete from trsystem032 where DPOS_POSITION_DATE=workingDate and DPOS_COMPANY_CODE=numCompanyCode;
--      
--       insert into trsystem032  (DPOS_COMPANY_CODE,DPOS_POSITION_DATE,
--          DPOS_CURRENCY_CODE,DPOS_POSITION_TYPE,dpos_user_id, dpos_holding_rate) 
--            (select numCompanyCode,workingdate, cncy_pick_code,pick_key_value,0 ,
--             pkgforexprocess.fncgetrate(cncy_pick_code,30400003,workingdate,25300001) 
--             from currencymaster,trmaster001
--             where cncy_traded_yn=12400001 and pick_key_value in(26000001,26000002)
--             and cncy_pick_code !=30400003);
--             
--      insert into trsystem032  (DPOS_COMPANY_CODE,DPOS_POSITION_DATE,
--          DPOS_CURRENCY_CODE,DPOS_POSITION_TYPE,dpos_user_id, dpos_holding_rate) 
--          (select numCompanyCode,workingdate, cncy_pick_code,pick_key_value ,user_user_id,
--            pkgforexprocess.fncgetrate(cncy_pick_code,30400003,workingdate,25300001) 
--            from currencymaster,trmaster001,usermaster
--            where cncy_traded_yn=12400001 and pick_key_value in(26000001,26000002)
--            and user_group_code=14200002  and cncy_pick_code !=30400003);


-- Call the Rate update to take the yesterday rates and insert to day open day incase if the rates are not exists
   VAROPERATION:=' Call the Rate update to take the yesterday rates and insert to day open day' ;    
   pkgvaranalysis.prcpopulateratealert(workingdate);

   VAROPERATION:=' To take Holidays Position' ;    
   --pkgvaranalysis.prcpopulateholidayposition(workingdate);
   --insert into temp2 values ('Calling the Rate Alert'); commit;
      
   Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('Day Open', numError, varMessage, 
                      varOperation, varError);

      commit;
      
      raise_application_error(-20101, varError);                      
  
      
  END prcDayOpen;
 -------------------------------------------------------------------------------------------------- 
--procedure prcDayClose(workingdate in date,userid in varchar) as
--     vartemp varchar(4000);
--     date1 date;
--     numrecords number(5);
--     numerror number;
--     numtemp number;
--     varOperation        GConst.gvarOperation%Type;
--     varMessage          GConst.gvarMessage%Type;
--     varError            GConst.gvarError%Type;
--     dateTemp   date;  
--     dateTemp1  date;
--     dateTemp2  date;
--     numCount   number;
--     numCount1  number;     
--   begin
--   
--     -- for checking Opened day 
--    
--      delete from trsystem031 
--      where dayo_process_date=workingdate 
--      and DAYO_OPERATION_TYPE= GCONST.DAYCLOSED;
--
--   --     commit;
--        
--
--      BEGIN
--      
--          select nvl(count(*),0) into numrecords from holidaytable
--                 WHERE hday_day_status = GCONST.DAYOPEN
--                 AND hday_location_code = 30299999
--                 group by hday_calendar_date;
--                 
--      EXCEPTION
--      WHEN OTHERS THEN
--          numrecords:=0; 
--      END ;
---- varOperation:=' Insert Other product from trtran002c into trtran002 after 2 days' ;
----     NUMERROR :=DAYOPENDAYEND.FNCSAPOTHER(WORKINGDATE);
----       
--     varOperation:=' Update position outstanding in the table' ;
--     Numerror :=pkgvaranalysis.fncPositionGenerate(UserID , WORKINGDATE);
--     
--      update trtran002 set trad_trade_Rate=
--                 pkgforexprocess.fncGetRate(trad_trade_currency,30400003,trad_entry_date,
--                       (case when trad_import_export >25900050 then  Gconst.PURCHASEDEAL
--                        else Gconst.SALEDEAL end),0,
--                        trad_maturity_date, (select max(drat_serial_number) from trtran012
--                        where drat_effective_date = trad_entry_date
--                          and drat_record_status not in(10200005,10200006)
--                          and drat_currency_code= trad_trade_currency
--                          and drat_for_currency= 30400003)),
--                 trad_spot_rate=
--                  pkgforexprocess.fncGetRate(trad_trade_currency,30400003,trad_entry_date,
--                       (case when trad_import_export >25900050 then  Gconst.PURCHASEDEAL
--                        else Gconst.SALEDEAL end),0,
--                        null, (select max(drat_serial_number) from trtran012
--                        where drat_effective_date = trad_entry_date
--                          and drat_record_status not in(10200005,10200006)
--                          and drat_currency_code= trad_trade_currency
--                          and drat_for_currency= 30400003))
--       where trad_record_status not in (10200005,10200006)
--         and trad_entry_date= workingdate
--         and trad_import_export= 25900077;
--                          
--       varOperation:=' Update the forward rate and final rate' ;
--
--       update trtran002 set trad_forward_rate= abs(trad_trade_Rate-trad_spot_rate),
--                 trad_final_rate=((trad_trade_Rate/100)* (select prmc_benchmark_percent
--                                                         from trsystem051)) + trad_trade_Rate
--       where trad_record_status not in (10200005,10200006)
--         and trad_entry_date= workingdate
--         and trad_import_export= 25900077 ;
--         
--       commit;  
------------------------------From Here Commented ------------------Ishwarachandra 03/12/2015-----------       
--
--       select nvl(count(*),0) into numrecords from trtran001 
--       where DEAL_MATURITY_DATE <= workingdate
--       and deal_Process_complete = 12400002
--       --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
--       and DEAL_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED);
--       
--       if numrecords !=0 then
--          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                         GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                        'There are Deals Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--       end if;
--       
--       dateTemp   := '25-'||to_char(workingdate,'MON-YYYY');
--       dateTemp1  := LAST_DAY(ADD_MONTHS(workingdate,-1));
--       delete from temp;
--       insert into temp values (dateTemp,dateTemp1);
--       insert into temp values (TRUNC (workingdate, 'month'),dateTemp-1);
--       
----       SELECT COUNT(*) INTO numCount
----       FROM trsystem001
----       WHERE hday_day_status IN(26400002) -----chek if last working day is holiday
----       AND hday_location_code     = 30299999
----       AND hday_calendar_date BETWEEN TRUNC (workingdate, 'month') AND (dateTemp-1);
--       
----       IF to_char(workingdate,'DD') <= 24 THEN
----         select nvl(count(*),0) into numrecords from trtran002 
----         where TRAD_MATURITY_DATE <= dateTemp1
----          AND TRAD_PROCESS_COMPLETE =12400002
----         and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
----         and trad_product_category not in(33300004,33300005)
----        AND PKGFOREXPROCESS.fncGetOutstanding(trad_trade_reference,0,GConst.UTILCONTRACTOS,GConst.AMOUNTFCY, workingdate) >0;
----
----           
----         if numrecords !=0 then
----            insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                           GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
----                                          'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
----         end if;
----       else
----           SELECT max(hday_calendar_date)
----             INTO dateTemp2
----           FROM trsystem001
----           WHERE hday_day_status NOT IN(26400007,26400008,26400009) -----chek if last working day is holiday
----           AND hday_location_code     = 30299999
----           AND hday_calendar_date BETWEEN dateTemp AND Last_Day(workingdate);
----       
----           IF workingdate = dateTemp2 THEN
----                  select nvl(count(*),0) into numrecords from trtran002 
----                   where TRAD_MATURITY_DATE <= Last_Day(workingdate)
----                    AND TRAD_PROCESS_COMPLETE =12400002
----                   and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
----                   and trad_product_category NOT IN(33300004,33300005)
----                   AND PKGFOREXPROCESS.fncGetOutstanding(trad_trade_reference,0,GConst.UTILCONTRACTOS,GConst.AMOUNTFCY, workingdate) >0;
----           
----               if numrecords !=0 then
----                  insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                                 GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
----                                                'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
----               end if;
----           else
----               select nvl(count(*),0) into numrecords from trtran002 
----                   where TRAD_MATURITY_DATE <= dateTemp
----                    AND TRAD_PROCESS_COMPLETE =12400002
----                   --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
----                   and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
----                   and trad_product_category not in(33300004,33300005)
----                   AND PKGFOREXPROCESS.fncGetOutstanding(trad_trade_reference,0,GConst.UTILCONTRACTOS,GConst.AMOUNTFCY, workingdate) >0;
----           
----               if numrecords !=0 then
----                  insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                                 GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
----                                                'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
----               end if;
----            
----           END IF;
----          
----      end if; 
--      
-------------------------------------UPTO Here  commnted ------------------03/12/2015      
----       dateTemp   := '25-'||to_char(workingdate,'MON-YYYY');
----         
----              
----       IF dateTemp = workingdate THEN ----Working date = 25th then check Maturity Transactions
----         select nvl(count(*),0) into numrecords from trtran002 
----         where TRAD_MATURITY_DATE <= workingdate
----          AND TRAD_PROCESS_COMPLETE =12400002
----         --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
----         and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
----         and trad_product_category not in(33300004);
----         
----         if numrecords !=0 then
----            insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                           GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
----                                          'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
----       end if;
----      END IF;
----      IF dateTemp < workingdate THEN 
----        SELECT COUNT(*) INTO numCount
----         FROM trsystem001
----         WHERE hday_day_status IN(26400007,26400008,26400009) -----chek if 25th day is holiday
----         AND hday_location_code     = 30299999
----         AND hday_calendar_date     = dateTemp;
----         
----        SELECT COUNT(*) INTO numCount1  ---Check for if date is allready opend and closed between 25th and last day of month
----         FROM trsystem001
----         WHERE hday_day_status IN(26400005)
----         AND hday_location_code     = 30299999
----         AND hday_calendar_date between dateTemp and Last_Day(workingdate);
----         
----
----        IF numCount != 0 and numCount1 = 0 THEN
----          SELECT min(hday_calendar_date) into dateTemp1
----            FROM trsystem001
----            WHERE hday_day_status  IN(26400002)
----            AND hday_location_code     = 30299999
----            AND hday_calendar_date   between dateTemp and Last_Day(workingdate);
----            
----            select nvl(count(*),0) into numrecords from trtran002 
----            where TRAD_MATURITY_DATE <= workingdate
----            AND TRAD_PROCESS_COMPLETE =12400002
----           --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
----            and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
----            and trad_product_category not in(33300004);
----           
----            if numrecords !=0 then
----              insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                             GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
----                                            'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
----            end if;
----        END IF;
----      END IF;       
---- un commenct Once All Hestorical open exposure close  .
----       select nvl(count(*),0) into numrecords from trtran002 
----       where TRAD_MATURITY_DATE <= workingdate
----        AND TRAD_PROCESS_COMPLETE =12400002
----       --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
----       and TRAD_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED);
----       
----       if numrecords !=0 then
----          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                         GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
----                                        'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
----       end if;
--
------------------------------------------------------------
--
----       
----     update trtran002  set trad_trade_Rate= 
----            pkgforexprocess.fncGetRate(trad_trade_currency,30400003,trad_entry_date,
----            (case when trad_import_export>25900050 then 25300001 else 25300002 end ),0,
----                        trad_maturity_date, (select max(drat_serial_number) from trtran012
----                        where drat_effective_date = trad_entry_date
----                          and drat_record_status not in(10200005,10200006)
----                          and drat_currency_code= trad_trade_currency
----                          and drat_for_currency= 30400003))
----     where trad_record_status not in (10200005,10200006)
----       and trad_entry_date= workingdate;
--
----       if numrecords =0 then
----       
----          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                         GCONST.DAYOPENCHECK,GCONST.OPTIONNO, 
----                                        'No Day Is Opend '); 
----       else 
----          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                         GCONST.DAYOPENCHECK,GCONST.OPTIONYES, ''); 
----       end if;
-- 
--        
----     --TRADE DEAL CONFORMATION
----     select nvl(count(*),0) into numrecords from trtran001 
----     where DEAL_EXECUTE_DATE= workingdate
----     and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
----     and DEAL_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
----     
----     if numrecords !=0 then
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
----                                      'Trade Deals are Pending For Conformation'); 
----     else 
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
----     end if;
--     
----     --Hedge DEAL CONFORMATION
----     select nvl(count(*),0) into numrecords from trtran001 
----     where DEAL_EXECUTE_DATE= workingdate
----     and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
----     and DEAL_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
----     
----     if numrecords !=0 then
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
----                                      'Hedge Deals are Pending For Conformation'); 
----     else 
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
----     end if;
--     
----     --Marchent DEAL CONFORMATION
----     select nvl(count(*),0) into numrecords from trtran002 
----     where TRAD_ENTRY_DATE= workingdate
----     and TRAD_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED);
----     
----     if numrecords !=0 then
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
----                                      'Merchant Deal are Pending For Conformation'); 
----     else 
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
----     end if;
----     
----      for curfields in(select user_user_id userid from usermaster where user_group_code=14200002)
----      loop
----        
----          numrecords := pkgforexprocess.fncinsertdeals(workingdate);
----      end loop;
----            insert into temp values (workingdate,'KKK');
----            commit;
--          
----          numrecords := pkgforexprocess.fncinsertdeals(workingdate);
----          
----          for curfields in (select user_user_id userid from usermaster
----                            where user_group_code=14200002)
----          loop
----              numrecords := pkgforexprocess.fncinsertdeals(workingdate,curfields.userid);
----          end loop;
--          
----          UPDATE trsystem032 c
----                SET dpos_day_position =
----               (SELECT(nvl(dpos_purchase_amount,0) -nvl(dpos_sale_amount,0))
----                FROM trsystem032 b
----                WHERE b.dpos_position_type = 26000002
----                AND b.dpos_position_date = workingdate
----                and b.dpos_currency_code= c.dpos_currency_code
----                and b.dpos_user_id is null),
----                dpos_position_inr =
----                (SELECT (nvl(dpos_purchase_inr,0) -nvl(dpos_sale_inr,0))
----                FROM trsystem032 a
----                WHERE a.dpos_position_type = 26000002
----                AND a.dpos_position_date = workingdate
----                and a.dpos_currency_code= c.dpos_currency_code
----                and a.dpos_user_id is null)
----                where 
----                c.dpos_position_type = 26000002
----                AND c.dpos_position_date = workingdate
----                and c.dpos_user_id is null;
----                 
----           UPDATE trsystem032 c
----                SET dpos_day_position =
----               (SELECT(nvl(dpos_purchase_amount,0) -nvl(dpos_sale_amount,0))
----                FROM trsystem032 b
----                WHERE b.dpos_position_type = 26000002
----                AND b.dpos_position_date = workingdate
----                and b.dpos_currency_code= c.dpos_currency_code
----                and b.dpos_user_id=c.dpos_user_id),
----                dpos_position_inr =
----                (SELECT (nvl(dpos_purchase_inr,0) -nvl(dpos_sale_inr,0))
----                FROM trsystem032 a
----                WHERE a.dpos_position_type = 26000002
----                AND a.dpos_position_date = workingdate
----                and a.dpos_currency_code= c.dpos_currency_code
----                and a.dpos_user_id=c.dpos_user_id)
----                where 
----                dpos_position_type = 26000002
----                and c.dpos_user_id is not null
----                AND dpos_position_date = workingdate;
----                 
----      if numrecords !=0 then
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.UPDATEPOSITION,GCONST.OPTIONNO, 
----                                      'Currency Position Update'); 
----      else
----        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
----                                       GCONST.UPDATEPOSITION,GCONST.OPTIONYES, 
----                                      ''); 
----                                      
----        
----      end if;
----  varOperation := 'Updating Commodity Broker Charges'; 
----  prcCalcBrokerCharges(workingdate);
--  
--  Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('Day Close', numError, varMessage, 
--                      varOperation, varError);
--      raise_application_error(-20101, varError);      
--   end prcDayClose;--------------------------------------------------------------------------------------------------


procedure prcDayClose(workingdate in date,userid in varchar) as
     vartemp varchar(4000);
     date1 date;
     numrecords number(5);
     numerror number;
     numtemp number;
     varOperation        GConst.gvarOperation%Type;
     varMessage          GConst.gvarMessage%Type;
     varError            GConst.gvarError%Type;
     dateTemp   date;  
     dateTemp1  date;
     dateTemp2  date;
     numCount   number;
     numCount1  number;     
   begin
   
     -- for checking Opened day 
    
      delete from trsystem031 
      where dayo_process_date=workingdate 
      and DAYO_OPERATION_TYPE= GCONST.DAYCLOSED;

   --     commit;
        

      BEGIN
      
          select nvl(count(*),0) into numrecords from holidaytable
                 WHERE hday_day_status = GCONST.DAYOPEN
                 AND hday_location_code = 30299999
                 group by hday_calendar_date;
                 
      EXCEPTION
      WHEN OTHERS THEN
          numrecords:=0; 
      END ;
-- varOperation:=' Insert Other product from trtran002c into trtran002 after 2 days' ;
--     NUMERROR :=DAYOPENDAYEND.FNCSAPOTHER(WORKINGDATE);
--       

--     
--      update trtran002 set trad_trade_Rate=
--                 pkgforexprocess.fncGetRate(trad_trade_currency,30400003,trad_entry_date,
--                       (case when trad_import_export >25900050 then  Gconst.PURCHASEDEAL
--                        else Gconst.SALEDEAL end),0,
--                        trad_maturity_date, (select max(drat_serial_number) from trtran012
--                        where drat_effective_date = trad_entry_date
--                          and drat_record_status not in(10200005,10200006)
--                          and drat_currency_code= trad_trade_currency
--                          and drat_for_currency= 30400003)),
--                 trad_spot_rate=
--                  pkgforexprocess.fncGetRate(trad_trade_currency,30400003,trad_entry_date,
--                       (case when trad_import_export >25900050 then  Gconst.PURCHASEDEAL
--                        else Gconst.SALEDEAL end),0,
--                        null, (select max(drat_serial_number) from trtran012
--                        where drat_effective_date = trad_entry_date
--                          and drat_record_status not in(10200005,10200006)
--                          and drat_currency_code= trad_trade_currency
--                          and drat_for_currency= 30400003))
--       where trad_record_status not in (10200005,10200006)
--         and trad_entry_date= workingdate
--         and trad_import_export= 25900077;
--                          
--       varOperation:=' Update the forward rate and final rate' ;
--
--       update trtran002 set trad_forward_rate= abs(trad_trade_Rate-trad_spot_rate),
--                 trad_final_rate=((trad_trade_Rate/100)* (select prmc_benchmark_percent
--                                                         from trsystem051)) + trad_trade_Rate
--       where trad_record_status not in (10200005,10200006)
--         and trad_entry_date= workingdate
--         and trad_import_export= 25900077 ;
--         
--       commit;  
----------------------------From Here Commented ------------------Ishwarachandra 03/12/2015-----------       
      varOperation:= 'Deals Maturied but not closed';
      
       select nvl(count(*),0) into numrecords from trtran001 
       where DEAL_MATURITY_DATE <= workingdate
       and deal_Process_complete = 12400002
       --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
       and DEAL_RECORD_STATUS in(10200001,10200002,10200003,10200004);
       
       if numrecords !=0 then
          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                         GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
                                        'There are Forward Deals Matured But Not Closed Please Check'); 
       end if;
       
      select nvl(count(*),0) into numrecords from trtran061
       where CFUT_MATURITY_DATE <= workingdate
       and CFUT_Process_complete = 12400002
       --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
       and CFUT_RECORD_STATUS in(10200001,10200002,10200003,10200004);
       
       if numrecords !=0 then
          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                         GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
                                        'There are Future Deals Matured But Not Closed Please Check'); 
       end if;
       
      select nvl(count(*),0) into numrecords from trtran071
       where COPT_EXPIRY_DATE <= workingdate
       and COPT_Process_complete = 12400002
       --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
       and COPT_RECORD_STATUS in(10200001,10200002,10200003,10200004);
       
       if numrecords !=0 then
          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                         GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
                                        'There are Option Deals Matured But Not Closed Please Check'); 
       end if;
       
       
--       dateTemp   := '25-'||to_char(workingdate,'MON-YYYY');
--       dateTemp1  := LAST_DAY(ADD_MONTHS(workingdate,-1));
--       delete from temp;
--       insert into temp values (dateTemp,dateTemp1);
--       insert into temp values (TRUNC (workingdate, 'month'),dateTemp-1);
       
       
       
--       SELECT COUNT(*) INTO numCount
--       FROM trsystem001
--       WHERE hday_day_status IN(26400002) -----chek if last working day is holiday
--       AND hday_location_code     = 30299999
--       AND hday_calendar_date BETWEEN TRUNC (workingdate, 'month') AND (dateTemp-1);
       
--       IF to_char(workingdate,'DD') <= 24 THEN
--         select nvl(count(*),0) into numrecords from trtran002 
--         where TRAD_MATURITY_DATE <= dateTemp1
--          AND TRAD_PROCESS_COMPLETE =12400002
--         and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
--         and trad_product_category not in(33300004,33300005)
--        AND PKGFOREXPROCESS.fncGetOutstanding(trad_trade_reference,0,GConst.UTILCONTRACTOS,GConst.AMOUNTFCY, workingdate) >0;
--
--           
--         if numrecords !=0 then
--            insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                           GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                          'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--         end if;
--       else
--           SELECT max(hday_calendar_date)
--             INTO dateTemp2
--           FROM trsystem001
--           WHERE hday_day_status NOT IN(26400007,26400008,26400009) -----chek if last working day is holiday
--           AND hday_location_code     = 30299999
--           AND hday_calendar_date BETWEEN dateTemp AND Last_Day(workingdate);
--       
--           IF workingdate = dateTemp2 THEN
--                  select nvl(count(*),0) into numrecords from trtran002 
--                   where TRAD_MATURITY_DATE <= Last_Day(workingdate)
--                    AND TRAD_PROCESS_COMPLETE =12400002
--                   and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
--                   and trad_product_category NOT IN(33300004,33300005)
--                   AND PKGFOREXPROCESS.fncGetOutstanding(trad_trade_reference,0,GConst.UTILCONTRACTOS,GConst.AMOUNTFCY, workingdate) >0;
--           
--               if numrecords !=0 then
--                  insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                                 GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                                'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--               end if;
--           else
--               select nvl(count(*),0) into numrecords from trtran002 
--                   where TRAD_MATURITY_DATE <= dateTemp
--                    AND TRAD_PROCESS_COMPLETE =12400002
--                   --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
--                   and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
--                   and trad_product_category not in(33300004,33300005)
--                   AND PKGFOREXPROCESS.fncGetOutstanding(trad_trade_reference,0,GConst.UTILCONTRACTOS,GConst.AMOUNTFCY, workingdate) >0;
--           
--               if numrecords !=0 then
--                  insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                                 GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                                'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--               end if;
--            
--           END IF;
--          
--      end if; 
      
-----------------------------------UPTO Here  commnted ------------------03/12/2015      
--       dateTemp   := '25-'||to_char(workingdate,'MON-YYYY');
--         
--              
--       IF dateTemp = workingdate THEN ----Working date = 25th then check Maturity Transactions
--         select nvl(count(*),0) into numrecords from trtran002 
--         where TRAD_MATURITY_DATE <= workingdate
--          AND TRAD_PROCESS_COMPLETE =12400002
--         --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
--         and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
--         and trad_product_category not in(33300004);
--         
--         if numrecords !=0 then
--            insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                           GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                          'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--       end if;
--      END IF;
--      IF dateTemp < workingdate THEN 
--        SELECT COUNT(*) INTO numCount
--         FROM trsystem001
--         WHERE hday_day_status IN(26400007,26400008,26400009) -----chek if 25th day is holiday
--         AND hday_location_code     = 30299999
--         AND hday_calendar_date     = dateTemp;
--         
--        SELECT COUNT(*) INTO numCount1  ---Check for if date is allready opend and closed between 25th and last day of month
--         FROM trsystem001
--         WHERE hday_day_status IN(26400005)
--         AND hday_location_code     = 30299999
--         AND hday_calendar_date between dateTemp and Last_Day(workingdate);
--         
--
--        IF numCount != 0 and numCount1 = 0 THEN
--          SELECT min(hday_calendar_date) into dateTemp1
--            FROM trsystem001
--            WHERE hday_day_status  IN(26400002)
--            AND hday_location_code     = 30299999
--            AND hday_calendar_date   between dateTemp and Last_Day(workingdate);
--            
--            select nvl(count(*),0) into numrecords from trtran002 
--            where TRAD_MATURITY_DATE <= workingdate
--            AND TRAD_PROCESS_COMPLETE =12400002
--           --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
--            and TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004--in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED)
--            and trad_product_category not in(33300004);
--           
--            if numrecords !=0 then
--              insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                             GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                            'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--            end if;
--        END IF;
--      END IF;       
-- un commenct Once All Hestorical open exposure close  .
--       select nvl(count(*),0) into numrecords from trtran002 
--       where TRAD_MATURITY_DATE <= workingdate
--        AND TRAD_PROCESS_COMPLETE =12400002
--       --and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
--       and TRAD_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED);
--       
--       if numrecords !=0 then
--          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                         GCONST.MATUREDENTRY,GCONST.OPTIONNO, 
--                                        'There are Exposure Matured But Not Closed Please Refer Report :- Transaction Matured But Not Closed in System'); 
--       end if;

----------------------------------------------------------

--       
--     update trtran002  set trad_trade_Rate= 
--            pkgforexprocess.fncGetRate(trad_trade_currency,30400003,trad_entry_date,
--            (case when trad_import_export>25900050 then 25300001 else 25300002 end ),0,
--                        trad_maturity_date, (select max(drat_serial_number) from trtran012
--                        where drat_effective_date = trad_entry_date
--                          and drat_record_status not in(10200005,10200006)
--                          and drat_currency_code= trad_trade_currency
--                          and drat_for_currency= 30400003))
--     where trad_record_status not in (10200005,10200006)
--       and trad_entry_date= workingdate;

--       if numrecords =0 then
--       
--          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                         GCONST.DAYOPENCHECK,GCONST.OPTIONNO, 
--                                        'No Day Is Opend '); 
--       else 
--          insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                         GCONST.DAYOPENCHECK,GCONST.OPTIONYES, ''); 
--       end if;
 
        
--     --TRADE DEAL CONFORMATION
--     select nvl(count(*),0) into numrecords from trtran001 
--     where DEAL_EXECUTE_DATE= workingdate
--     and DEAL_HEDGE_TRADE= GCONST.TRADEDEAL
--     and DEAL_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Trade Deals are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;


     
--     --Hedge DEAL CONFORMATION
--     select nvl(count(*),0) into numrecords from trtran001 
--     where DEAL_EXECUTE_DATE= workingdate
--    -- and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
--     and DEAL_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Deals are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
--     
--          --Hedge DEAL CONFORMATION
--     select nvl(count(*),0) into numrecords from trtran006
--     where CDEL_CANCEL_DATE= workingdate
--     --and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
--     and CDEL_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Deal Cancellation are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
--     
--     --Future Deals For Confirmation
--     select nvl(count(*),0) into numrecords from trtran061
--     where CFUT_EXECUTE_DATE= workingdate
--     --and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
--     and CFUT_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Future Deals are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
--     
--     --Future Cancellation Deals For Confirmation
--     select nvl(count(*),0) into numrecords from trtran063
--     where CFRV_EXECUTE_DATE= workingdate
--     --and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
--     and CFRV_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Future Cancellation Deals are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
--     
--     --Option Deals are  For Confirmation
--     select nvl(count(*),0) into numrecords from trtran071
--     where COPT_EXECUTE_DATE= workingdate
--     --and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
--     and COPT_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Option Deals are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
--     
--         --Option Deal Unwinds are  For Confirmation
--     select nvl(count(*),0) into numrecords from trtran073
--     where CORV_EXERCISE_DATE= workingdate
--     --and DEAL_HEDGE_TRADE= GCONST.HEDGEDEAL
--     and CORV_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED,10200012);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Option Deal Unwinds are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
     
     --Populate Rates
     select nvl(count(*),0) into numrecords from trtran012
     where DRAT_EFFECTIVE_DATE= workingdate
     and DRAT_SERIAL_NUMBER >0 
     and DRAT_RECORD_STATUS not in(10200005,10200006);
     
     if numrecords =0 then
        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
                                      'Please Populate Forward Rates'); 
     else 
        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
     end if;
     
     --Future rates
--     select nvl(count(*),0) into numrecords from trtran064
--     where CFMM_EFFECTIVE_DATE= workingdate
--    -- and DRAT_SERIAL_NUMBER >0 
--     and CFMM_RECORD_STATUS not in(10200005,10200006);
--     
--     if numrecords =0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Please Populate Future Rates'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
     
    --Option Valuvation 
     select nvl(count(*),0) into numrecords from trtran074A
     where OPTV_ENTRY_DATE= workingdate
    -- and DRAT_SERIAL_NUMBER >0 
      and OPTV_RECORD_STATUS not in(10200005,10200006);
     
     if numrecords =0 then
        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
                                      'Please Populate Option Valuvation'); 
     else 
        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
     end if;
     
     
     varOperation:=' Update position outstanding in the table' || WORKINGDATE ;
      Numerror :=pkgvaranalysis.fncPositionGenerate(UserID , WORKINGDATE);
      
     for curDate in (select HDAY_CALENDAR_DATE DayClosedDate from trsystem001 
                       where HDAY_CALENDAR_DATE >WORKINGDATE
                       and HDAY_DAY_STATUS= 26400005)
     loop
          varOperation:=' Update position outstanding in the table' || CurDate.DayClosedDate ;
          Numerror :=pkgvaranalysis.fncPositionGenerate(UserID , CurDate.DayClosedDate);
     end loop;
    
     varOperation:=' Update position outstanding in the table' ;
     Numerror :=pkgvaranalysis.fncPositionGenerate(UserID , WORKINGDATE);
     
    delete from  TRSYSTEM997D_DAYREOPEN where posn_mtm_date= WORKINGDATE;
         
           INSERT INTO TRSYSTEM997D_DAYREOPEN
            (
              POSN_MTM_DATE,    POSN_COMPANY_CODE,    POSN_CURRENCY_CODE,    POSN_ACCOUNT_CODE,
              POSN_USER_ID,    POSN_REFERENCE_NUMBER,    POSN_REFERENCE_SERIAL,    POSN_REFERENCE_DATE,
              POSN_DEALER_ID,    POSN_COUNTER_PARTY,    POSN_TRANSACTION_AMOUNT,    POSN_FCY_RATE,
              POSN_USD_RATE,    POSN_INR_VALUE,    POSN_USD_VALUE,    POSN_MTM_FCYRATE,
              POSN_MTM_LOCALRATE,    POSN_REVALUE_USD,    POSN_REVALUE_INR,    POSN_POSITION_USD,
              POSN_POSITION_INR,    POSN_DUE_DATE,    POSN_MATURITY_MONTH,    POSN_PRODUCT_CODE,
              POSN_HEDGE_TRADE,    POSN_ASSET_LIABILITY,    POSN_FOR_CURRENCY,    POSN_SUBPRODUCT_CODE,
              POSN_MTM_PNL,    POSN_MTM_PNLLOCAL,    POSN_OTHER_CURRENCY,    POSN_SPOT_RATE,
              POSN_FORWARD_RATE,    POSN_MARGIN_RATE,    POSN_CANCEL_PNL,    POSN_PROCESS_COMPLETE,
              POSN_TRADE_REFERENCE,    POSN_USER_REFERENCE,    POSN_USER_REMARKS,    POSN_CANCEL_RATE,
              POSN_CONTRACT_NO,    POSN_LOCATION_CODE,    POSN_BROKER_CODE  )
           select POSN_MTM_DATE,    POSN_COMPANY_CODE,    POSN_CURRENCY_CODE,    POSN_ACCOUNT_CODE,
              POSN_USER_ID,    POSN_REFERENCE_NUMBER,    POSN_REFERENCE_SERIAL,    POSN_REFERENCE_DATE,
              POSN_DEALER_ID,    POSN_COUNTER_PARTY,    POSN_TRANSACTION_AMOUNT,    POSN_FCY_RATE,
              POSN_USD_RATE,    POSN_INR_VALUE,    POSN_USD_VALUE,    POSN_MTM_FCYRATE,
              POSN_MTM_LOCALRATE,    POSN_REVALUE_USD,    POSN_REVALUE_INR,    POSN_POSITION_USD,
              POSN_POSITION_INR,    POSN_DUE_DATE,    POSN_MATURITY_MONTH,    POSN_PRODUCT_CODE,
              POSN_HEDGE_TRADE,    POSN_ASSET_LIABILITY,    POSN_FOR_CURRENCY,    POSN_SUBPRODUCT_CODE,
              POSN_MTM_PNL,    POSN_MTM_PNLLOCAL,    POSN_OTHER_CURRENCY,    POSN_SPOT_RATE,
              POSN_FORWARD_RATE,    POSN_MARGIN_RATE,    POSN_CANCEL_PNL,    POSN_PROCESS_COMPLETE,
              POSN_TRADE_REFERENCE,    POSN_USER_REFERENCE,    POSN_USER_REMARKS,    POSN_CANCEL_RATE,
              POSN_CONTRACT_NO,    POSN_LOCATION_CODE,    POSN_BROKER_CODE
            from TRSYSTEM997D where posn_mtm_date= WORKINGDATE;
            
     for curDate in (select Distinct HDAY_CALENDAR_DATE from trsystem001
                     where HDAY_DAY_STATUS=26400005
                      and HDAY_CALENDAR_DATE >WORKINGDATE
                      and HDAY_LOCATION_CODE =30299999)
     loop
     
         delete from  TRSYSTEM997D_DAYREOPEN where posn_mtm_date= curDate.HDAY_CALENDAR_DATE;
         
           INSERT INTO TRSYSTEM997D_DAYREOPEN
            (
              POSN_MTM_DATE,    POSN_COMPANY_CODE,    POSN_CURRENCY_CODE,    POSN_ACCOUNT_CODE,
              POSN_USER_ID,    POSN_REFERENCE_NUMBER,    POSN_REFERENCE_SERIAL,    POSN_REFERENCE_DATE,
              POSN_DEALER_ID,    POSN_COUNTER_PARTY,    POSN_TRANSACTION_AMOUNT,    POSN_FCY_RATE,
              POSN_USD_RATE,    POSN_INR_VALUE,    POSN_USD_VALUE,    POSN_MTM_FCYRATE,
              POSN_MTM_LOCALRATE,    POSN_REVALUE_USD,    POSN_REVALUE_INR,    POSN_POSITION_USD,
              POSN_POSITION_INR,    POSN_DUE_DATE,    POSN_MATURITY_MONTH,    POSN_PRODUCT_CODE,
              POSN_HEDGE_TRADE,    POSN_ASSET_LIABILITY,    POSN_FOR_CURRENCY,    POSN_SUBPRODUCT_CODE,
              POSN_MTM_PNL,    POSN_MTM_PNLLOCAL,    POSN_OTHER_CURRENCY,    POSN_SPOT_RATE,
              POSN_FORWARD_RATE,    POSN_MARGIN_RATE,    POSN_CANCEL_PNL,    POSN_PROCESS_COMPLETE,
              POSN_TRADE_REFERENCE,    POSN_USER_REFERENCE,    POSN_USER_REMARKS,    POSN_CANCEL_RATE,
              POSN_CONTRACT_NO,    POSN_LOCATION_CODE,    POSN_BROKER_CODE  )
           select POSN_MTM_DATE,    POSN_COMPANY_CODE,    POSN_CURRENCY_CODE,    POSN_ACCOUNT_CODE,
              POSN_USER_ID,    POSN_REFERENCE_NUMBER,    POSN_REFERENCE_SERIAL,    POSN_REFERENCE_DATE,
              POSN_DEALER_ID,    POSN_COUNTER_PARTY,    POSN_TRANSACTION_AMOUNT,    POSN_FCY_RATE,
              POSN_USD_RATE,    POSN_INR_VALUE,    POSN_USD_VALUE,    POSN_MTM_FCYRATE,
              POSN_MTM_LOCALRATE,    POSN_REVALUE_USD,    POSN_REVALUE_INR,    POSN_POSITION_USD,
              POSN_POSITION_INR,    POSN_DUE_DATE,    POSN_MATURITY_MONTH,    POSN_PRODUCT_CODE,
              POSN_HEDGE_TRADE,    POSN_ASSET_LIABILITY,    POSN_FOR_CURRENCY,    POSN_SUBPRODUCT_CODE,
              POSN_MTM_PNL,    POSN_MTM_PNLLOCAL,    POSN_OTHER_CURRENCY,    POSN_SPOT_RATE,
              POSN_FORWARD_RATE,    POSN_MARGIN_RATE,    POSN_CANCEL_PNL,    POSN_PROCESS_COMPLETE,
              POSN_TRADE_REFERENCE,    POSN_USER_REFERENCE,    POSN_USER_REMARKS,    POSN_CANCEL_RATE,
              POSN_CONTRACT_NO,    POSN_LOCATION_CODE,    POSN_BROKER_CODE
            from TRSYSTEM997D where posn_mtm_date= curDate.HDAY_CALENDAR_DATE;
         varOperation:=' Processing the Postion Updated for the Date ' || curDate.HDAY_CALENDAR_DATE ;
         Numerror :=pkgvaranalysis.fncPositionGenerate(UserID , curDate.HDAY_CALENDAR_DATE);
     end loop;

     
     
--     --Marchent DEAL CONFORMATION
--     select nvl(count(*),0) into numrecords from trtran002 
--     where TRAD_ENTRY_DATE= workingdate
--     and TRAD_RECORD_STATUS in(GCONST.STATUSENTRY,GCONST.STATUSAPREUTHORIZATION,GCONST.STATUSUPDATED);
--     
--     if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONNO, 
--                                      'Merchant Deal are Pending For Conformation'); 
--     else 
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.PENDINGCONFORM,GCONST.OPTIONYES, ''); 
--     end if;
--     
--      for curfields in(select user_user_id userid from usermaster where user_group_code=14200002)
--      loop
--        
--          numrecords := pkgforexprocess.fncinsertdeals(workingdate);
--      end loop;
--            insert into temp values (workingdate,'KKK');
--            commit;
          
--          numrecords := pkgforexprocess.fncinsertdeals(workingdate);
--          
--          for curfields in (select user_user_id userid from usermaster
--                            where user_group_code=14200002)
--          loop
--              numrecords := pkgforexprocess.fncinsertdeals(workingdate,curfields.userid);
--          end loop;
          
--          UPDATE trsystem032 c
--                SET dpos_day_position =
--               (SELECT(nvl(dpos_purchase_amount,0) -nvl(dpos_sale_amount,0))
--                FROM trsystem032 b
--                WHERE b.dpos_position_type = 26000002
--                AND b.dpos_position_date = workingdate
--                and b.dpos_currency_code= c.dpos_currency_code
--                and b.dpos_user_id is null),
--                dpos_position_inr =
--                (SELECT (nvl(dpos_purchase_inr,0) -nvl(dpos_sale_inr,0))
--                FROM trsystem032 a
--                WHERE a.dpos_position_type = 26000002
--                AND a.dpos_position_date = workingdate
--                and a.dpos_currency_code= c.dpos_currency_code
--                and a.dpos_user_id is null)
--                where 
--                c.dpos_position_type = 26000002
--                AND c.dpos_position_date = workingdate
--                and c.dpos_user_id is null;
--                 
--           UPDATE trsystem032 c
--                SET dpos_day_position =
--               (SELECT(nvl(dpos_purchase_amount,0) -nvl(dpos_sale_amount,0))
--                FROM trsystem032 b
--                WHERE b.dpos_position_type = 26000002
--                AND b.dpos_position_date = workingdate
--                and b.dpos_currency_code= c.dpos_currency_code
--                and b.dpos_user_id=c.dpos_user_id),
--                dpos_position_inr =
--                (SELECT (nvl(dpos_purchase_inr,0) -nvl(dpos_sale_inr,0))
--                FROM trsystem032 a
--                WHERE a.dpos_position_type = 26000002
--                AND a.dpos_position_date = workingdate
--                and a.dpos_currency_code= c.dpos_currency_code
--                and a.dpos_user_id=c.dpos_user_id)
--                where 
--                dpos_position_type = 26000002
--                and c.dpos_user_id is not null
--                AND dpos_position_date = workingdate;
--                 
--      if numrecords !=0 then
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.UPDATEPOSITION,GCONST.OPTIONNO, 
--                                      'Currency Position Update'); 
--      else
--        insert into trsystem031 values(workingdate,gconst.fncGenerateSerial(gconst.SERIALDAYLOG),1,GCONST.DAYCLOSED,
--                                       GCONST.UPDATEPOSITION,GCONST.OPTIONYES, 
--                                      ''); 
--                                      
--        
--      end if;
--  varOperation := 'Updating Commodity Broker Charges'; 
--  prcCalcBrokerCharges(workingdate);
  
  Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('Day Close', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);      
   end prcDayClose;
   
--procedure prcCheckingReminders(workingDate in date) as
--  
--    vartemp             varchar(4000);
--    numrecords          number(5);
--    numGroup            number(8);
--    varFieldName        varchar(50);
--    varTableName        varchar(50);
--    Remindernumber      number(12);
--    varQuery            varchar(1000);
--    dattemp             date;
--    dattemp1            date;
--    numerror            number;
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    curdata             Gconst.DataCursor;
--    xmltemp             Gconst.gClobType%Type;
-- 
--  
--  begin
--     
--        --27600001	Login Reminders
--        --27600002	Mail Reminders
--        --30700102	Date Range
--        --30700103	Date As On
--        --30700104	Month
--        --30700105	Lessthan
--        --30700106	Lessthan=
--        --30700107	Greaterthan
--      
--          
--         delete from trtran022
--                where remu_reminder_number IN
--                    (select remm_reminder_number
--                     from trtran021
--                     where remm_reminder_date = workingDate);
--                     
--        delete from trtran021 
--        where remm_reminder_date = workingDate;
--        
--   
--        for Innercurfileds in( select remp_reminder_code remindercode,remp_periodicity_code PeriodicCode,
--                                      remp_report_query reportquery,remp_report_id reportid,
--                                      remp_report_remarks remarks,remp_report_field as reportfield
--                                 from trsystem013 
--                                where REMP_REMINDER_CODE=27600001)  
--        loop
--        
--                varQuery:='';
--                if Innercurfileds.reportid ='TRADEDEALFORTHEDAY' then
--                  varQuery:=' and Deal_Maturity_date=' ||'''' || workingDate ||'''' ;
--                   varQuery := innercurfileds.ReportQuery || varQuery;
--                   execute immediate  varQuery  into numrecords;
--                elsif Innercurfileds.reportid in('TRDDEALMATUREDBYNXTTWODAYS','HDGDEALMATUREDONNXTTWODAYS') then
--                   
--                    dattemp:=workingDate+2;
--                    dattemp1 := workingDate+1;
--                   varQuery:=' and Deal_Maturity_date Between ' ||'''' || dattemp1 ||'''' || ' and ' ||'''' || dattemp ||'''' ;
--                   varQuery := innercurfileds.ReportQuery || varQuery;
--                   execute immediate  varQuery  into numrecords;
--                end if;
--               
--               IF numrecords > 0 THEN
--                         Remindernumber :=gconst.fncGenerateSerial(gconst.SERIALREMINDER);
--                         insert into trtran021  (REMM_REMINDER_NUMBER,REMM_REPORT_ID,REMM_REMINDER_DATE,
--                                                 REMM_REMINDER_REMARKS,REMM_CREATE_DATE,REMM_FINAL_CONDITION )                                                
--                                          values(Remindernumber,Innercurfileds.reportid,workingdate,
--                                                 Innercurfileds.remarks,workingdate,varQuery);
--                    end if;
----                select to_number(ExtractValue(value(t), '//GroupType')) GroupType ,
----                       to_char(ExtractValue(value(t), '//FieldName')) FieldName,
----                       to_char(ExtractValue(value(t), '//TableName')) TableName
----                       into numGroup,varFieldName,varTableName
----                  from trsystem003 a, trsystem999,
----                       table(xmlsequence(extract(repm_report_params,'//Parameter'))) t
----                 where to_number(ExtractValue(value(t), '//GroupType')) in(30700102,30700103,30700104,30700105,30700106,30700107)
----                   and fldp_table_synonym = ExtractValue(value(t), '//TableName')
----                   and fldp_xml_field = ExtractValue(value(t), '//FieldName')
----                   and repm_report_id = Innercurfileds.reportid; 
----                   
----                select fldp_column_name into varFieldName 
----                  from trsystem999 
----                 where fldp_table_synonym=varTableName
----                   and fldp_xml_field=varFieldName;
----                   
------                select min(hday_calendar_date) into dattemp
------                  from trsystem001 
------                 where hday_day_status in(gconst.DAYNOTOPENED) 
------                   and hday_calendar_date >workingDate
------                   and hday_location_code=30299999;
----                   
----                    select max(hday_calendar_date) into dattemp
----                            from trsystem001 
----                           where hday_location_code=30299999
----                             and hday_day_status in(gconst.DAYCLOSED)
----                             and hday_calendar_date <workingDate;
----                             
----                   if (Innercurfileds.PeriodicCode=26600001) then  --Daily
----                          varQuery :=Innercurfileds.reportquery || ' and ' || varFieldName || ' Between  '|| '''' || workingdate ||  '''' ||' and '|| '''' || workingdate+5 ||  '''';
----                   elsif (Innercurfileds.PeriodicCode=26600002) then  --Weekly
----                      if (to_char(to_date(workingDate),'D') = '1')  then      --To check date is starting day of the week
----                          varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                      elsif (to_char(to_date(workingDate),'D') < to_char(to_date(dattemp),'D')) then
----                         varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                      end if;
----                   elsif (Innercurfileds.PeriodicCode=26600003) then  --Fortnightly
----                       if (to_char(to_date(workingDate),'dd') ='15') then      --To check date is starting day of the week
----                            varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                       elsif ((to_char(to_date(workingDate),'dd') > '15') and (to_char(to_date(dattemp),'dd') <'15')) then
----                            varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                       end if;
----                       
----                   elsif (Innercurfileds.PeriodicCode=26600004) then  --Monthly
----                       if (to_char(to_date(workingDate),'dd') = '01') then      --To check date is starting day of the week
----                            varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                       elsif ((to_char(to_date(workingDate),'dd') > '01') and (to_char(to_date(dattemp),'dd') <'31')) then
----                            varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                       end if;
----                       
----                   elsif (Innercurfileds.PeriodicCode=26600005) then  --Quarterly
----                      if (to_char(to_date(workingDate),'mm') in('03','06','09','12')) then      --To check date is starting day of the week
----                         if (to_char(to_date(workingDate),'dd') = '01') then      --To check date is starting day of the week
----                             varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                         elsif ((to_char(to_date(workingDate),'dd') > '01') and (to_char(to_date(dattemp),'dd') <'31')) then
----                             varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                         end if;
----                      end if;
----                   elsif (Innercurfileds.PeriodicCode=26600006) then  --Half Yearly
----                       if (to_char(to_date(workingDate),'mm') ='06') then      --To check date is starting day of the week
----                         if (to_char(to_date(workingDate),'dd') = 01) then      --To check date is starting day of the week
----                             varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                         elsif ((to_char(to_date(workingDate),'dd') > '01') and (to_char(to_date(dattemp),'dd') <'31')) then
----                             varQuery:=getCondition(workingDate,numGroup,Innercurfileds.PeriodicCode);
----                         end if;
----                      end if;
----                   elsif (Innercurfileds.PeriodicCode=26600007) then  --Yearly
----                          dattemp :=add_months(workingdate,-12);
----                          varQuery :=Innercurfileds.reportquery || ' and ' || varFieldName || ' Between '|| '''' || workingdate ||'''' || ' and ' || ''''|| dattemp  || '''';
----                   end if;
----                     
----                     if varQuery ='' then
----                        goto EndLoop;
----                     end if;
----                   pkgreturnreport.PRCEXTRACTREPORT(
----                                        fncCreateParamDate(Innercurfileds.reportid,
----                                                           varQuery,
----                                                           workingDate,
----                                                           workingDate),
----                                        xmltemp,xmltemp,curdata,curdata);                   
----                                        
----                select to_number(ExtractValue(value(t),'//RecordSets')) into numrecords
----                  from table(xmlsequence(extract(xmltype(xmltemp),'//ErrorData'))) t;
--                
--
--                    
----            end if;
--
--     end loop;
--        INSERT  INTO trtran022(remu_reminder_number,   remu_serial_number,   remu_user_id,   remu_reminder_remarks,   remu_create_date,   remu_record_status)
--                        (SELECT remm_reminder_number, 1,
--                         'Manju123',remm_reminder_remarks,remm_create_date,
--                         10200001 FROM trtran021  WHERE remm_reminder_date= workingDate);
--  Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('Day Close', numError, varMessage, 
--                      varOperation, varError);
--      raise_application_error(-20101, varError);   
--  end  prcCheckingReminders;
--  
  
 function getCondition
             (workdate in date,
              numgroup in number,
              numperiod in number default 0 ) return varchar
  is
  begin
	
      case numgroup
          
          when 30700102 then  --Date Range
            if numperiod=26600001 then --Daily
                return ' = ' || ''''||   workdate ||'''';
            elsif numperiod=26600002 then --Weekly
                 return ' Between ' || ''''||   workdate-7 ||'''' || ' and ' || ''''|| workdate || '''' ;
            elsif numperiod=26600003	 then --Fortnightly
                 return ' Between ' || ''''||   workdate-15 ||'''' || ' and ' || ''''|| workdate || '''' ;
            elsif numperiod=26600004 then --Monthly
                 return ' Between ' || ''''||   add_months(workdate,-1) ||'''' || ' and ' || ''''|| workdate || '''' ;
            elsif numperiod=26600005 then --Quarterly
                 return ' Between ' || ''''||   add_months(workdate,-3) ||'''' || ' and ' || ''''|| workdate || '''' ;
            elsif numperiod=26600006 then --Half Yearly
                 return ' Between ' || ''''||   add_months(workdate,-6) ||'''' || ' and ' || ''''|| workdate || '''' ;
            elsif numperiod=26600007 then --Yearly
                 return ' Between ' || ''''||   add_months(workdate,-12) ||'''' || ' and ' || ''''|| workdate || '''' ;
            end if;
          when 30700103	then  --Date As On
            return ' = ' || '''' ||  workdate || '''';
          when 30700105	then  --Lessthan
            return ' < '|| '''' || workdate ||'''';
          when 30700106	then  --Lessthan=
            return ' <= '|| '''' || workdate ||'''';
          when 30700107	then  --Greaterthan
            return ' > '|| '''' || workdate ||'''';
         when 30700108	then  --Graeaterthan=
            return ' >= '|| '''' || workdate ||'''';
      end case;
  end getcondition;
  
--  procedure prcCheckingReminders(workingDate in date) as
--  
--    vartemp varchar(4000);
--    numrecords number(5);
--    numGroup number(8);
--    Remindernumber number(12);
--    varQuery varchar(1000);
--    dattemp date;
--    numerror number;
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    curdata             Gconst.DataCursor;
--    xmltemp             Gconst.gClobType%Type;
--  begin
--     
--        --27600001	Login Reminders
--        --27600002	Mail Reminders
--        --30700102	Date Range
--        --30700103	Date As On
--        --30700104	Month
--        --30700105	Lessthan
--        --30700106	Lessthan=
--        --30700107	Greaterthan
--               
--         delete from trtran022
--                where remu_reminder_number IN
--                    (select remm_reminder_number
--                     from trtran021
--                     where remm_reminder_date = workingDate);
--                     
--        delete from trtran021 
--        where remm_reminder_date = workingDate;
--        
--   
--        for Innercurfileds in( select remp_reminder_code remindercode,
--                                      remp_report_query reportquery,remp_report_id reportid,
--                                      remp_report_remarks remarks,remp_report_field as reportfield
--                                 from trsystem013 
--                                where REMP_REMINDER_CODE=27600001)  
--        loop
--        
--        
--                select to_number(ExtractValue(value(t), '//GroupType')) GroupType into numGroup
--                  from trsystem003 a, trsystem999,
--                       table(xmlsequence(extract(repm_report_params,'//Parameter'))) t
--                 where to_number(ExtractValue(value(t), '//GroupType')) in(30700102,30700103,30700104,30700105,30700106,30700107)
--                   and fldp_table_synonym = ExtractValue(value(t), '//TableName')
--                   and fldp_xml_field = ExtractValue(value(t), '//FieldName')
--                   and repm_report_id = varTemp; 
--                   
--                   pkgreturnreport.PRCEXTRACTREPORT(
--                                        fncCreateParamDate(Innercurfileds.reportid,
--                                                           Innercurfileds.reportquery,
--                                                           workingDate,
--                                                           workingDate),
--                                        xmltemp,xmltemp,curdata,curdata);                   
--                   
--                   if curdata % rowcount != 0 then
--                   
--                   end if;
--               if (numGroup=30700103) then  --Date As On
--                   varQuery :='and ' || innercurfileds.reportfield || ' = '|| '''' || workingdate ||  '''';
--                   execute immediate  innercurfileds.ReportQuery || varQuery  into numrecords;
--               elsif (Innercurfileds.ReminderCode IN (26800011,26800012,26800013,26800014)) then
--                   dattemp :=workingdate+2;
--                   varQuery :='and ' || innercurfileds.reportfield || ' Between '|| '''' || workingdate ||'''' || ' and ' || ''''|| dattemp  || '''';
--                   execute immediate  innercurfileds.ReportQuery || varQuery  into numrecords;
--                      --execute immediate  innercurfileds.ReportQuery into numrecords using workingdate,workingdate+2 ;
--               end if;
--             IF numrecords > 0 THEN
--                 Remindernumber :=gconst.fncGenerateSerial(gconst.SERIALREMINDER);
--                 insert into trtran021  (REMM_REMINDER_NUMBER,REMM_REMINDER_CODE,REMM_REMINDER_DATE,
--                                         REMM_REMINDER_REMARKS,REMM_CREATE_DATE,REMM_FINAL_CONDITION )                                                
--                                 values(Remindernumber,Innercurfileds.ReminderCode,workingdate,
--                                        Innercurfileds.remarks,workingdate,varQuery);
--            end if;
--            numrecords:=0;
--        end loop;
--        INSERT  INTO trtran022(remu_reminder_number,   remu_serial_number,   remu_user_id,   remu_reminder_remarks,   remu_create_date,   remu_record_status)
--                        (SELECT remm_reminder_number, 1,
--                         rusr_user_id,remm_reminder_remarks,remm_create_date,
--                         10200001 FROM trtran021, trsystem014
--                         WHERE remm_reminder_date= workingDate and  remm_reminder_code = rusr_reminder_code);
--  Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('Day Close', numError, varMessage, 
--                      varOperation, varError);
--      raise_application_error(-20101, varError);   
--  end  prcCheckingReminders;
  procedure prcHolidaysCheck(executiondate in date,
                             BaseCurrency in Number,
                             OtherCurrency in Number,
                             delivaryType in number default 0 ,
                             delivaryOption in number default 0,
                             delivarydays in number default 0,
                             delivarydate in date default sysdate,
                             dateFrom in out date,dateTo in out date) 
is

    numTemp number(5);
    datTemp date;
    numerror number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

  begin
    
       case delivaryType
           when gconst.CASH then
               dateFrom:= executiondate;
               dateto := executiondate;
           when gconst.TOM then
                datefrom :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate+1,1);
                dateTo :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate+1,1);
           when gconst.SPOT then
                datefrom :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate);
                dateTo :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate);
           when gconst.OTHER then
                datefrom :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate,1);
                dateTo :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate,1);                
           when gconst.FORWARDFIXED then
--                datefrom :=fncBankHolidayCheck(delivarydate,CounterParty);
--                dateto :=fncBankHolidayCheck(delivarydate,CounterParty);
                datTemp :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate);
 
                if delivaryOption= gconst.DAYS then
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,(datTemp+delivarydays)-1,1);
                elsif delivaryOption= gconst.MONTHS then
                     datTemp:=add_months(datTemp,delivarydays);
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp-1,1);                     
                elsif delivaryOption=gconst.weeks then
                     numtemp :=((7 * delivarydays)-1);
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp+numtemp,1);
                elsif  delivaryOption=gconst.Years then
                     numtemp :=((12 * delivarydays)-1);
                     datTemp:=add_months(datTemp,numtemp);
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp-1,1);  
                end if;
                   dateFrom:=dateTo;
           when gconst.FORWARDOPTION then
           
                --datTemp :=fncBankHolidayCheck(executiondate+2,CounterParty);
                dattemp :=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,executiondate,4);
 
                if delivaryOption= gconst.DAYS then
                     numtemp :=delivarydays-1;
                     dateFrom:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp+numtemp,1);
                     --dateTo:=fncBankHolidayCheck((datTemp+delivarydays)-1,CounterParty);
                     dateTo:=dateFrom;
                elsif delivaryOption= gconst.MONTHS then
                     numtemp :=delivarydays-1;
                     dateFrom:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,add_months(datTemp,numtemp),0);
                     datTemp:=add_months(datTemp,delivarydays);
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp-1,0);                     
                elsif delivaryOption=gconst.weeks then
                     numtemp := (7 * (delivarydays-1));
                     dateFrom:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp + numtemp,0);
                     numtemp :=((7 * delivarydays)-1);
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp+numtemp,0);
                elsif  delivaryOption=gconst.Years then
                     numtemp :=(12 * (delivarydays-1));
                     dateFrom:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,add_months(datTemp,numtemp),0);
                     numtemp :=((12 * delivarydays)-1);
                     datTemp:=add_months(datTemp,numtemp);
                     dateTo:=pkgforexprocess.fncGetCurrSpotDate(BaseCurrency,OtherCurrency,datTemp-1,0);  
                end if;
           else
            -- this is for Teade Register Forms
             case delivaryOption
                when gconst.DAYS then
                      dateFrom:=executiondate+delivarydays;
                      dateTo:=executiondate+delivarydays;     
                when gconst.weeks then
                     numtemp := (7 * (delivarydays-1));
                     dateFrom:=executiondate + numtemp;
                     numtemp := (7 * (delivarydays))-1;
                     dateTo:=executiondate+numtemp; 
                when gconst.MONTHS then
                     numtemp :=delivarydays-1;
                     dateFrom:=add_months(executiondate,numtemp);
                     datTemp:=add_months(executiondate,delivarydays);
                     dateTo:=datTemp;  ---1;                     
                when gconst.Years then
                     numtemp :=(12 * (delivarydays-1));
                     dateFrom:=add_months(executiondate,numtemp);
                     numtemp :=(12 * (delivarydays));
                     datTemp:=add_months(executiondate,numtemp);
                     dateTo:=datTemp;  ---1;  
              end case;
          end case;
            Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('Day Close', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);   
  end prcHolidaysCheck;
  
 function fncBankHolidayCheck(AsonDate in date,
                              CounterParty in number) 
                              return date 
 is
 
    numError      number;
    numFlag       number(1);
    datReturn     date;
    datTemp       date;
    varOperation  gconst.gvaroperation%type;
    varMessage    gconst.gvarmessage%type;
    varError      gconst.gvarerror%type;

 begin
 
    varMessage := 'Returning Spot Date for ' || AsonDate;
    datReturn := null;
    datTemp := AsonDate;
    numFlag := 0;
    
    varOperation := 'Extracting Holidays for the counter Party';
    for curHoliday in
    (select distinct hday_calendar_date
      from trsystem001
      where hday_location_code in
      (select nvl(lbnk_bank_location, 0) 
        from trmaster306
        where lbnk_pick_code = Counterparty
         and hday_day_status in 
        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2)
        union
       select nvl(lbnk_corr_location,0)
        from trmaster306
        where lbnk_pick_code = CounterParty
        and hday_day_status in 
        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2))
      and hday_calendar_date >= AsonDate 
      order by hday_calendar_date)
    Loop
      numFlag := 1;
      
      if  curHoliday.hday_calendar_date > datTemp then
        datReturn := datTemp;
        exit;
      else
        datTemp := datTemp + 1;
      end if;
      
    End Loop;

    if numFlag = 0 then -- No Holiday records after the date
      select decode(trim(to_char(AsonDate + 2, 'DAY')), 
        'SATURDAY', AsonDate + 2,
        'SUNDAY', AsonDate + 1, 
        AsonDate + 2) 
        into datReturn
        from dual;
    End if;
   
    return datReturn;
Exception
    when others then
      varerror := 'SpotDate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return datReturn;
      
  end fncBankHolidayCheck;
--  Procedure MaturityDayCalc(datExecution in date,numMaturityType in number,numDays in number,numMaturityCode in number,datFrom out date, datTo out Date) is
--    numTemp number;
--  begin
--    case numMaturityType
--       when gconst.CASH then
--          datFrom:= datExecution;
--           datto := datExecution;
--       when gconst.TOM then
--          datfrom :=HolidaysCheck(datExecution+1);
--          datTo :=HolidaysCheck(datExecution+1);
--       when gconst.SPOT then
--          datfrom :=HolidaysCheck(datExecution+2);
--          datTo :=HolidaysCheck(datExecution+2);
--       when gconst.FORWARDFIXED then
--          datfrom :=HolidaysCheck(datExecution);
--          datto :=HolidaysCheck(datExecution);
--       when gconst.FORWARDOPTION then
--          if numMaturityCode=25500002 thrn --add Weeks for the date
--              numtemp := 3+(7*numDays);
--              datfrom :=HolidaysCheck(datExecution +numtemp);
--               numtemp := 3+(7* (numDays-1)); 
--              datto :=HolidaysCheck(datExecution+3+numtemp);
--          elsif numMaturityCode=25500003 then  --add Month for the date
--             
--              datfrom :=HolidaysCheck(datExecution+3+numDays);
--              datto :=HolidaysCheck(datExecution+3+numDays);
--          end if;
--       when gconst.DAYS then
--          dattemp:=HolidaysCheck(datExecution+numtemp);
--       when gconst.MONTHS then
--          dattemp:=HolidaysCheck(add_months(datExecution,numtemp));
--       when gconst.YEARS then
--          dattemp:=HolidaysCheck(add_months(datExecution, (12*numtemp)));
--    end case;
--    return datTemp;
--  end MaturityDayCalc;
--  function MaturityDayCalc(datExecution in date,numDaysType in number,numtemp in number) return date is
--     dattemp date;
--  begin
--     case numDaysType
--        when gconst.DAYS then
--           dattemp:=HolidaysCheck(datExecution+numtemp);
--        when gconst.MONTHS then
--           dattemp:=HolidaysCheck(add_months(datExecution,numtemp));
--        when gconst.YEARS then
--           dattemp:=HolidaysCheck(add_months(datExecution, (12*numtemp)));
--     end case; 
--   return dattemp;   
--  end MaturityDayCalc;

-----------------------------------------------------------------------------------------------------------
 Function prcCalculateHoldingrate
    ( CurrencyCode in Number,
      AsonDate in Date)
    return number
    is
--  Created on 27/03/2008
    numError            number;
    numCode             number;
    numPosition         number(8);
    numRate             number(15,6) := 0;
    numPosFCY           number(15,6) := 0;
    numPosINR           number(15,2) := 0;
    numBuyFCY           number(15,6) := 0;
    numSalFCY           number(15,6) := 0;
    numBuyINR           number(15,2) := 0;
    numSalINR           number(15,2) := 0;
    datToday            date;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    tsDeal              timestamp;
    
Begin
    varMessage := 'Holding Rate Calculation';
    numError := 0;
    numRate := 0.00;
    
    varOperation := 'Extracting Previous Holding Rate';
    select round((drat_spot_bid + drat_spot_ask) / 2,4)
      into numRate
      from trtran012
      where drat_currency_code = CurrencyCode
      and drat_for_currency = GConst.INDIANRUPEE
      and drat_effective_date = 
      (select max(drat_effective_date)
        from trtran012
        where drat_currency_code = CurrencyCode
        and drat_for_currency = GConst.INDIANRUPEE 
        and drat_effective_date <= AsonDate);


--    varOperation := 'Getting Opening day position';
--    Begin
--      select NVL(dpos_position_code,0), NVL(dpos_day_position,0)
--        into numPosition, numPosFcy
--        from trsystem032 a
--        where dpos_company_code = 30199999
--        and dpos_currency_code = CurrencyCode
--        and dpos_position_type = GConst.TRADEDEAL
--        and dpos_position_date =
--        (select max(dpos_position_date)
--          from trsystem032 b 
--          where a.dpos_company_code = b.dpos_company_code
--          and a.dpos_currency_code = b.dpos_currency_code
--          and a.dpos_position_type = b.dpos_position_type
--          and a.dpos_position_date < AsonDate);
--          
--    Exception
--      when no_data_found then
--      numPosition := 0;
--      numPosFcy := 0;
--    End;
-- 
--    if numPosition = 0 then
--      numPosInr := 0;
--      numPosition := GConst.OPTIONYES;
--    else      
--      numPosInr := Round(numPosFcy * numRate,0);
--    end if;
--    
--    if numPosition = GConst.OPTIONNO then
--      numPosFcy := numPosFcy * -1;
--      numPosInr := numPosInr * -1;
--    end if;
--    
--    varOperation := 'Calculating Holding Rate';
--    for curHoldingRate in    
--    (select 1 DealType, to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'),
--      deal_deal_number DealNumber, deal_serial_number DealSerial,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, deal_base_amount,0),0) BuyFCY,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL,deal_base_amount, 0),0)  SaleFCY,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, 
--        decode(deal_other_currency,GConst.INDIANRUPEE,deal_other_amount,deal_amount_local),0),0) BuyINR,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, 
--        decode(deal_other_currency,GConst.INDIANRUPEE,deal_other_amount,deal_amount_local),0),0) SaleINR
--      from trtran001
--      where deal_base_currency = CurrencyCode
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_execute_date = AsonDate
--      and deal_record_status in (10200001, 10200003,10200004)
--    union
----  Cross Currency Deals    
--    select 2 DealType, to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'),
--      deal_deal_number DealNumber, deal_serial_number DealSerial,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, deal_other_amount, 0),0)  BuyFCY,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, deal_other_amount,0),0) SaleFCY,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, deal_amount_local, 0),0) BuyINR,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, deal_amount_local,0),0) SaleINR
--      from trtran001
--      where deal_other_currency = CurrencyCode
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_execute_date = AsonDate
--      and deal_record_status in (10200001, 10200003,10200004)
--    order by 2)
--
--    Loop
--      numCode := curHoldingRate.DealType;
--      numBuyFCY := curHoldingRate.BuyFCY;
--      numSalFCY := curHoldingRate.SaleFCY;
--      numBuyINR := curHoldingRate.BuyINR;
--      numSalINR := curHoldingRate.SaleINR;
--      
--      numPosFCY := (numPosFCY + numBuyFCY) - numSalFCY;
--      numPosInr := (numPosINR + numBuyINR) - numSalINR;
--
--dbms_output.put_line('Rat ' || numRate || 'cur ' || numPosFCY || ' inr: ' || numPosInr);      
--
--      numRate := round(abs(numPosInr) / abs(numPosFCY),4);

      
--      if numCode = 1 then
--        update trtran001
--          set deal_holding_rate = numRate
--          where deal_deal_number = curHoldingRate.DealNumber
--          and deal_serial_number = curHoldingRate.DealSerial;
--      else
--        update trtran001
--          set deal_holding_rate1 = numRate
--          where deal_deal_number = curHoldingRate.DealNumber
--          and deal_serial_number = curHoldingRate.DealSerial;
--      end if;
      
  --  End Loop;
    
    
    return numRate;    
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('HoldingRate', numError, varMessage, 
--                      varOperation, varError);
--      raise_application_error(-20101, varError);                      
--      return numRate;
--End fncHoldingRate;
--
-- loop
--      
-- end loop;

end prcCalculateHoldingrate;
function fnccalcHedgeAmount
             (hedgecurrency in number,
              basecurrency in number,
              hedgeamount in number,
              baseamount in number,
              exeutiondate in date,
              buyorsell in number) return number
is
basespot number;
usdspot number;
hedgespot number;
numtemp number;
numtemp1 number;
begin
     Basespot:=pkgforexprocess.fncGetRate(basecurrency,30400003,exeutiondate,buyorsell);
     usdspot :=pkgforexprocess.fncGetRate(30400004,30400003,exeutiondate,buyorsell);
     hedgespot := pkgforexprocess.fncGetRate(hedgecurrency,30400003,exeutiondate,buyorsell);
     numtemp := (baseamount * (basespot/usdspot));
     numtemp1 := (hedgeamount * (hedgespot/usdspot));
     
     if numtemp >numtemp1 then
          return 0;
     else 
          return 1;
     end if;
     
return 1;
end fnccalcHedgeAmount;
-- if dateType =0  then future date 
-- if dateType =1 then  past date
FUNCTION fnccheckHolidays(fromdate in date,dateType in number default 0)return date is
    datTemp date;
  begin
  if dateType = 0  then 
    if to_char(fromdate,'D')=7 then  -- for checking Sunday
      datTemp  := fromdate+1;
    elsif to_char(fromdate,'D')=6 then  --for Checking Saturday
      datTemp := fromdate+2;
    else
      datTemp := fromdate;
    end if;
  elsif dateType = 1 then
      if to_char(fromdate,'D')=7 then  -- for checking sunday
      datTemp  := fromdate-2;
    elsif to_char(fromdate,'D')=6 then  --for Checking saturday
      datTemp := fromdate-1;
    else
      datTemp := fromdate;
    end if;
  end if;
  return datTemp;
END fnccheckHolidays;
function fncConvRs(num in number,numofDec in number)return varchar 
is
strtemp varchar(25);
strNoDec varchar(20);
lo number(5);
begin
    for lo in 1..numofDec
    loop
      strNoDec:=strNoDec || '9';
    end loop;
    strtemp:=to_char(num,'99G99G99G99G99G99G99G999D'||  strNoDec ,'NLS_NUMERIC_CHARACTERS=.,');
return strtemp;
end fncConvRs;
-- Commodity Deal Broker Charges Calculations
procedure prcCalcBrokerCharges
              (workdate in date)
is
numBookedLots     number(5);
numNoofLots       number(5);
numAmount         number(15,2);
numReverseAmount  number(15,2);
numLoopCount      number(5);
numTemp           number(15,2);
numIntraType      number(8);
numIntraBroker    number(15,6);
numInterType      number(8);
numInterBroker    number(15,6);
numserviceTax     number(15,6);
varDealNo         varchar(25);
numProductUOM     number(15,6);
varOperation      GConst.gvarOperation%Type;
varMessage        GConst.gvarMessage%Type;
varError          GConst.gvarError%Type;   
begin

  delete from trtran055
    where cbro_charges_date= workdate;
       
     select prmc_service_tax 
       into numServiceTax
       from trsystem051;
   varOperation := 'Taking All the Deals Which Entered on :' || workdate;       
   for curFields in (select cmdl_deal_number DealNumber,cmdl_buy_sell BuySell,
                       cmdl_lot_numbers NoOfLots,cmdl_lot_price LotPrice,
                       cmdl_product_quantity ProductQty,cmdl_deal_amount DealAmount,
                       cmdl_counter_party CounterParty
                       from trtran051 
                       where cmdl_deal_number not in 
                       (select crev_deal_number from trtran053)
                       and cmdl_execute_date= workdate)
   loop
     numBookedLots := curFields.NoOfLots;
     numNoofLots:=0;
     numloopCount :=0;
     numProductUOM := curFields.ProductQty/curFields.NoOfLots;
     varOperation := 'Extracting Intra Day Broker Charges and Broker Charges Type'; 
     select cbrk_intraday_charges , cbrk_intraday_broker
       into numIntraType,numIntraBroker
       from trmaster502 where cbrk_pick_code=curFields.CounterParty;
    
     varOperation := 'Extracting Inter Day Broker Charges and Broker Charges Type';   
     select cbrk_intraday_charges , cbrk_intraday_broker
       into numInterType,numInterBroker
       from trmaster502 where cbrk_pick_code=curFields.CounterParty;
   
     varOperation := 'Extracting Deals Which are Got Reversed on the Same day ';   

     for innerCur in ( select crev_deal_number DealNumber,crev_reverse_deal Reversedeal,
                         crev_reverse_lot ReverseLot,
                         (select cmdl_lot_price 
                            from trtran051 
                            where cmdl_deal_number=crev_deal_number) LotPrice
                            from trtran053
                          where crev_reverse_deal= curFields.DealNumber
                          and crev_execute_date= workdate) 
     loop
        numNoofLots :=numNoofLots+ innerCur.ReverseLot;     
        numLoopCount := numLoopCount +1;
        numAmount := innerCur.ReverseLot * numProductUOM * curFields.LotPrice;
        numReverseAmount :=  innerCur.ReverseLot * numProductUOM * innerCur.LotPrice;
        varOperation := 'Inserting Charges when Charges type is single Leg';
        if numIntraType= Gconst.SingleLeg then 
            if numAmount < numReverseAmount then
               numTemp := numReverseAmount;
               varDealNo:=innerCur.DealNumber;
            else
               numTemp := numAmount;
               varDealNo := curFields.DealNumber;
            end if;
            insert into trtran055 (cbro_deal_number,cbro_serial_number,
              cbro_charges_date,cbro_deal_amount,cbro_brokerage_rate,
              cbro_brokerage_amount,cbro_service_tax,cbro_transaction_cost,cbro_Record_status)
              values(varDealNo,numloopCount,WorkDate,
              numTemp,numIntraBroker,numIntraBroker* numTemp,
              numServiceTax* (numIntraBroker* numTemp),0,Gconst.StatusEntry);
        else
            varOperation := 'Inserting charges when Charges type are Both Legs ';
            insert into trtran055 (cbro_deal_number,cbro_serial_number,
              cbro_charges_date,cbro_deal_amount,cbro_brokerage_rate,
              cbro_brokerage_amount,cbro_service_tax,cbro_transaction_cost,cbro_Record_status)
              values(curFields.DealNumber,numloopCount,WorkDate,
              numAmount,numIntraBroker,numIntraBroker* numAmount,
              numServiceTax* (numIntraBroker* numAmount),0,Gconst.StatusEntry);

            insert into trtran055 (cbro_deal_number,cbro_serial_number,
              cbro_charges_date,cbro_deal_amount,cbro_brokerage_rate,
              cbro_brokerage_amount,cbro_service_tax,cbro_transaction_cost,cbro_Record_status)
              values(innerCur.DealNumber,numloopCount,WorkDate,
              numReverseAmount,numIntraBroker,numIntraBroker* numReverseAmount,
              numServiceTax* (numIntraBroker* numReverseAmount),0,Gconst.StatusEntry);
        end if;
     end Loop;
     numLoopCount:=numLoopCount+1;
     varOperation := 'Inserting Charges for which lot not at Reversed :' || curFields.DealNumber;
     if ((numLoopCount =0) or (numBookedLots > numNoofLots)) then
         numAmount := (numBookedLots-numNoofLots)* numProductUOM *  curFields.LotPrice;
         
         insert into trtran055 (cbro_deal_number,cbro_serial_number,
           cbro_charges_date,cbro_deal_amount,cbro_brokerage_rate,
           cbro_brokerage_amount,cbro_service_tax,cbro_transaction_cost,cbro_Record_status)
           values(curFields.DealNumber,numloopCount,WorkDate,
           numAmount,numInterBroker,numInterBroker* numAmount,
           numServiceTax* (numInterBroker* numAmount),0,Gconst.StatusEntry);
     end if;
   end loop;
     varOperation := 'Inserting Charges Which Reversed Today :' ;
     for CurOutter in (select crev_deal_number DealNumber,crev_reverse_deal Reversedeal,
                         crev_reverse_lot ReverseLot,cmdl_lot_price LotPrice,cmdl_counter_party CounterParty,
                         cmdl_deal_amount DealAmount,cmdl_lot_numbers NoOfLots
                         from trtran053,trtran051
                         where cmdl_deal_number=crev_deal_number
                         and crev_reverse_deal not in (select cmdl_deal_number 
                            from trtran051 
                            where cmdl_execute_date=workdate)
                         and crev_execute_Date= workdate) 
    loop
     --varOperation := 'Extracting Inter Day Broker Charges and Broker Charges Type';   
     select cbrk_intraday_charges , cbrk_intraday_broker
       into numInterType,numInterBroker
       from trmaster502 where cbrk_pick_code=CurOutter.CounterParty;
       
        insert into trtran055 (cbro_deal_number,cbro_serial_number,
           cbro_charges_date,cbro_deal_amount,cbro_brokerage_rate,
           cbro_brokerage_amount,cbro_service_tax,cbro_transaction_cost,cbro_Record_status)
           values(CurOutter.DealNumber,1,WorkDate,
           CurOutter.DealAmount,numInterBroker,numInterBroker* CurOutter.DealAmount,
           numServiceTax* (numInterBroker* CurOutter.DealAmount),0,Gconst.StatusEntry);
     end loop;
   commit;
Exception
    when others then
      varError := SQLERRM || SQLCODE;
      varerror := 'Updating Commodity Broker Charges: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
end prcCalcBrokerCharges;

function fncCreateParamDate(reportid in varchar,Condition in varchar,asondate in date,todate in date) return Gconst.gClobType%Type
is 
 xmlDoc              Gconst.gClobType%Type;
 numerror            number(10);
 varXml              varchar(4000);
begin

 varXml:=('<?xml version="1.0" ?> 
  <Treasury>
  <CompanyID>30199999</CompanyID> 
  <LocationID>30299999</LocationID> 
  <UserID>Manju123</UserID> 
  <WorkDate>04/08/2008</WorkDate> 
  <TerminalID>0019D1A6B3BC</TerminalID> 
  <CommandSet>
  <Entity>REPORTVIEWER</Entity> 
  <Action>131</Action> 
  <Type /> 
  <KeyValues /> 
  <ReportID>' || reportid ||' </ReportID> 
  <Condition>'|| Condition || '</Condition> 
  <AsonDate>'|| asondate || '</AsonDate> 
  <ToDate>'|| todate ||'</ToDate> 
  <LocalBank>'|| 0 || ' <LocalBank>
  </CommandSet>
  </Treasury>');
  
  xmlDoc:=varXml;
  return xmldoc;
END FNCCREATEPARAMDATE;
FUNCTION fncforwardoutstanding(DATWORKDATE IN DATE) RETURN NUMBER
IS

PRAGMA AUTONOMOUS_TRANSACTION;
datlastworkingday DATE;
NUMRATE NUMBER(15,6);
VAREERORMSG VARCHAR2(2500);
VARSERIALNUMBER VARCHAR2(40);
NUMOUTSTANDINGAMT NUMBER(15,2);
NUMRECORDS NUMBER;
NUMERROR NUMBER;
DATEASON DATE;
DATRATEEFFECTIVE date;
varOperation        GConst.gvarOperation%Type;
varMessage          GConst.gvarMessage%Type;
varError            GConst.gvarError%Type;

CURSOR CUROUTSTANDING IS
SELECT * FROM trtran002 WHERE TRAD_CONTRACT_NO IS NOT NULL 
      AND TO_CHAR(TRAD_MATURITY_DATE,'yyyymm')= TO_CHAR( (last_day(add_months(DATWORKDATE,-1))),'yyyymm')
      AND TRAD_PRODUCT_CATEGORY IN (33300001,33300002,33300004)
      AND (TRAD_PROCESS_COMPLETE IS NULL OR TRAD_PROCESS_COMPLETE=12400002)
      AND TRAD_RECORD_STATUS NOT IN (10200005,10200006);
BEGIN
     VAREERORMSG :='Getting the Last working Day of the month';
     SELECT MIN(HDAY_CALENDAR_DATE) INTO DATLASTWORKINGDAY FROM TRSYSTEM001 
         WHERE HDAY_CALENDAR_DATE > (trunc(DATWORKDATE , 'month')-1)
          AND HDAY_DAY_STATUS < 26400004 ; 
       
IF DATWORKDATE =DATLASTWORKINGDAY THEN
   FOR CURDATA IN CUROUTSTANDING
    LOOP
     begin 
      NUMOUTSTANDINGAMT :=PKGFOREXPROCESS.FNCPURCHASECONTRACTOS(CURDATA.TRAD_TRADE_REFERENCE,
                               TRUNC(DATWORKDATE,'month')-1 , CURDATA.TRAD_MATURITY_DATE, CURDATA.TRAD_CONTRACT_NO);
     ---  INSERT INTO TEMP VALUES(CURDATA.TRAD_CONTRACT_NO,NUMOUTSTANDINGAMT); COMMIT;
      IF NUMOUTSTANDINGAMT >0 THEN
         
          SELECT COUNT(*) INTO NUMRECORDS FROM trtran002
              WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
              AND TO_CHAR(TRAD_MATURITY_DATE,'yyyymm') =TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')
              AND TRAD_RECORD_STATUS NOT IN (10200005,10200006);
         
         IF  NUMRECORDS =0 THEN
           
            VAREERORMSG :='Generate Serial Number';
            VARSERIALNUMBER :=PKGGLOBALMETHODS.FNCGENERATESERIAL(10900015,0);
          
            VAREERORMSG :='Getting bench mark  Date from  trtran002 ';
            begin
            SELECT TRAD_REFERENCE_DATE INTO DATEASON FROM trtran002 
                WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
                  AND TRAD_TRADE_CURRENCY=CURDATA.TRAD_TRADE_CURRENCY
                  AND TRAD_IMPORT_EXPORT=25900086 AND TRAD_PRODUCT_CATEGORY IN (33300001,33300002,33300004) 
                  AND TRAD_RECORD_STATUS NOT IN (10200005,10200006) ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 SELECT min(TRAD_REFERENCE_DATE) INTO DATEASON FROM trtran002 
                WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
                  AND TRAD_TRADE_CURRENCY=CURDATA.TRAD_TRADE_CURRENCY
                  AND TRAD_IMPORT_EXPORT=25900077 AND TRAD_PRODUCT_CATEGORY IN (33300001,33300002,33300004) 
                  AND TRAD_RECORD_STATUS NOT IN (10200005,10200006) ;
            end;
              VAREERORMSG :='Getting bench mark effective Date from  Trtran012 ';
     
             SELECT MAX(DRAT_EFFECTIVE_DATE) INTO DATRATEEFFECTIVE FROM TRTRAN012 WHERE DRAT_EFFECTIVE_DATE <=DATEASON
                                AND DRAT_CURRENCY_CODE =CURDATA.TRAD_TRADE_CURRENCY  AND DRAT_FOR_CURRENCY=30400003
                                AND DRAT_RECORD_STATUS NOT IN (10200005,10200006);
      
             VAREERORMSG :='Getting rate Bench mark rate from  Trtran012 table';
             NUMRATE :=PKGFOREXPROCESS.FNCGETRATE(CURDATA.TRAD_TRADE_CURRENCY,30400003,DATRATEEFFECTIVE,25300001,0,
                          LAST_DAY(ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1)),0);
           
         --  INSERT INTO TEMP VALUES(DATRATEEFFECTIVE,NUMRATE); COMMIT;
            
            VAREERORMSG :='Inserting Data into Trtran002 table';
            INSERT INTO trtran002 (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,TRAD_REVERSE_REFERENCE,
                TRAD_REVERSE_SERIAL,TRAD_IMPORT_EXPORT,TRAD_LOCAL_BANK,TRAD_ENTRY_DATE,TRAD_USER_REFERENCE,
                TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,TRAD_TRADE_CURRENCY,TRAD_PRODUCT_CODE,
                TRAD_PRODUCT_DESCRIPTION,TRAD_TRADE_FCY,TRAD_TRADE_RATE,TRAD_TRADE_INR,TRAD_PERIOD_CODE,
                TRAD_TRADE_PERIOD,TRAD_TENOR_CODE,TRAD_TENOR_PERIOD,TRAD_MATURITY_FROM,TRAD_MATURITY_DATE,
                TRAD_PROCESS_COMPLETE,TRAD_COMPLETE_DATE,TRAD_TRADE_REMARKS,
                TRAD_CREATE_DATE,TRAD_ENTRY_DETAIL,TRAD_RECORD_STATUS,TRAD_VESSEL_NAME,TRAD_PORT_NAME,
                TRAD_BENEFICIARY,TRAD_USANCE,TRAD_BILL_DATE,TRAD_CONTRACT_NO,TRAD_APP,TRAD_TRANSACTION_TYPE,
                TRAD_PRODUCT_QUANTITY,TRAD_PRODUCT_RATE,TRAD_TERM,TRAD_VOYAGE,TRAD_LINK_BATCHNO,
                TRAD_LINK_DATE,TRAD_LC_BENEFICIARY,TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,
                TRAD_SPOT_RATE,TRAD_SUBPRODUCT_CODE,TRAD_PRODUCT_CATEGORY) VALUES(
            
                CURDATA.TRAD_COMPANY_CODE,'BCCL/PURORD/' || VARSERIALNUMBER,CURDATA.TRAD_REVERSE_REFERENCE,
                CURDATA.TRAD_REVERSE_SERIAL,CURDATA.TRAD_IMPORT_EXPORT,CURDATA.TRAD_LOCAL_BANK,
                CURDATA.TRAD_ENTRY_DATE,CURDATA.TRAD_USER_REFERENCE,
                CURDATA.TRAD_REFERENCE_DATE,CURDATA.TRAD_BUYER_SELLER,CURDATA.TRAD_TRADE_CURRENCY,
                CURDATA.TRAD_PRODUCT_CODE,CURDATA.TRAD_PRODUCT_DESCRIPTION,NUMOUTSTANDINGAMT,
                (NUMRATE + (NUMRATE *2)/100),NUMOUTSTANDINGAMT *(NUMRATE + (NUMRATE *2)/100),CURDATA.TRAD_PERIOD_CODE,
                CURDATA.TRAD_TRADE_PERIOD,CURDATA.TRAD_TENOR_CODE,CURDATA.TRAD_TENOR_PERIOD,
                (last_day(CURDATA.TRAD_MATURITY_DATE )+1),last_day(ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1)),
                12400002,NULL,
                SUBSTR('Outstanding inserted from '|| TO_CHAR( CURDATA.TRAD_MATURITY_DATE ,'yyyymm')||' :'||NUMOUTSTANDINGAMT,1,200),
                datworkdate,CURDATA.TRAD_ENTRY_DETAIL,10200001,CURDATA.TRAD_VESSEL_NAME,
                CURDATA.TRAD_PORT_NAME,CURDATA.TRAD_BENEFICIARY,CURDATA.TRAD_USANCE,CURDATA.TRAD_BILL_DATE,
                CURDATA.TRAD_CONTRACT_NO,CURDATA.TRAD_APP,CURDATA.TRAD_TRANSACTION_TYPE,
                CURDATA.TRAD_PRODUCT_QUANTITY,CURDATA.TRAD_PRODUCT_RATE,CURDATA.TRAD_TERM,CURDATA.TRAD_VOYAGE,
                CURDATA.TRAD_LINK_BATCHNO,CURDATA.TRAD_LINK_DATE,CURDATA.TRAD_LC_BENEFICIARY,
                CURDATA.TRAD_FORWARD_RATE,CURDATA.TRAD_MARGIN_RATE,
                CURDATA.TRAD_SPOT_RATE,CURDATA.TRAD_SUBPRODUCT_CODE,CURDATA.TRAD_PRODUCT_CATEGORY);
                
                  UPDATE trtran002 SET TRAD_PROCESS_COMPLETE=12400001,TRAD_COMPLETE_DATE=DATWORKDATE,
                    TRAD_TRADE_REMARKS = SUBSTR(NVL(TRAD_TRADE_REMARKS,'')||'-Outstanding forward to  '|| TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')||' :'||NUMOUTSTANDINGAMT,1,200)
                 WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
                  AND TRAD_TRADE_REFERENCE=CURDATA.TRAD_TRADE_REFERENCE
                  and TRAD_TRADE_CURRENCY =CURDATA.TRAD_TRADE_CURRENCY
                  AND TO_CHAR(TRAD_MATURITY_DATE,'yyyymm') =TO_CHAR( CURDATA.TRAD_MATURITY_DATE ,'yyyymm')
                  AND TRAD_RECORD_STATUS NOT IN (10200005,10200006);

            --    INSERT INTO TEMP VALUES('BCCL/PURORD/' || VARSERIALNUMBER,SUBSTR('Outstanding inserted from '|| TO_CHAR( CURDATA.TRAD_MATURITY_DATE ,'yyyymm')||' -'||NUMOUTSTANDINGAMT,1,200)); COMMIT;
         ELSIF NUMRECORDS >=1 THEN
           VAREERORMSG :=CURDATA.TRAD_CONTRACT_NO;
          
          
            VAREERORMSG :='Updating outstanding amount in next month contract';
            UPDATE trtran002 SET TRAD_TRADE_FCY=TRAD_TRADE_FCY + NUMOUTSTANDINGAMT,
               TRAD_TRADE_INR =TRAD_TRADE_INR + (NUMOUTSTANDINGAMT * TRAD_TRADE_RATE),
               TRAD_TRADE_REMARKS = SUBSTR(NVL(TRAD_TRADE_REMARKS,'')||'-Outstanding updated from  '|| TO_CHAR( CURDATA.TRAD_MATURITY_DATE ,'yyyymm')||' :'||NUMOUTSTANDINGAMT,1,200)
              WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
                 and TRAD_TRADE_CURRENCY =CURDATA.TRAD_TRADE_CURRENCY
                 AND TO_CHAR(TRAD_MATURITY_DATE,'yyyymm') =TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')
                 AND TRAD_RECORD_STATUS NOT IN (10200005,10200006);
               --  NUMERROR :=SQL%ROWCOUNT;
              --    INSERT INTO TEMP VALUES(NUMERROR||CURDATA.TRAD_CONTRACT_NO,TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')); COMMIT;
        -- ELSE
               UPDATE trtran002 SET TRAD_PROCESS_COMPLETE=12400001,TRAD_COMPLETE_DATE=DATWORKDATE,
                    TRAD_TRADE_REMARKS = SUBSTR(NVL(TRAD_TRADE_REMARKS,'')||'-Outstanding forward to  '|| TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')||' :'||NUMOUTSTANDINGAMT,1,200)
                 WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
                  AND TRAD_TRADE_REFERENCE=CURDATA.TRAD_TRADE_REFERENCE
                  and TRAD_TRADE_CURRENCY =CURDATA.TRAD_TRADE_CURRENCY
                  AND TO_CHAR(TRAD_MATURITY_DATE,'yyyymm') =TO_CHAR( CURDATA.TRAD_MATURITY_DATE ,'yyyymm')
                  AND TRAD_RECORD_STATUS NOT IN (10200005,10200006);
               --    NUMERROR :=SQL%ROWCOUNT;
            --INSERT INTO TEMP VALUES(NUMERROR||'-outstanding forward to '|| TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')||' -'||NUMOUTSTANDINGAMT,TO_CHAR( CURDATA.TRAD_MATURITY_DATE,'yyyymm')); COMMIT;
         end if;
     -- Update the process complete status when the outstanding is less than zero By pv manjunath on 10/10/2014        
      elsif ((NUMOUTSTANDINGAMT <=0) and (CURDATA.TRAD_MATURITY_DATE <=DATWORKDATE))  THEN
             UPDATE trtran002 SET TRAD_PROCESS_COMPLETE=12400001,TRAD_COMPLETE_DATE=DATWORKDATE,
                    TRAD_TRADE_REMARKS = SUBSTR(NVL(TRAD_TRADE_REMARKS,'')||' Move the Process Complete '|| TO_CHAR( ADD_MONTHS(CURDATA.TRAD_MATURITY_DATE ,1),'yyyymm')||' :'||NUMOUTSTANDINGAMT,1,200)
                 WHERE TRAD_CONTRACT_NO =CURDATA.TRAD_CONTRACT_NO
                  AND TRAD_TRADE_REFERENCE=CURDATA.TRAD_TRADE_REFERENCE
                  and TRAD_TRADE_CURRENCY =CURDATA.TRAD_TRADE_CURRENCY
                  AND TO_CHAR(TRAD_MATURITY_DATE,'yyyymm') =TO_CHAR( CURDATA.TRAD_MATURITY_DATE ,'yyyymm')
                  AND TRAD_RECORD_STATUS NOT IN (10200005,10200006);
      END IF;
      
     
    exception
       WHEN OTHERS THEN
       VAREERORMSG := VAREERORMSG||SQLERRM;
--    --   INSERT INTO TEMP VALUES(VAREERORmsg,VAREERORmsg); COMMIT;
    end;
    END LOOP;
    COMMIT;
    return 0;
ELSE
  return 1;
end if;
 
  Exception
    when others then
      varError := SQLERRM || SQLCODE;
      varerror := 'Updating Contract Outstanding : ' || varmessage || VAREERORMSG || varerror;
      raise_application_error(-20101,   varerror);    
-- EXCEPTION             
--   WHEN OTHERS THEN
--   VAREERORMSG := VAREERORMSG||SQLERRM;
  -- INSERT INTO TEMP VALUES(VAREERORmsg,VAREERORmsg); COMMIT;
   RETURN 1;
END FNCFORWARDOUTSTANDING;

--FUNCTION FNCSAPOTHER(DATWORKDATE IN DATE) RETURN NUMBER
--IS
--
--PRAGMA AUTONOMOUS_TRANSACTION;
--DATRATEEFFECTIVE DATE;
--NUMRATE NUMBER(15,6);
--VAREERORMSG VARCHAR2(2500);
--VARSERIALNUMBER VARCHAR2(40);
--
--CURSOR CURSAPOTHER IS
-- SELECT CONR_COMPANY_CODE,CONR_TRADE_REFERENCE,CONR_LOCAL_BANK,
--        CONR_REFERENCE_DATE,CONR_USER_REFERENCE,CONR_BUYER_SELLER,
--        CONR_BASE_CURRENCY,CONR_BASE_AMOUNT,CONR_END_DATE,
--        CONR_TOTAL_QUANTITY,CONR_PRODUCT_RATE,CONR_PAYMENT_TERMS,
--        Conr_Product_Category,CONR_SUB_CATEGORY
--  FROM TRTRAN002C
--  WHERE  CONR_TRADE_REFERENCE is not null and nvl(CONR_BASE_AMOUNT,0) >0 and
--  TRUNC(CONR_ADD_DATE) <= (SELECT MAX(HDAY_CALENDAR_DATE)-1
--                            FROM TRSYSTEM001 WHERE HDAY_CALENDAR_DATE< (SELECT MIN(HDAY_CALENDAR_DATE) 
--                                                                FROM  TRSYSTEM001 WHERE HDAY_DAY_STATUS =26400002)
--                             AND   HDAY_DAY_STATUS =26400005)
--  AND NVL(CONR_PRODUCT_CATEGORY,0) =33300004
--  AND CONR_RECORD_STATUS IN (10200001,10200002,10200003,10200004);
--  
--BEGIN
--     
--      
--    FOR CURDATA IN CURSAPOTHER
--     LOOP
--      BEGIN
--        VAREERORMSG :='Generate Serial Number';
--        VARSERIALNUMBER :=PKGGLOBALMETHODS.FNCGENERATESERIAL(10900015,0);
--      
--        VAREERORMSG :='Getting rate effective Date from  Trtran012 table';
--     
--        SELECT MAX(DRAT_EFFECTIVE_DATE) INTO DATRATEEFFECTIVE FROM TRTRAN012 WHERE DRAT_EFFECTIVE_DATE <=CURDATA.CONR_REFERENCE_DATE
--                                AND DRAT_CURRENCY_CODE =CURDATA.CONR_BASE_CURRENCY  AND DRAT_FOR_CURRENCY=30400003
--                                AND DRAT_RECORD_STATUS NOT IN (10200005,10200006);
--       
--         VAREERORMSG :='Getting rate from  Trtran012 table';
--       
--         NUMRATE :=PKGFOREXPROCESS.FNCGETRATE(CURDATA.CONR_BASE_CURRENCY,30400003,DATWORKDATE,25300001,0,
--                          LAST_DAY(CURDATA.CONR_END_DATE),0);
--                          
--        VAREERORMSG :='Inserting data into Trtran002 table';   
--             INSERT INTO TRTRAN002
--                        ( TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE, TRAD_REVERSE_REFERENCE, TRAD_REVERSE_SERIAL,
--                          TRAD_IMPORT_EXPORT, TRAD_LOCAL_BANK, TRAD_ENTRY_DATE, TRAD_USER_REFERENCE, TRAD_REFERENCE_DATE,
--                          TRAD_BUYER_SELLER, TRAD_TRADE_CURRENCY, TRAD_PRODUCT_CODE, TRAD_PRODUCT_DESCRIPTION,
--                          TRAD_TRADE_FCY,  TRAD_TRADE_RATE,  TRAD_TRADE_INR,  TRAD_PERIOD_CODE, TRAD_TRADE_PERIOD,
--                          TRAD_TENOR_CODE,  TRAD_TENOR_PERIOD, TRAD_MATURITY_FROM, TRAD_MATURITY_DATE,
--                          TRAD_MATURITY_MONTH, TRAD_PROCESS_COMPLETE,  TRAD_COMPLETE_DATE,
--                          TRAD_CREATE_DATE, TRAD_ENTRY_DETAIL,TRAD_RECORD_STATUS, TRAD_PRODUCT_QUANTITY,
--                          TRAD_PRODUCT_RATE,  TRAD_TERM,TRAD_CONTRACT_NO,TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_TRADE_REMARKS
--                        ) VALUES(
--                          CURDATA.CONR_COMPANY_CODE,'BCCL/PURORD/' || VARSERIALNUMBER,
--                          CURDATA.CONR_TRADE_REFERENCE,1,25900077,CURDATA.CONR_LOCAL_BANK,
--                          CURDATA.CONR_REFERENCE_DATE,CURDATA.CONR_USER_REFERENCE,CURDATA.CONR_REFERENCE_DATE,
--                          CURDATA.CONR_BUYER_SELLER,CURDATA.CONR_BASE_CURRENCY,
--                          DECODE(CURDATA.CONR_SUB_CATEGORY,33800051,24200003,33800052,24200007,33800053,24200006,33800054,24200006,
--                          33800055,24200004,33800056,24200010,24200058),NULL,CURDATA.CONR_BASE_AMOUNT, 
--                          (NUMRATE + (NUMRATE *2)/100),CURDATA.CONR_BASE_AMOUNT*NUMRATE, 25500001,1,25500001,1,
--                          TRUNC(CURDATA.CONR_END_DATE,'month'),LAST_DAY(CURDATA.CONR_END_DATE), LAST_DAY(CURDATA.CONR_END_DATE),
--                          12400002,NULL,SYSDATE,NULL,10200001,CURDATA.CONR_TOTAL_QUANTITY,CURDATA.CONR_PRODUCT_RATE,
--                          CURDATA.CONR_PAYMENT_TERMS,CURDATA.CONR_USER_REFERENCE,CURDATA.CONR_PRODUCT_CATEGORY,CURDATA.CONR_SUB_CATEGORY,'Batch Insert after 2 working Day'); 
--                     
--           VAREERORMSG :='Updateing data in Trtran002c table';  
--           UPDATE TRTRAN002C SET CONR_RECORD_STATUS =10200005 WHERE CONR_TRADE_REFERENCE =CURDATA.CONR_TRADE_REFERENCE ;
--     
--      EXCEPTION     
--         WHEN OTHERS THEN
--             VAREERORMSG := VAREERORMSG||SQLERRM;
--           --  INSERT INTO TEMP VALUES(CURDATA.CONR_TRADE_REFERENCE,VAREERORmsg); COMMIT;      
--      end;  
--       end loop;
--           commit;
--           RETURN 0;
-- EXCEPTION             
--   WHEN OTHERS THEN
--   VAREERORMSG := VAREERORMSG||SQLERRM;
-- --  INSERT INTO TEMP VALUES(VAREERORmsg,VAREERORmsg); COMMIT;
--   RETURN 1;
--end;

--- modified by Prashant Panda/Prateek on 04th July 2014   ----

FUNCTION FNCSAPOTHER(DATWORKDATE IN DATE) RETURN NUMBER
IS

PRAGMA AUTONOMOUS_TRANSACTION;
DATRATEEFFECTIVE DATE;
NUMRATE NUMBER(15,6);
VAREERORMSG VARCHAR2(2500);
VARSERIALNUMBER VARCHAR2(40);
NUMRECORD number;
varOperation        GConst.gvarOperation%Type;
varMessage          GConst.gvarMessage%Type;
varError            GConst.gvarError%Type;
datMaturityDate date;

CURSOR CURSAPOTHER IS
 SELECT CONR_COMPANY_CODE,CONR_TRADE_REFERENCE,CONR_LOCAL_BANK,
        CONR_REFERENCE_DATE,CONR_USER_REFERENCE,CONR_BUYER_SELLER,
        CONR_BASE_CURRENCY,CONR_BASE_AMOUNT,CONR_END_DATE,
        CONR_TOTAL_QUANTITY,CONR_PRODUCT_RATE,CONR_PAYMENT_TERMS,
        Conr_Product_Category,CONR_SUB_CATEGORY
  FROM TRTRAN002C
  WHERE  CONR_TRADE_REFERENCE is not null and nvl(CONR_BASE_AMOUNT,0) >0 and
  TRUNC(CONR_ADD_DATE) <= (SELECT MAX(HDAY_CALENDAR_DATE)-1
                            FROM TRSYSTEM001 WHERE HDAY_CALENDAR_DATE< (SELECT MIN(HDAY_CALENDAR_DATE) 
                                                                FROM  TRSYSTEM001 WHERE HDAY_DAY_STATUS =26400002)
                             AND   HDAY_DAY_STATUS =26400005)
  AND NVL(CONR_PRODUCT_CATEGORY,0) =33300004
  AND CONR_RECORD_STATUS IN (10200001,10200002,10200003,10200004);
  
BEGIN
     
      
    FOR CURDATA IN CURSAPOTHER
     LOOP
    ---  BEGIN
       
      
        VAREERORMSG :='Getting rate effective Date from  Trtran012 table' || CURDATA.CONR_USER_REFERENCE ;
     
        SELECT MAX(DRAT_EFFECTIVE_DATE) INTO DATRATEEFFECTIVE FROM TRTRAN012 WHERE DRAT_EFFECTIVE_DATE <=CURDATA.CONR_REFERENCE_DATE
                                AND DRAT_CURRENCY_CODE =CURDATA.CONR_BASE_CURRENCY  AND DRAT_FOR_CURRENCY=30400003
                                AND DRAT_RECORD_STATUS NOT IN (10200005,10200006);
       
         VAREERORMSG :='Getting rate from  Trtran012 table' || CURDATA.CONR_USER_REFERENCE ;
       
       -- delete from temp;
         
         
       --  commit;
         if LAST_DAY(CURDATA.CONR_END_DATE) < DATWORKDATE then
            datMaturityDate:= last_day(DATWORKDATE);
         else
            datMaturityDate:= LAST_DAY(CURDATA.CONR_END_DATE);
         end if;   
         
         NUMRATE :=PKGFOREXPROCESS.FNCGETRATE(CURDATA.CONR_BASE_CURRENCY,30400003,DATWORKDATE,25300001,0,
                          datMaturityDate,0);
         
       --  insert into temp values ('before into Table',NUMRATE);
        SELECT COUNT(*) INTO NUMRECORD FROM  TRTRAN002 
          WHERE TRAD_USER_REFERENCE=CURDATA.CONR_USER_REFERENCE
          and   TRAD_PRODUCT_CATEGORY=33300004;  
         
         
        IF NUMRECORD =0 THEN
              VAREERORMSG :='Generate Serial Number'  || CURDATA.CONR_USER_REFERENCE ;
           --   insert into temp values ('Entered into Table','Entered');
            --  commit;
              VARSERIALNUMBER :=PKGGLOBALMETHODS.FNCGENERATESERIAL(10900015,0);
            --  insert into temp values ('Entered into Table',VARSERIALNUMBER);
             VAREERORMSG :='Inserting data into Trtran002 table'  || CURDATA.CONR_USER_REFERENCE ;   
             INSERT INTO TRTRAN002
                        ( TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE, TRAD_REVERSE_REFERENCE, TRAD_REVERSE_SERIAL,
                          TRAD_IMPORT_EXPORT, TRAD_LOCAL_BANK, TRAD_ENTRY_DATE, TRAD_USER_REFERENCE, TRAD_REFERENCE_DATE,
                          TRAD_BUYER_SELLER, TRAD_TRADE_CURRENCY, TRAD_PRODUCT_CODE, TRAD_PRODUCT_DESCRIPTION,
                          TRAD_TRADE_FCY,  TRAD_TRADE_RATE,  TRAD_TRADE_INR,  TRAD_PERIOD_CODE, TRAD_TRADE_PERIOD,
                          TRAD_TENOR_CODE,  TRAD_TENOR_PERIOD, TRAD_MATURITY_FROM, TRAD_MATURITY_DATE,
                           TRAD_PROCESS_COMPLETE,  TRAD_COMPLETE_DATE,
                          TRAD_CREATE_DATE, TRAD_ENTRY_DETAIL,TRAD_RECORD_STATUS, TRAD_PRODUCT_QUANTITY,
                          TRAD_PRODUCT_RATE,  TRAD_TERM,TRAD_CONTRACT_NO,TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_TRADE_REMARKS
                        ) VALUES(
                          CURDATA.CONR_COMPANY_CODE,'BCCL/PURORD/' || VARSERIALNUMBER,
                          CURDATA.CONR_TRADE_REFERENCE,1,25900077,CURDATA.CONR_LOCAL_BANK,
                          CURDATA.CONR_REFERENCE_DATE,CURDATA.CONR_USER_REFERENCE,CURDATA.CONR_REFERENCE_DATE,
                          CURDATA.CONR_BUYER_SELLER,CURDATA.CONR_BASE_CURRENCY,
                          DECODE(CURDATA.CONR_SUB_CATEGORY,33800051,24200003,33800052,24200007,33800053,24200006,33800054,24200006,
                          33800055,24200004,33800056,24200010,24200058),NULL,CURDATA.CONR_BASE_AMOUNT, 
                          (NUMRATE + (NUMRATE *2)/100),CURDATA.CONR_BASE_AMOUNT*NUMRATE, 25500001,1,25500001,1,
                          TRUNC(CURDATA.CONR_END_DATE,'month'),datMaturityDate, 
                          12400002,NULL,SYSDATE,NULL,10200001,CURDATA.CONR_TOTAL_QUANTITY,CURDATA.CONR_PRODUCT_RATE,
                          CURDATA.CONR_PAYMENT_TERMS,CURDATA.CONR_USER_REFERENCE,CURDATA.CONR_PRODUCT_CATEGORY,CURDATA.CONR_SUB_CATEGORY,'Batch Insert after 2 working Day'); 
                     
           VAREERORMSG :='Updating data in Trtran002c table'  || CURDATA.CONR_USER_REFERENCE ;  
           UPDATE TRTRAN002C SET CONR_RECORD_STATUS =10200005 WHERE CONR_TRADE_REFERENCE =CURDATA.CONR_TRADE_REFERENCE ;
     ELSE
        VAREERORMSG :='updating data into Trtran002 table'  || CURDATA.CONR_USER_REFERENCE ;
        UPDATE TRTRAN002 SET TRAD_LOCAL_BANK=CURDATA.CONR_LOCAL_BANK,
                             TRAD_ENTRY_DATE=CURDATA.CONR_REFERENCE_DATE,  
                             TRAD_REFERENCE_DATE=CURDATA.CONR_REFERENCE_DATE,
                             TRAD_BUYER_SELLER=CURDATA.CONR_BUYER_SELLER,
                             TRAD_TRADE_CURRENCY=CURDATA.CONR_BASE_CURRENCY,
                             TRAD_PRODUCT_CODE=DECODE(CURDATA.CONR_SUB_CATEGORY,33800051,24200003,33800052,24200007,33800053,24200006,33800054,24200006,
                                                       33800055,24200004,33800056,24200010,24200058),
                            TRAD_TRADE_FCY=CURDATA.CONR_BASE_AMOUNT,  
                            TRAD_TRADE_RATE=(NUMRATE + (NUMRATE *2)/100),  
                            TRAD_TRADE_INR=CURDATA.CONR_BASE_AMOUNT*NUMRATE,
                            TRAD_MATURITY_FROM=TRUNC(CURDATA.CONR_END_DATE,'month'), 
                            TRAD_MATURITY_DATE=datMaturityDate,
                            --TRAD_MATURITY_MONTH=datMaturityDate,  
                            TRAD_CREATE_DATE=SYSDATE, TRAD_RECORD_STATUS=10200004, 
                            TRAD_PRODUCT_QUANTITY=CURDATA.CONR_TOTAL_QUANTITY,
                            TRAD_PRODUCT_RATE=CURDATA.CONR_PRODUCT_RATE, 
                            TRAD_TERM=CURDATA.CONR_PAYMENT_TERMS,
                            TRAD_SUBPRODUCT_CODE=CURDATA.CONR_SUB_CATEGORY
          WHERE TRAD_USER_REFERENCE=CURDATA.CONR_USER_REFERENCE
          AND   TRAD_PRODUCT_CATEGORY=33300004 
          AND  TRAD_PROCESS_COMPLETE=12400002 ;
        
        VAREERORMSG :='Updateing data in Trtran002c table'  || CURDATA.CONR_USER_REFERENCE ;  
        UPDATE TRTRAN002C SET CONR_RECORD_STATUS =10200005 WHERE CONR_TRADE_REFERENCE =CURDATA.CONR_TRADE_REFERENCE ;
   

     END IF;
     
--      EXCEPTION     
--         WHEN OTHERS THEN
--             VAREERORMSG := VAREERORMSG||SQLERRM;
--             INSERT INTO TEMP VALUES(CURDATA.CONR_TRADE_REFERENCE,VAREERORmsg); COMMIT;      
--      end;  
       end loop;
           commit;
           RETURN 0;
 EXCEPTION             
   WHEN OTHERS THEN
   VAREERORMSG := VAREERORMSG||SQLERRM;
      varError := SQLERRM || SQLCODE;
      varerror := 'Updating Contract Outstanding : ' || varmessage || VAREERORMSG || varerror;
      raise_application_error(-20101,   varerror);    
   RETURN 1;
end;



---- end here ----

END DAYOPENDAYEND;
/