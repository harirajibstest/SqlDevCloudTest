CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."REFGRAPHS" (ratetype in number,varuserid in varchar,datworkdate in date,currency in number ) RETURN number AS
	numError number(5);
	numTemp	 number;
	numTemp1 number;
	numTemp2 number;
	numRate number(15,6);
	varTemp varchar2(50);
	--varUserId varchar2(256);
	varError varchar2(2048);
	varQuery varchar2(4000);
	type type_user is table of varchar2(50);
	typUser type_user;
        Summation  GConst.DataCursor;

	cursor dealRate (DealerName varchar2)
	is
	select deal_exchange_rate
		from trtran001
		where deal_user_id = DealerName
                and deal_execute_date=datworkdate
                and deal_base_currency=currency;

begin

	--varUserID := 'Manju123,Dealer123,Nataraj123';
	numTemp := 1;	
	numTemp1 := 0;
	numTemp2 := 1;
	typUser := type_user();

	varQuery := 'Create global temporary table trtemp(';

	while numTemp > 0 	
	Loop
		numTemp1 := numTemp1 + 1;
		numTemp := instr(varUserID, ',', 1, numTemp1);
		

		if numTemp = 0 then
			varTemp := substr(varUserId, numTemp2);
		else
			varTemp := substr(varUserId, numTemp2, numTemp - numTemp2);
			
		end if;

		varQuery := varQuery || varTemp || ' number(15,6),';
		typUser.Extend(1);
		typUser(numTemp1) := varTemp;
		numTemp2 := numTemp + 1;		
		
	End Loop;	
	
	
	varQuery := varQuery || ' srlno number(3,0))';
	varQuery := varQuery || ' on commit preserve rows';
	dbms_output.put_line(varQuery);
	execute immediate varQuery;


	for numError in 1..numTemp1
	loop
		numTemp := 0;

		open DealRate(typUser(numError));
		Loop
			fetch DealRate into numRate;
			exit when DealRate%NOTFOUND;

			numTemp := numTemp + 1;
			varQuery := 'select nvl(srlno,0) from trtemp where srlno = ' || numTemp;
			begin
				execute immediate varQuery into numTemp2;
			Exception
				when no_data_found then
				numTemp2 := 0;
			end;

			if numTemp2 > 0 then
				varQuery := 'update trtemp set ' || typUser(numError) || ' = ' || numRate;
				varQuery := varQuery || ' where srlno = ' || numTemp;
			else
				varQuery := 'insert into trtemp (' || typUser(numError) || ',srlno) values(';
				varQuery := varQuery || numRate || ',' || numTemp || ')';
			End if;			
		
			dbms_output.put_line(varQuery);
			execute immediate varQuery;
		End Loop;
		
		Close DealRate;

	End loop;
	commit;
        
	return 0;
Exception
	when others then
		varError := SQLERRM;
		dbms_output.put_line(varError);
                return -1;
END REFGRAPHS;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/