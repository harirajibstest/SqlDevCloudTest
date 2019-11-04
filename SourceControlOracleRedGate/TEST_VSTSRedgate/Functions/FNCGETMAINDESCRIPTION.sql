CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncGetMainDescription 
  (deal_type in number,COUNTERPARTY in number,recorder in number,TRADER in number,rectype in number) 
    return varchar 
    as
    Description varchar2(100 byte);
    
begin
  if rectype = 1 then
    if deal_type = 33300012 AND COUNTERPARTY NOT IN(30600003) AND TRADER NOT IN(33800018,33800014) AND recorder IN(1,2,3)  THEN
      Description :=  'TREASURY DAILY M2M-Outright';
    elsif deal_type = 33300012 AND COUNTERPARTY IN(30600003) AND TRADER NOT IN(33800018,33800014)  AND recorder IN(2,3) THEN
      Description :=  'TREASURY DAILY M2M-CC Outright';
    elsif deal_type = 33300012 AND COUNTERPARTY NOT IN(30600003) AND TRADER NOT IN(33800018,33800014) AND recorder IN(4,5,6) THEN
      Description :=  'TREASURY DAILY M2M-Options';   
    elsif deal_type = 33300012 AND COUNTERPARTY IN(30600003) AND TRADER NOT IN(33800018,33800014) AND recorder IN(4,5,6) THEN
      Description :=  'TREASURY DAILY M2M-CC Outright';       
    elsif deal_type = 33300012 AND TRADER IN(33800018) AND recorder IN(1,2,3) THEN
      Description :=  'TREASURY DAILY M2M-CCTSY';
    elsif deal_type = 33300012 AND TRADER IN(33800018) AND recorder IN(4,5,6) THEN
      Description :=  'TREASURY DAILY M2M-CCTSY Option';
    elsif deal_type = 33300011 AND TRADER IN(33800014) AND recorder IN(1,2,3) THEN
      Description :=  'TSF DAILY M2M-MT'; 
    elsif deal_type = 33300011 AND TRADER IN(33800014) AND recorder IN(4,5,6) THEN
      Description :=  'TSF DAILY M2M-MT Option';  
    end if;
   elsif  rectype = 2 then
     if deal_type = 33300012 AND COUNTERPARTY NOT IN(30600003) AND  TRADER NOT IN(33800018,33800014) AND recorder IN(1,2,3,4,5,6) THEN
       Description := 'A';
     elsif deal_type = 33300012 AND COUNTERPARTY IN(30600003) AND  TRADER NOT IN(33800018,33800014) AND recorder IN(1,2,3,4,5,6) THEN
       Description := 'A';
     elsif deal_type = 33300012 AND TRADER IN(33800018) AND recorder IN(1,2,3,4,5,6) THEN
       Description := 'B'; 
     elsif deal_type = 33300011 AND TRADER IN(33800014) AND recorder IN(1,2,3,4,5,6) THEN
       Description := 'C'; 
     end if; 
   elsif rectype = 3 then  
    if deal_type = 33300012 AND COUNTERPARTY NOT IN(30600003) AND  TRADER NOT IN(33800018,33800014) AND recorder IN(1,2,3)  THEN
      Description :=  'A';
    elsif deal_type = 33300012 AND COUNTERPARTY IN(30600003) AND  TRADER NOT IN(33800018,33800014) AND recorder IN(2,3) THEN
      Description :=  'B';
    elsif deal_type = 33300012 AND COUNTERPARTY NOT IN(30600003) AND  TRADER NOT IN(33800018,33800014) AND recorder IN(4,5,6) THEN
      Description :=  'C';   
    elsif deal_type = 33300012 AND COUNTERPARTY IN(30600003) AND  TRADER NOT IN(33800018,33800014) AND recorder IN(4,5,6) THEN
      Description :=  'D';       
    elsif deal_type = 33300012 AND TRADER IN(33800018) AND recorder IN(1,2,3) THEN
      Description :=  'E';
    elsif deal_type = 33300012 AND TRADER IN(33800018) AND recorder IN(4,5,6) THEN
      Description :=  'F';
    elsif deal_type = 33300011 AND TRADER IN(33800014) AND recorder IN(1,2,3) THEN
      Description :=  'G'; 
    elsif deal_type = 33300011 AND TRADER IN(33800014) AND recorder IN(4,5,6) THEN
      Description :=  'H';  
    end if;     
  end if;
  return Description;
end fncGetMainDescription;
/