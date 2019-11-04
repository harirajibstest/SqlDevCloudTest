CREATE OR REPLACE function "TEST_VSTSRedgate".fncGetQuater( datDatetemp in date) return varchar
as 
 VarTemp varchar(20);
begin
 select (case when  ((to_number( to_char(sysdate,'MM')) >= 1) and (to_number( to_char(sysdate,'MM')) <= 3)) then 'Q4'
             when  ((to_number( to_char(sysdate,'MM')) >= 4) and
                    (to_number( to_char(sysdate,'MM')) <= 6)) then 'Q1'
             when  ((to_number( to_char(sysdate,'MM')) >= 7) and
                    (to_number( to_char(sysdate,'MM')) <= 9)) then 'Q2'
              when  ((to_number( to_char(sysdate,'MM')) >= 10) and
                    to_number( to_char(sysdate,'MM')) <= 12) then 'Q3'
        END) into VarTemp
  from dual;
  
  return VarTemp;
                    
end fncGetQuater;
/