CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCNEXTWORKINGDAYS" (ASondate in  date, NoofDays in number)
RETURN date
AS 
 datTemp date;   
BEGIN
  
   select hday_calendar_date 
      into datTemp
     from  
     (select rank() over (order by hday_calendar_date asc) rown,   hday_calendar_date from trsystem001
       where hday_day_status not in (26400008,26400009)
         and hday_calendar_date >= ASondate
         and hday_location_code =30299999
   order by hday_calendar_date desc)
       where  rown = NoofDays ;
  RETURN datTemp;
END FNCNEXTWORKINGDAYS;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/