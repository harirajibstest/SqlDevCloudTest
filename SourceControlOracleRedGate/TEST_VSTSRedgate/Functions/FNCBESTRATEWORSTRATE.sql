CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCBESTRATEWORSTRATE" 
  (TradeReference in Varchar,frm_Date in Date,To_Date in date,slno in number) 
    return Number 
    as
    BestWorstRate     number(15,4);
    ReturnValue       Number(15,4);
    BestDate          date;
    WorstDate         date;
    BestPrimium       number(15,4);
    WorstPrimium      number(15,4);
    BestSpot          number(15,4);
    WorstSpot         number(15,4);
    ImpExp            number(08);
    Currency          number(08);
    status            number(08);
    rate              number(15,4);
    Maturitydate      date;
    toDate            date;
    frmDate           date;
    SpotRate          number(15,6);
    
    
    begin
    
--                select TRAD_IMPORT_EXPORT,TRAD_TRADE_CURRENCY,
--                       TRAD_PROCESS_COMPLETE,TRAD_SPOT_RATE,nvl(TRAD_COMPLETE_DATE,To_Date)
--                       into ImpExp,Currency,status,rate,Maturitydate
--                from trtran002 where trad_trade_reference = TradeReference
--                and TRAD_REFERENCE_DATE between frmDate and To_date;
                
                  SELECT * into ImpExp,Currency,status,rate,Maturitydate FROM(select TRAD_IMPORT_EXPORT ,TRAD_TRADE_CURRENCY,
                       TRAD_PROCESS_COMPLETE,TRAD_SPOT_RATE,nvl(TRAD_COMPLETE_DATE,To_Date)
                 from trtran002 where trad_trade_reference = TradeReference
                --and TRAD_REFERENCE_DATE between frm_Date and To_date
                Union
                select 25900052,BCRD_CURRENCY_CODE,
                       BCRD_PROCESS_COMPLETE,BCRD_CONVERSION_RATE,nvl(BCRD_COMPLETION_DATE,To_Date)
                from trtran045 where BCRD_BUYERS_CREDIT = TradeReference);
                --and BCRD_SANCTION_DATE between frm_Date and To_date);
               
               if status =12400001 and Maturitydate is not null then
                  toDate := Maturitydate;
               else
                  toDate := To_date;
               end if; 
               
               select min(DRAT_EFFECTIVE_DATE) into frmDate  from trtran012 where DRAT_EFFECTIVE_DATE between frm_Date and toDate;
               
                BestDate := fncBestRateWorstDate(TradeReference,frmDate,TODATE,1);
                WorstDate := fncBestRateWorstDate(TradeReference,frmDate,TODATE,2);
                
--               if ImpExp > 25900050  then
--                select  EffDate, Effrate into BestDate,SpotRate
--                from(select drat_effective_date EffDate,Min(DRAT_SPOT_BID) Effrate
--                from trtran012
--                where drat_effective_date between frmDate and toDate
--                and  DRAT_SPOT_BID < rate
--                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
--                --and rownum = 1
--                group by drat_effective_date order by 2 asc) where rownum = 1;
--
--                Select  EffDate,Effrate into WorstDate,SpotRate
--                from(select drat_effective_date EffDate,Max(DRAT_SPOT_BID) Effrate
--                from trtran012
--                where drat_effective_date between frmDate and toDate
--                and  DRAT_SPOT_BID > rate 
--                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
--                --and rownum = 1
--                group by drat_effective_date order by 2 desc) where rownum = 1;
--              elsif ImpExp < 25900050  then
--                select EffDate,Effrate into BestDate,SpotRate 
--                from (select drat_effective_date EffDate, Max(DRAT_SPOT_ASK) Effrate
--                from trtran012
--                where drat_effective_date between frmDate and toDate
--                and  DRAT_SPOT_ASK> rate 
--                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
--                --and rownum = 1
--                group by drat_effective_date order by 2 desc) where rownum = 1;
--
--                select EffDate,Effrate into WorstDate,SpotRate 
--                from (select drat_effective_date EffDate,Min(DRAT_SPOT_ASK) Effrate
--                from trtran012
--                where drat_effective_date between frmDate and toDate
--                and  DRAT_SPOT_ASK < rate 
--                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
--                --and rownum = 1
--                group by drat_effective_date order by 2 asc) where rownum = 1;
--               end if;

        BestSpot :=  pkgforexprocess.fncGetRate(Currency,30400003,BestDate,
                  (case when ImpExp > 25900050 then 25300001 else 25300002 end),0,null,0);  
      
        WorstSpot := pkgforexprocess.fncGetRate(Currency,30400003,WorstDate,
                  (case when ImpExp > 25900050 then 25300001 else 25300002 end),0,null,0);  
        BestPrimium := (pkgforexprocess.fncGetRate(30400004,30400003,BestDate,
                        (case when ImpExp > 25900050 then 25300001 else 25300002 end),0,
                        (case when status = 12400001 then Maturitydate
                        else 
                        toDate end)                        
                        ,0) - pkgforexprocess.fncGetRate(30400004,30400003,BestDate,
                        (case when ImpExp > 25900050 then 25300001 else 25300002 end),0,null,0));
        WorstPrimium := (pkgforexprocess.fncGetRate(30400004,30400003,WorstDate,
                        (case when ImpExp > 25900050 then 25300001 else 25300002 end),0,
                        (case when status = 12400001 then Maturitydate
                        else 
                        toDate end)                        
                        ,0) - pkgforexprocess.fncGetRate(30400004,30400003,WorstDate,
                        (case when ImpExp > 25900050 then 25300001 else 25300002 end),0,null,0));  
                        

        if slno = 3 then -- BestSpot
          ReturnValue := BestSpot;
        elsif slno = 4 then -- WorstSpot
          ReturnValue := WorstSpot;
        elsif slno = 5 then -- BestPrimium
          ReturnValue := BestPrimium;
        elsif slno = 6 then --WorstPrimium
          ReturnValue := WorstPrimium;
        end if;
        --ReturnValue :=   BestSpot +  BestPrimium;              
    return ReturnValue;
    
    end fncBestRateWorstRate;
 
 
 
 
 
 
 
/