CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCSPOTDATE" 
    ( AsonDate in Date,
      NoofDays in Number,
      LocationCode in Number)
  return date as 
  varMessage    varchar2(100);
  varOperation  varchar2(100);
  varError	    varchar2(2048);
	datToday	    date;
	datMature	    date;
	datTemp		    date;
  numError      number;
	numHoliday	  number(8);
	numDays		    number(5);
	numFlag		    number(1);
begin
	numDays := NoofDays;
	numFlag := 0;
	datToday := AsonDate;
  datMature := null;

  varMessage := 'Calculating Spot Date for ' || AsonDate;
	datTemp := datToday + numDays;

  varOperation := 'Calculating spot date';
	while numflag = 0
	Loop

    Begin
      select hday_day_status into
        numHoliday
        from trsystem001
        where hday_location_code = LocationCode
        and hday_calendar_date = datTemp;
    Exception
      when no_data_found then
        if  to_char(datTemp, 'D') = '1' then
          numHoliday := 26400009;
        elsif to_char(datTemp, 'D') = '7' then          
          numHoliday := 26400008;
        else numHoliday := 0;  
        End if;
    End;
    
		if numHoliday in (26400007,26400008,26400009) then

			if numDays > 0 then
				datTemp := datTemp + 1;
			else
				datTemp := datTemp - 1;
			end if;

		else
			numFlag := 1;
			datMature := datTemp;
		End if;
	

	end Loop;

	return datMature;
  
Exception
	when others then
		varError := SQLERRM;
    varError := varError || ' Loc: ' || LocationCode || ' for: ' || datTemp;
    numError := SQLCODE;
     varError := GConst.fncReturnError('SpotDate', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);                      
      return datMature;
End fncSpotDate;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/