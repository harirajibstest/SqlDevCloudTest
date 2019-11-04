CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCASONDATE" 
  return date as 

  varMessage    varchar2(100);
  varOperation  varchar2(100);
  varError	    varchar2(2048);
	datAson	    date;
   datTemp      date;
	numError      number;
begin
  
  
--  select nvl(hday_calendar_date,Sysdate) into datTemp 
--    from trsystem001
--   where hday_day_status =26400002;
  datTemp := Sysdate;  
 -- if  
  varMessage := 'Getting the Latest Date opened ';
  varOperation := 'Getting the Latest Date opened ';
  
Begin
--  select FromDate
--    into datAson
--    from trsystem979
--    where rownum = 1;
 -- just for the reference execute dbms_application_info.set_client_info('25-jul-2012');     
  --datAson := TO_DATE (USERENV ('client_info'), 'dd-mon-yyyy');    
  select asondate into datAson 
    from trsystem978;
    
  Exception
    when no_data_found then

      datAson := datTemp;
  End;

	 return nvl(datAson,datTemp);

  
Exception
	when others then
		varError := SQLERRM;
 		numError := SQLCODE;
    varError := GConst.fncReturnError('Ason', numError, varMessage, 
                      varOperation, varError);
    raise_application_error(-20101, varError);                      
    return datAson;
End fncAsonDate;
 
 
 
 
/