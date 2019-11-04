CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".IS_Valid_PICKUP_TEXT
  ( PickText in varchar2,KeyGroup in number ) 
    return number 
    as
    numTemp     number(15);
    numError    number;
begin
    numTemp:=0;
  begin
    select PICK_KEY_VALUE
      into numTemp
     from trmaster001
      where PICK_RECORD_STATUS not in (10200005,10200006)
      and pick_key_group= KeyGroup
      and ((trim(pick_long_description) =PickText)
          or (trim(pick_short_description) =PickText));
   exception
     when no_data_found then 
        numTemp:=0;
   end; 
   return numTemp;
Exception
  When others then
    return 0;
end IS_Valid_PICKUP_TEXT;
/