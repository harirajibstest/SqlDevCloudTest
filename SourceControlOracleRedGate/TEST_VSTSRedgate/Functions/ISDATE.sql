CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."ISDATE" 
  ( DateText in varchar2, DateFormat in varchar2) 
  
    return number 
    as
--  Created on 09/10/09 TMM
    datTemp     date;
    numError    number;
begin
    numError := 0;
    if  DateText is null then
      return 1;
    end if;
    datTemp := to_date(DateText, DateFormat);
    
    return numError;
Exception
  When others then
    numError := 1;
    return numError;
end IsDate;
/