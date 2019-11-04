CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCFRWDPRIMIUM" 
  (MatDate in Date,FrmDate in Date,slno in number) 
  
    return number 
    as
    Primium     number(15,4);
    Enddaate    date;
    
begin
   Enddaate := last_day( MatDate );
   if slno = 1 then
     select 
          case 
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(to_date(FrmDate,'dd-mm-yy'),'MON') then 
               Round(((select RATE_MONTH1_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd'))
               * (MatDate - (to_date(FrmDate,'dd-mm-yy'))),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),1),'MON')then
               Round((select (RATE_MONTH2_ASK - RATE_MONTH1_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003)and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH1_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),2),'MON')then
               Round((select (RATE_MONTH3_ASK  - RATE_MONTH2_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003)and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH2_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)      
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),3),'MON')then
               Round((select (RATE_MONTH4_ASK - RATE_MONTH3_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH3_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)      
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),4),'MON')then
               Round((select (RATE_MONTH5_ASK - RATE_MONTH4_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH4_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)      
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),5),'MON')then
               Round((select (RATE_MONTH6_ASK - RATE_MONTH5_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH5_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),6),'MON')then
               Round((select (RATE_MONTH7_ASK - RATE_MONTH6_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH6_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)    
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),7),'MON')then
               Round((select (RATE_MONTH8_ASK - RATE_MONTH7_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH7_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),8),'MON')then
               Round((select (RATE_MONTH9_ASK - RATE_MONTH8_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH8_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),9),'MON')then
               Round((select (RATE_MONTH10_ASK - RATE_MONTH9_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH9_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),10),'MON')then
               Round((select (RATE_MONTH11_ASK - RATE_MONTH10_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH10_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          when to_char(to_date(MatDate,'dd/mm/yyyy'),'MON') = to_char(add_months(to_date(FrmDate,'dd-mm-yy'),11),'MON')then
               Round((select (RATE_MONTH12_ASK - RATE_MONTH11_ASK) from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003)/to_char(Last_day(MatDate),'dd') * (MatDate - to_date('01-'||to_char(MatDate,'MON-YY'),'dd-mm-yy')+1)  +
              (select RATE_MONTH11_ASK from trsystem009 where rate_effective_date = (select max(rate_effective_date)from trsystem009 a where a.rate_effective_date <=FrmDate and a.rate_for_currency = 30400003) and RATE_SERIAL_NUMBER = (select max(RATE_SERIAL_NUMBER)from trsystem009 b where b.rate_effective_date = FrmDate and b.rate_for_currency = 30400003) and rate_for_currency = 30400003),4)
          end  into  Primium
     from dual; 
    end if;
    if  slno = 2 then -- twodays spot rate
   --   select DRAT_SPOT_ASK into Primium from trtran012 where drat_effective_date = (select max(drat_effective_date) from trtran012 a where a.drat_effective_date <= FrmDate and a.drat_currency_code = 30400004 and a.DRAT_FOR_CURRENCY = 30400003) and drat_currency_code = 30400004 and DRAT_FOR_CURRENCY = 30400003 ;
      select DRAT_SPOT_ASK into Primium from trtran012 where drat_effective_date = (select max(drat_effective_date) from trtran012 a where a.drat_effective_date <= FrmDate and a.drat_currency_code = 30400004 and a.DRAT_FOR_CURRENCY = 30400003) 
      AND DRAT_SERIAL_NUMBER = (select max(DRAT_SERIAL_NUMBER) from trtran012 B where B.drat_effective_date = FrmDate and B.drat_currency_code = 30400004 and B.DRAT_FOR_CURRENCY = 30400003)and drat_currency_code = 30400004 and DRAT_FOR_CURRENCY = 30400003 ;


    end if;
      return Primium;
end fncFrwdPrimium;
 
 
---------------

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/