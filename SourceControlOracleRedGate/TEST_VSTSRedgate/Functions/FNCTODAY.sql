CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCTODAY" 
  return date as 

  varMessage    varchar2(100);
  varOperation  varchar2(100);
  varError	    varchar2(2048);
	datToday	    date;
	numError      number;
begin
  datToday := Sysdate;
  varMessage := 'Getting the Latest Date opened ';
 	varOperation := 'Getting the Latest Date opened ';
 	Begin
		select max(hday_calendar_date)
			into datToday
			from trsystem001
			where hday_location_code = 30299999
			and hday_day_status = 26400002;
      
  Exception
    when no_data_found then
      datToday := sysdate;
  End;

	return datToday;
  
Exception
	when others then
		varError := SQLERRM;
 		numError := SQLCODE;
    varError := GConst.fncReturnError('Today', numError, varMessage, 
                      varOperation, varError);
    raise_application_error(-20101, varError);                      
    return datToday;
End fncToday;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/