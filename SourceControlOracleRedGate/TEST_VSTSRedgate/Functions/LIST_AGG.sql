CREATE OR REPLACE function "TEST_VSTSRedgate".list_agg(refno in varchar2,numtype in number)
    return varchar2
    as aggregatevalue varchar2(4000);
    begin
       if numtype=1 then    
            select listagg(a.ScreenName,',')within group (order by a.ScreenName) into aggregatevalue from
            ( select distinct CHGA_SCREEN_NAME ScreenName from tRtran015d,tRtran015e
            where CHAR_REFERENCE_NUMBER=CHGA_REF_NUMBER
            and CHAR_REFERENCE_NUMBER=refno
            and CHAR_record_status not in(10200005,10200006)) a;
       elsif numtype=2 then 
             select listagg(b.ChargeEvent,',')within group (order by b.ChargeEvent) into aggregatevalue from
            ( select distinct Pkgreturncursor.fncgetdescription(CHGA_CHARGING_EVENT,2) ChargeEvent from tRtran015d,tRtran015e
            where CHAR_REFERENCE_NUMBER=CHGA_REF_NUMBER  
            and CHAR_REFERENCE_NUMBER=refno
            and CHAR_record_status not in(10200005,10200006)) b;
       end if;
       return aggregatevalue;
       exception
       when others then
       return '0';
       end list_agg;
/