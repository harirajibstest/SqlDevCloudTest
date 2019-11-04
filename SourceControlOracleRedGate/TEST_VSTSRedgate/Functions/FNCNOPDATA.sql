CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncNOPData
  return number as 
  PRAGMA AUTONOMOUS_TRANSACTION;
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
  INSERT INTO trsystem997_NOP
    (POSN_MATURITY_MONTH,POSN_INFLOW_AMOUNT,POSN_OUTFLOWHEDGE_AMOUNT,POSN_OUTFLOW_AMOUNT,
    POSN_INFLOWHEDGE_AMOUNT,POSN_INFLOW_RATE,POSN_HEDGEBUY_RATE,POSN_OUTFLOW_RATE,
    POSN_HEDGESELL_RATE,POSN_MONTH_ORDER)
  SELECT MaturityMonth,SUM(NVL(InflowAmount,0))InflowAmount,SUM(NVL(Outflow_Hedge,0))Outflow_Hedge,
    SUM(NVL(Outflow,0))Outflow,SUM(NVL(Inflow_Hedge,0))Inflow_Hedge,
    NVL(ROUND(SUM(InflowAmount * InflowRate)/SUM(InflowAmount),6),0)InflowRate,
    NVL(ROUND(SUM(Outflow_Hedge * OutflowHedgeRate)/SUM(Outflow_Hedge),6),0)OutflowHedgeRate,
    NVL(ROUND(SUM(Outflow * OutflowRate)/SUM(Outflow),6),0) OutflowRate,
    NVL(ROUND(SUM(Inflow_Hedge * InflowHedgeRate)/SUM(Inflow_Hedge),6),0) InflowHedgeRate,MonthOrder FROM(
    SELECT  TO_CHAR(Posn_due_date,'MON-YYYY') MaturityMonth,
    SUM(case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,25900026) then POSN_TRANSACTION_AMOUNT END)InflowAmount,
    sum(case when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,25900014,25900015,25900011,25900012) then POSN_TRANSACTION_AMOUNT end) Outflow_Hedge,
    SUM(case when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086,25900091,25900059) then POSN_TRANSACTION_AMOUNT end)Outflow,
    sum(case when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,25900085,25900074,25900075) then POSN_TRANSACTION_AMOUNT end) Inflow_Hedge,
    
    ROUND(case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,25900026) then SUM(POSN_TRANSACTION_AMOUNT*POSN_FCY_RATE)/SUM(POSN_TRANSACTION_AMOUNT) END,6) InflowRate,
    ROUND(case when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,25900014,25900015,25900011,25900012) then SUM(POSN_TRANSACTION_AMOUNT*POSN_FCY_RATE)/SUM(POSN_TRANSACTION_AMOUNT)  end,6) OutflowHedgeRate,
    ROUND(case when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086,25900091,25900059) then SUM(POSN_TRANSACTION_AMOUNT*POSN_FCY_RATE)/SUM(POSN_TRANSACTION_AMOUNT) end,6) OutflowRate,
    ROUND(case when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,25900085,25900074,25900075) then SUM(POSN_TRANSACTION_AMOUNT*POSN_FCY_RATE)/SUM(POSN_TRANSACTION_AMOUNT)  end,6) InflowHedgeRate,
    TO_CHAR(Posn_due_date,'YYYYMM')MonthOrder
  FROM(
    select trsystem997.*,(case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,25900026) then 'Inflow'
                               when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,25900014,25900015,25900011,25900012) then 'Outflow_Hedge'
                               when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086,25900091,25900059) then 'Outflow'
                               when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,25900085,25900074,25900075) then 'Inflow_Hedge' end) ExposureType
                            from trsystem997
                             where posn_transaction_amount!=0
                              and posn_fcy_rate !=0)
    GROUP BY TO_CHAR(Posn_due_date,'MON-YYYY'), TO_CHAR(Posn_due_date,'YYYYMM'),posn_account_code
    ORDER BY TO_CHAR(Posn_due_date,'YYYYMM')) GROUP BY MaturityMonth,MonthOrder ORDER BY MonthOrder ;
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
	  return numError;
    --COMMIT;
Exception
	when others then
    --ROLLBACK;  
    return numError;
End fncNOPData;
/