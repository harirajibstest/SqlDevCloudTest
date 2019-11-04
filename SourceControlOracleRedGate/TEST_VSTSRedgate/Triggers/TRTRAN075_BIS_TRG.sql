CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."TRTRAN075_BIS_TRG"  
before insert on "TEST_VSTSRedgate".trtran075
referencing NEW as New OLD as Old
for each row
 
declare
   rowCnt Number := 0;
begin
   select count(*)
     into rowCnt
     from trtran075
    where mtmr_report_date = :New.mtmr_report_date
      and mtmr_user_reference = :New.mtmr_user_reference;
   if rowCnt > 0 then
     delete
      from trtran075
     where mtmr_report_date = :New.mtmr_report_date
       and mtmr_user_reference = :New.mtmr_user_reference;
   end if;
end;
/