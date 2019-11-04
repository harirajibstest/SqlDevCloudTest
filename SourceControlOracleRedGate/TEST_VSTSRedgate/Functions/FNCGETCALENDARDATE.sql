CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETCALENDARDATE" ( datCheck date ) return date
as
  datTemp date;
begin
  
 select max(hday_calendar_date) 
   into datTemp
   from trsystem001 
  where 
  hday_calendar_Date < =datCheck  
  and  hday_day_status not in (26400007,26400008,26400009);
 return datTemp;
end;
 
 
 
 
 
 
 
 
 
 
 
 
 
/