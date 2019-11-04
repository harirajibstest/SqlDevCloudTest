CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."ISNUMBER" 
  ( NumberText in varchar2) 
  
    return number 
    as
--  Created on 10/10/09 TMM
    numTemp     number(15);
    numError    number;
begin
    numError := 0;
    if  NumberText is null then
      return 1;
    end if;
    
    numTemp := to_number(NumberText);    
    return numError;
Exception
  When others then
    numError := 1;
    return numError;
end IsNumber;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/