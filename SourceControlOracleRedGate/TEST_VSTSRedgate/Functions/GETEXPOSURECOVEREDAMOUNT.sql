CREATE OR REPLACE function "TEST_VSTSRedgate".getExposureCoveredAmount
(varExpReference in varchar,datAsOnDate date)
 return number
as
numTemp number(15,2);
begin
    select sum(CASE WHEN HEDG_RECORD_STATUS BETWEEN 10200001 AND 10200004 THEN HEDG_HEDGED_FCY ELSE
    case when HEDG_HEDGED_FCY < nvl(outstandingAmount,0) then HEDG_HEDGED_FCY
                                 else nvl(outstandingAmount,0) end END)
      into numTemp
    from (    
    select hedg_deal_number,HEDG_HEDGED_FCY,HEDG_RECORD_STATUS,
     CASE WHEN DEAL_BASE_CURRENCY = 30400004 THEN
          pkgforexprocess.fncGetOutstanding(hedg_deal_number, 1,1,1, datAsOnDate) 
     WHEN DEAL_OTHER_CURRENCY = 30400004 THEN        
      round(pkgforexprocess.fncGetOutstanding(hedg_deal_number, 1,1,1, datAsOnDate)  * DEAL_EXCHANGE_RATE,2)    end OutstandingAmount
      from trtran004 inner join trtran001
      on hedg_deal_number=deal_deal_number
      where hedg_record_Status not in (10200005,10200006)
      and hedg_trade_Reference=varExpReference
      AND HEDG_LINKED_DATE <= datAsOnDate
      and deal_record_status not in (10200005,10200006)
      union all 
      select hedg_deal_number,
        CASE WHEN (pkgforexprocess.fncGetOutstanding(hedg_deal_number, 1,15,1,datAsOnDate,null,1)) > 0 THEN
            HEDG_HEDGED_FCY ELSE pkgforexprocess.fncGetOutstanding(hedg_deal_number, 1,15,1,datAsOnDate,null,1) END,
            HEDG_RECORD_STATUS,
           pkgforexprocess.fncGetOutstanding(hedg_deal_number, 1,15,1,datAsOnDate,null,1) OutstandingAmount
      from trtran004 inner join trtran071
      on hedg_deal_number=copt_deal_number
      where hedg_record_Status not in (10200005,10200006)
      and hedg_trade_Reference=varExpReference
      AND HEDG_LINKED_DATE <= datAsOnDate
      and copt_record_status not in (10200005,10200006)      
      );
  return numTemp;
exception
 when others then
return 0;
end;
/