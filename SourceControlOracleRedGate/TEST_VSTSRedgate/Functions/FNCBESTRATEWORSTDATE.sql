CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCBESTRATEWORSTDATE" 
  (TradeReference in Varchar,frm_Date in Date,To_Date in date,slno in number) 
    return Date 
    as
    BestWorstRate     number(15,4);
    ReturnValue       Date;
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
    SpotRate          number(15,6);
    RefDate           date;
    frmDate           date;
    
    
    begin
    
                SELECT * into ImpExp,Currency,status,rate,Maturitydate,RefDate  FROM(select TRAD_IMPORT_EXPORT ,TRAD_TRADE_CURRENCY,
                       TRAD_PROCESS_COMPLETE,TRAD_SPOT_RATE,nvl(TRAD_COMPLETE_DATE,To_Date),TRAD_REFERENCE_DATE
                 from trtran002 where trad_trade_reference = TradeReference
                --and TRAD_REFERENCE_DATE between frm_Date and To_date
                Union
                select 25900052,BCRD_CURRENCY_CODE,
                       BCRD_PROCESS_COMPLETE,BCRD_CONVERSION_RATE,nvl(BCRD_COMPLETION_DATE,To_Date),BCRD_SANCTION_DATE
                from trtran045 where BCRD_BUYERS_CREDIT = TradeReference);
                --and BCRD_SANCTION_DATE between frm_Date and To_date);
                
                
                
                frmDate := RefDate;
               
               if status =12400001 and Maturitydate is not null then
                  toDate := Maturitydate;
               else
                  toDate := To_date;
               end if; 
               
               select min(DRAT_EFFECTIVE_DATE) into frmDate  from trtran012 where DRAT_EFFECTIVE_DATE between frmDate and toDate;
       
               if ImpExp > 25900050  then
            begin  
                select  EffDate, Effrate into BestDate,SpotRate
                from(select drat_effective_date EffDate,Min(DRAT_SPOT_BID) Effrate
                from trtran012
                where drat_effective_date between frmDate and toDate
                --and  DRAT_SPOT_BID < rate
                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
                --and rownum = 1
                group by drat_effective_date order by 2 asc) where rownum = 1;
         exception
          when no_data_found then
         BestDate := frmDate;
         SpotRate :=0;
         
       end;            
        begin
                Select  EffDate,Effrate into WorstDate,SpotRate
                from(select drat_effective_date EffDate,Max(DRAT_SPOT_BID) Effrate
                from trtran012
                where drat_effective_date between frmDate and toDate
                --and  DRAT_SPOT_BID > rate 
                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
                --and rownum = 1
                group by drat_effective_date order by 2 desc) where rownum = 1;
           exception
          when no_data_found then
             WorstDate := toDate;
             SpotRate :=0;              
         end;         
              elsif ImpExp < 25900050  then
         begin     
                select EffDate,Effrate into BestDate,SpotRate 
                from (select drat_effective_date EffDate, Max(DRAT_SPOT_ASK) Effrate
                from trtran012
                where drat_effective_date between frmDate and toDate
                --and  DRAT_SPOT_ASK > rate 
                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
                --and rownum = 1
                group by drat_effective_date order by 2 desc) where rownum = 1;
                  exception
          when no_data_found then
            BestDate := To_Date;
            SpotRate :=0;
           end;       
          begin
                select EffDate,Effrate into WorstDate,SpotRate 
                from (select drat_effective_date EffDate,Min(DRAT_SPOT_ASK) Effrate
                from trtran012
                where drat_effective_date between frmDate and toDate
               -- and  DRAT_SPOT_ASK < rate 
                and DRAT_CURRENCY_CODE = Currency and DRAT_FOR_CURRENCY = 30400003
                --and rownum = 1
                group by drat_effective_date order by 2 asc) where rownum = 1;
                 exception
            when no_data_found then
             WorstDate := frmDate;
             SpotRate :=0;              
            end;
               end if;

                        
        if  slno = 1 then --Bestdate
          ReturnValue := BestDate;   
        elsif slno = 2 then --WorstDate
          ReturnValue := WorstDate;
        end if;
        --ReturnValue :=   BestSpot +  BestPrimium;              
    return ReturnValue;
    
    end fncBestRateWorstDate;
/