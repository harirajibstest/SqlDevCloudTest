CREATE OR REPLACE Procedure "TEST_VSTSRedgate".prcNOP_DashBoard
(CurrencyCodes in Varchar2,BasisType in number default 3)
as
  varMessage          varchar2(100);
  varOperation        varchar2(100);
  varError	          varchar2(2048);
	numError            number;
  numInflowRate       number(15,6) := 0;
  numOutflowRate      number(15,6) := 0;
  numInflowHedgeRate  number(15,6) := 0;
  numOutflowHedgeRate number(15,6) := 0;
  numExposureRate     number(15,6) := 0;
  numHedgeRate        number(15,6) := 0;
begin
  delete from trsystem997_NOP;
  delete from temp;commit;
  insert into temp values(BasisType,'HariNOP');commit;
  
  if BasisType=1 then
   INSERT INTO trsystem997_NOP
    (POSN_MATURITY_MONTH,POSN_INFLOW_AMOUNT,POSN_OUTFLOWHEDGE_AMOUNT,POSN_OUTFLOW_AMOUNT,
    POSN_INFLOWHEDGE_AMOUNT,POSN_INFLOW_RATE,POSN_HEDGEBUY_RATE,POSN_OUTFLOW_RATE,
    POSN_HEDGESELL_RATE,POSN_MTM_RATE,POSN_MONTH_ORDER)
  SELECT MaturityMonth,SUM(NVL(InflowAmount,0))InflowAmount,SUM(NVL(Outflow_Hedge,0))Outflow_Hedge,
    SUM(NVL(Outflow,0))Outflow,SUM(NVL(Inflow_Hedge,0))Inflow_Hedge,
    NVL(ROUND(SUM(InflowAmount * InflowRate)/SUM(InflowAmount),6),0)InflowRate,
    NVL(ROUND(SUM(Outflow_Hedge * OutflowHedgeRate)/SUM(Outflow_Hedge),6),0)OutflowHedgeRate,
    NVL(ROUND(SUM(Outflow * OutflowRate)/SUM(Outflow),6),0) OutflowRate,
    NVL(ROUND(SUM(Inflow_Hedge * InflowHedgeRate)/SUM(Inflow_Hedge),6),0) InflowHedgeRate,
    nvl(round(avg(MTMRate),6),0),
   to_CHAR(MonthOrder,'YYMMDD')
    FROM(  SELECT  Posn_due_date MaturityMonth,
    SUM(case when  b.erel_main_entity in (91900001) 
       then (case when length(CurrencyCodes)>8 then POSN_USD_VALUE else posn_transaction_amount end) END)InflowAmount,
    sum(case when  b.erel_main_entity in (91900002) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Outflow_Hedge,
    SUM(case when  b.erel_main_entity in (91900003) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end)Outflow,
    sum(case when  b.erel_main_entity in (9190004) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Inflow_Hedge,

    ROUND(case when b.erel_main_entity in (91900001)
        then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) END,6) InflowRate,
         
    ROUND(case when b.erel_main_entity in (91900002) 
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) OutflowHedgeRate,
         
    ROUND(case when b.erel_main_entity in (91900003) 
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
        (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
        SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) end,6) OutflowRate,
        
    ROUND(case when b.erel_main_entity in (91900004)  then 
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
           (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) InflowHedgeRate,
           

    ROUND(SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
              (case when  posn_for_currency!=30400003 then POSN_MTM_WASHRATE else POSN_MTM_RATEACTUAL end))/
              SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)),6) MTMRate,

    Posn_due_date MonthOrder,b.erel_main_entity
    from trsystem997 a left outer join (select erel_entity_relation,erel_main_entity from trsystem008 
                                                    where erel_entity_type=919 and EREL_MAIN_ENTITY<=91900004)b
                                                    on a.posn_account_code=b.erel_entity_relation
                             where posn_transaction_amount!=0
                             and posn_due_date >= SYSDATE
                              and posn_fcy_rate !=0
                              and POSN_USD_VALUE!=0
                               GROUP BY Posn_due_date,b.erel_main_entity
    --GROUP BY TO_CHAR(Posn_due_date,'MON-YYYY'), TO_CHAR(Posn_due_date,'YYYYMM'),posn_account_code
    ORDER BY TO_CHAR(Posn_due_date,'YYYYMM'))GROUP BY MaturityMonth,MonthOrder ORDER BY MonthOrder;
  elsif BasisType=2 then
   INSERT INTO trsystem997_NOP
    (POSN_MATURITY_MONTH,POSN_INFLOW_AMOUNT,POSN_OUTFLOWHEDGE_AMOUNT,POSN_OUTFLOW_AMOUNT,
    POSN_INFLOWHEDGE_AMOUNT,POSN_INFLOW_RATE,POSN_HEDGEBUY_RATE,POSN_OUTFLOW_RATE,
    POSN_HEDGESELL_RATE,POSN_MTM_RATE,POSN_MONTH_ORDER)
        SELECT MaturityMonth,SUM(NVL(InflowAmount,0))InflowAmount,SUM(NVL(Outflow_Hedge,0))Outflow_Hedge,
    SUM(NVL(Outflow,0))Outflow,SUM(NVL(Inflow_Hedge,0))Inflow_Hedge,
    NVL(ROUND(SUM(InflowAmount * InflowRate)/SUM(InflowAmount),6),0)InflowRate,
    NVL(ROUND(SUM(Outflow_Hedge * OutflowHedgeRate)/SUM(Outflow_Hedge),6),0)OutflowHedgeRate,
    NVL(ROUND(SUM(Outflow * OutflowRate)/SUM(Outflow),6),0) OutflowRate,
    NVL(ROUND(SUM(Inflow_Hedge * InflowHedgeRate)/SUM(Inflow_Hedge),6),0) InflowHedgeRate,
    nvl(round(avg(MTMRate),6),0),
    MonthOrder
    FROM( SELECT  trunc(Posn_due_date,'IW') MaturityMonth,
    SUM(case when b.erel_main_entity in (91900001) 
       then (case when length(CurrencyCodes)>8 then POSN_USD_VALUE else posn_transaction_amount end) END)InflowAmount,
    sum(case when b.erel_main_entity in (91900002) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Outflow_Hedge,
    SUM(case when b.erel_main_entity in (91900003) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end)Outflow,
    sum(case when b.erel_main_entity in (91900004)  
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Inflow_Hedge,

    ROUND(case when b.erel_main_entity in (91900001) --Inflow Amt
        then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) END,6) InflowRate,
         
    ROUND(case when b.erel_main_entity in (91900002)  --OutFlow Hedge
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) OutflowHedgeRate,
         
    ROUND(case when b.erel_main_entity in (91900003) --OutFlow Amt
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
        (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
        SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) end,6) OutflowRate,
        
    ROUND(case when b.erel_main_entity in (91900004)  then --Inflow Hedge
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
           (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) InflowHedgeRate,
           

    ROUND(SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
              (case when  posn_for_currency!=30400003 then POSN_MTM_WASHRATE else POSN_MTM_RATEACTUAL end))/
              SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)),6) MTMRate,

    to_char(trunc(Posn_due_date,'IW'),'YYMMDD') MonthOrder,b.erel_main_entity
    from trsystem997 a left outer join (select erel_entity_relation,erel_main_entity from trsystem008 
                                                    where erel_entity_type=919 and EREL_MAIN_ENTITY<=91900004 )b
                                                    on a.posn_account_code=b.erel_entity_relation
                             where posn_transaction_amount!=0
                             and posn_due_date >= SYSDATE
                              and posn_fcy_rate !=0
                              and POSN_USD_VALUE!=0
                               GROUP BY trunc(Posn_due_date,'IW'),b.erel_main_entity

    ORDER BY TO_CHAR(Posn_due_date,'W'))GROUP BY MaturityMonth, MonthOrder ORDER BY MonthOrder;
  elsif Basistype=3 then
  INSERT INTO trsystem997_NOP
    (POSN_MATURITY_MONTH,POSN_INFLOW_AMOUNT,POSN_OUTFLOWHEDGE_AMOUNT,POSN_OUTFLOW_AMOUNT,
    POSN_INFLOWHEDGE_AMOUNT,POSN_INFLOW_RATE,POSN_HEDGEBUY_RATE,POSN_OUTFLOW_RATE,
    POSN_HEDGESELL_RATE,POSN_MTM_RATE,POSN_MONTH_ORDER)
    SELECT MaturityMonth,SUM(NVL(InflowAmount,0))InflowAmount,SUM(NVL(Outflow_Hedge,0))Outflow_Hedge,
    SUM(NVL(Outflow,0))Outflow,SUM(NVL(Inflow_Hedge,0))Inflow_Hedge,
    NVL(ROUND(SUM(InflowAmount * InflowRate)/SUM(InflowAmount),6),0)InflowRate,
    NVL(ROUND(SUM(Outflow_Hedge * OutflowHedgeRate)/SUM(Outflow_Hedge),6),0)OutflowHedgeRate,
    NVL(ROUND(SUM(Outflow * OutflowRate)/SUM(Outflow),6),0) OutflowRate,
    NVL(ROUND(SUM(Inflow_Hedge * InflowHedgeRate)/SUM(Inflow_Hedge),6),0) InflowHedgeRate,
    avg(MTMRate),
    MonthOrder
    FROM(
    SELECT  TO_CHAR(Posn_due_date,'MON-YYYY') MaturityMonth,
    SUM(case when b.erel_main_entity in (91900001)  
       then (case when length(CurrencyCodes)>8 then POSN_USD_VALUE else posn_transaction_amount end) END)InflowAmount,
    sum(case when b.erel_main_entity in (91900002) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Outflow_Hedge,
    SUM(case when b.erel_main_entity in (91900003) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end)Outflow,
    sum(case when b.erel_main_entity in (91900004) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Inflow_Hedge,

    ROUND(case when b.erel_main_entity in (91900001) 
        then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) END,6) InflowRate,
         
    ROUND(case when b.erel_main_entity in (91900002) 
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) OutflowHedgeRate,
         
    ROUND(case when b.erel_main_entity in (91900003) 
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
        (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
        SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) end,6) OutflowRate,
        
    ROUND(case when b.erel_main_entity in (91900004) then
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
           (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) InflowHedgeRate,
           

    ROUND(SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
              (case when  posn_for_currency!=30400003 then POSN_MTM_WASHRATE else POSN_MTM_RATEACTUAL end))/
              SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)),6) MTMRate,

    TO_CHAR(Posn_due_date,'YYYYMM')MonthOrder,b.erel_main_entity
    from trsystem997 a left outer join (select erel_entity_relation,erel_main_entity from trsystem008 
                                                    where erel_entity_type=919 and EREL_MAIN_ENTITY<=91900004)b
                                                    on a.posn_account_code=b.erel_entity_relation
                             where posn_transaction_amount!=0
                             and posn_due_date >= SYSDATE
                              and posn_fcy_rate !=0
                              and POSN_USD_VALUE!=0                              
    GROUP BY TO_CHAR(Posn_due_date,'MON-YYYY'), TO_CHAR(Posn_due_date,'YYYYMM'),b.erel_main_entity
    ORDER BY TO_CHAR(Posn_due_date,'YYYYMM')) GROUP BY MaturityMonth,MonthOrder ORDER BY MonthOrder;
   elsif Basistype=4 then
   INSERT INTO trsystem997_NOP
    (POSN_MATURITY_MONTH,POSN_INFLOW_AMOUNT,POSN_OUTFLOWHEDGE_AMOUNT,POSN_OUTFLOW_AMOUNT,
    POSN_INFLOWHEDGE_AMOUNT,POSN_INFLOW_RATE,POSN_HEDGEBUY_RATE,POSN_OUTFLOW_RATE,
    POSN_HEDGESELL_RATE,POSN_MTM_RATE,POSN_MONTH_ORDER,POSN_LOCATION_CODE)
     SELECT MaturityMonth,SUM(NVL(InflowAmount,0))InflowAmount,SUM(NVL(Outflow_Hedge,0))Outflow_Hedge,
    SUM(NVL(Outflow,0))Outflow,SUM(NVL(Inflow_Hedge,0))Inflow_Hedge,
    NVL(ROUND(SUM(InflowAmount * InflowRate)/SUM(InflowAmount),6),0)InflowRate,
    NVL(ROUND(SUM(Outflow_Hedge * OutflowHedgeRate)/SUM(Outflow_Hedge),6),0)OutflowHedgeRate,
    NVL(ROUND(SUM(Outflow * OutflowRate)/SUM(Outflow),6),0) OutflowRate,
    NVL(ROUND(SUM(Inflow_Hedge * InflowHedgeRate)/SUM(Inflow_Hedge),6),0) InflowHedgeRate,
    avg(MTMRate),
    MonthOrder,Location1
    FROM(
    SELECT  TO_CHAR(Posn_due_date,'MON-YYYY') MaturityMonth,
    SUM(case when b.erel_main_entity in (91900001)  
       then (case when length(CurrencyCodes)>8 then POSN_USD_VALUE else posn_transaction_amount end) END)InflowAmount,
    sum(case when b.erel_main_entity in (91900002) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Outflow_Hedge,
    SUM(case when b.erel_main_entity in (91900003) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end)Outflow,
    sum(case when b.erel_main_entity in (91900004) 
       then (case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Inflow_Hedge,

    ROUND(case when b.erel_main_entity in (91900001) 
        then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) END,6) InflowRate,
         
    ROUND(case when b.erel_main_entity in (91900002) 
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
         (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
         SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) OutflowHedgeRate,
         
    ROUND(case when b.erel_main_entity in (91900003) 
       then SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
        (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
        SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) end,6) OutflowRate,
        
    ROUND(case when b.erel_main_entity in (91900004) then
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
           (case when length(CurrencyCodes)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
           SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) InflowHedgeRate,
           

    ROUND(SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
              (case when  posn_for_currency!=30400003 then POSN_MTM_WASHRATE else POSN_MTM_RATEACTUAL end))/
              SUM((case when length(CurrencyCodes)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)),6) MTMRate,

    TO_CHAR(Posn_due_date,'YYYYMM')MonthOrder,b.erel_main_entity,
    POSN_LOCATION_CODE Location1
    from trsystem997 a left outer join (select erel_entity_relation,erel_main_entity from trsystem008 
                                                    where erel_entity_type=919 and EREL_MAIN_ENTITY<=91900004 )b
                                                    on a.posn_account_code=b.erel_entity_relation
                             where posn_transaction_amount!=0
                             and posn_due_date >= SYSDATE
                              and posn_fcy_rate !=0
                              and POSN_USD_VALUE!=0
    GROUP BY TO_CHAR(Posn_due_date,'MON-YYYY'), TO_CHAR(Posn_due_date,'YYYYMM'),b.erel_main_entity,POSN_LOCATION_CODE 
    ORDER BY TO_CHAR(Posn_due_date,'YYYYMM')) GROUP BY MaturityMonth,MonthOrder,Location1 ORDER BY MonthOrder;
    end if;
--  SELECT MaturityMonth,SUM(NVL(InflowAmount,0))InflowAmount,SUM(NVL(Outflow_Hedge,0))Outflow_Hedge,
--    SUM(NVL(Outflow,0))Outflow,SUM(NVL(Inflow_Hedge,0))Inflow_Hedge,
--    NVL(ROUND(SUM(InflowAmount * InflowRate)/SUM(InflowAmount),6),0)InflowRate,
--    NVL(ROUND(SUM(Outflow_Hedge * OutflowHedgeRate)/SUM(Outflow_Hedge),6),0)OutflowHedgeRate,
--    NVL(ROUND(SUM(Outflow * OutflowRate)/SUM(Outflow),6),0) OutflowRate,
--    NVL(ROUND(SUM(Inflow_Hedge * InflowHedgeRate)/SUM(Inflow_Hedge),6),0) InflowHedgeRate,
--    MTMRate,
--    MonthOrder
--    FROM(
--    SELECT  TO_CHAR(Posn_due_date,'MON-YYYY') MaturityMonth,
--    SUM(case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,25900026) then (case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) END)InflowAmount,
--    sum(case when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,25900014,25900015,25900011,25900012) then (case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Outflow_Hedge,
--    SUM(case when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086,25900091,25900059) then (case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end)Outflow,
--    sum(case when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,25900085,25900074,25900075) then (case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end) end) Inflow_Hedge,
--
--    ROUND(case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,25900026) then SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*(case when length(vartemp)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) END,6) InflowRate,
--    ROUND(case when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,25900014,25900015,25900011,25900012) then SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*(case when length(vartemp)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) OutflowHedgeRate,
--    ROUND(case when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086,25900091,25900059) then SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*(case when length(vartemp)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)) end,6) OutflowRate,
--    ROUND(case when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,25900085,25900074,25900075) then 
--           SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
--           (case when length(vartemp)>8 then POSN_SPOT_RATE else POSN_FCY_RATE end))/
--           SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end))  end,6) InflowHedgeRate,
--
--    ROUND(SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)*
--              (case when length(vartemp)>8 then POSN_MTM_LOCAL else POSN_MTM_RATEACTUAL end))/
--              SUM((case when length(vartemp)>8 then ABS(POSN_USD_VALUE) else ABS(posn_transaction_amount) end)),6) MTMRate,
--
--    TO_CHAR(Posn_due_date,'YYYYMM')MonthOrder
--  FROM( select trsystem997.*,(case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,25900026) then 'Inflow'
--                               when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,25900014,25900015,25900011,25900012) then 'Outflow_Hedge'
--                               when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086,25900091,25900059) then 'Outflow'
--                               when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,25900085,25900074,25900075) then 'Inflow_Hedge' end) ExposureType
--                            from trsystem997
--                             where posn_transaction_amount!=0
--                             and posn_due_date >= SYSDATE
--                              and posn_fcy_rate !=0)
--    GROUP BY TO_CHAR(Posn_due_date,'MON-YYYY'), TO_CHAR(Posn_due_date,'YYYYMM'),posn_account_code
--    ORDER BY TO_CHAR(Posn_due_date,'YYYYMM')) GROUP BY MaturityMonth,MonthOrder ORDER BY MonthOrder ;


    FOR CUR_IN IN(SELECT * FROM trsystem997_NOP)
    LOOP
      numInflowRate       := CUR_IN.POSN_INFLOW_RATE;
      numOutflowRate      := CUR_IN.POSN_OUTFLOW_RATE;
      numInflowHedgeRate  := CUR_IN.POSN_HEDGESELL_RATE;
      numOutflowHedgeRate := CUR_IN.POSN_HEDGEBUY_RATE;
      IF ABS(NVL(CUR_IN.POSN_INFLOW_AMOUNT,0)) > ABS(NVL(CUR_IN.POSN_OUTFLOW_AMOUNT,0)) THEN
        numExposureRate := NVL(numInflowRate,0);
      ELSE
         numExposureRate := NVL(numOutflowRate,0);
      END IF;
      IF ABS(NVL(CUR_IN.POSN_INFLOWHEDGE_AMOUNT,0)) > ABS(NVL(CUR_IN.POSN_OUTFLOWHEDGE_AMOUNT,0)) THEN
        numHedgeRate := NVL(numInflowHedgeRate,0);
      ELSE
         numHedgeRate := NVL(numOutflowHedgeRate,0);
      END IF;    

      UPDATE trsystem997_NOP SET POSN_EXPOSURE_GAP = ABS(NVL(CUR_IN.POSN_INFLOW_AMOUNT,0)) - ABS(NVL(CUR_IN.POSN_OUTFLOW_AMOUNT,0)),
                                 POSN_HEDGE_GAP = ABS(NVL(CUR_IN.POSN_INFLOWHEDGE_AMOUNT,0)) - ABS(NVL(CUR_IN.POSN_OUTFLOWHEDGE_AMOUNT,0))
                                 WHERE POSN_MATURITY_MONTH = CUR_IN.POSN_MATURITY_MONTH AND POSN_MONTH_ORDER = CUR_IN.POSN_MONTH_ORDER;

      UPDATE trsystem997_NOP SET POSN_EXPOSURE_RATE  = NVL(numExposureRate,0),POSN_OVERALLHEDGE_RATE = NVL(numHedgeRate,0) 
                              WHERE POSN_MATURITY_MONTH = CUR_IN.POSN_MATURITY_MONTH AND POSN_MONTH_ORDER = CUR_IN.POSN_MONTH_ORDER;
    END LOOP;

     UPDATE trsystem997_NOP SET POSN_OVERALLHEDGE_RATE = POSN_EXPOSURE_RATE
     where nvl(POSN_OVERALLHEDGE_RATE,0) =0;
--25300001 -- Buy - Outflow
--25300002 --sell --inflow
     UPDATE trsystem997_NOP SET posn_import_export = (case when POSN_EXPOSURE_GAP>0 then 25300002 else 25300001 end);
     
     UPDATE trsystem997_NOP SET POSN_EXPOSURE_RATE=POSN_OVERALLHEDGE_RATE 
     where nvl(POSN_EXPOSURE_RATE,0) =0;

	  --return numError;
    COMMIT;
Exception
	when others then
        numerror := sqlcode;
        varerror := sqlerrm;
        varerror := gconst.fncreturnerror('getdesc',   numerror,   varmessage,   varoperation,   varerror);
        raise_application_error(-20101,   varerror);
        --return vardescription;
    --return numError;
End prcNOP_DashBoard;
/