CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGIRS" 
as
function fncIRSGetInterestRate(
        VarReference in varchar2,
        intSerialNumber in number,
        datStartDate in date,
        datEndDate in Date,
        intIntType in number,
        datAson    in Date,
        frwdMonth in number :=0)
        return number 
  as  
   numIntRate number(15,6);
   numAintRate number(15,6);
   numBaseRate number(15,6);
   numSpreadRate number(15,6);
   numRateType NUMBER(8);
   currencyCode Number(8);   
   numError number(15);
   varOperation        GConst.gvarOperation%Type;
   varMessage          GConst.gvarMessage%Type;
   varError            GConst.gvarError%Type;
  begin 
--  80300001	Fixed
--80300002	Floating
   select iirl_base_rate,iirl_spread,iirl_final_rate,IIRL_RATE_TYPE,IIRL_CURRENCY_CODE
     into numBaseRate,numSpreadRate,numAintRate,numRateType,currencyCode
     from trtran091a 
    where iirl_irs_number= varreference
    and iirl_serial_number= intserialnumber;
    

     if  intIntType = 80300002 then 
          select  avg(irat_settlement_price)
            into numIntRate
            from trtran094
           where irat_settlement_date between datStartDate and datEndDate
           and irat_effective_date = to_date(datAson,'DD-MM-YY')
           and irat_interest_type = numRateType
           AND irat_forward_month  != 0
           and  irat_currency_code = currencyCode;
           --numIntRate:= numIntRate + (numSpreadRate /100);
            --numIntRate:= nvl(numIntRate,0) + (numSpreadRate);
            numIntRate:= nvl(numIntRate,0);
      elsif intIntType = 80300001 then 
          numIntRate := numAintRate;
      end if;

       IF frwdMonth = 0 THEN
        SELECT avg(IRAT_SETTLEMENT_PRICE) INTO numIntRate
        FROM TRTRAN094
        WHERE irat_currency_code = currencyCode --For Libor Spot(Cannot get EURO currency 3 month Libor)
        and irat_forward_month   = 0
        AND irat_effective_date  = to_date(datAson,'DD-MM-YY')
        AND irat_interest_type = numRateType;
       END IF;
--       numIntRate := numIntRate/100;
       numIntRate := numIntRate;
    return numIntRate;   
   EXCEPTION
   WHEN others THEN
         numError := SQLCODE;
      varError := SQLERRM;
        varError := GConst.fncReturnError('fncIRSGetInterestRate', numError, varMessage,
                  varOperation, varError);
    raise_application_error(-20801,varError);
  end fncIRSGetInterestRate;


function fncGetInterestRate(
        datStartDate in date,
        datAson    in Date,
        RateType in number,
        currencyCode Number)
        return number 
  as  
   datIntAvaiable date;
   frwdMonth NUMBER(5);
   frwdAvaMonth number(5);
   numIntRate number(15,6);
   numError number(15);
   numSpotRate number(15,6);
   numForwardRate number(15,6);
   varOperation        GConst.gvarOperation%Type;
   varMessage          GConst.gvarMessage%Type;
   varError            GConst.gvarError%Type;
  begin 

       frwdMonth:= round(MONTHS_BETWEEN(datStartDate,datAson),0);
     if frwdMonth <0 then 
        frwdMonth:=0;
     End if;   
           varOperation := 'Getting Max Date for Currency ' || currencyCode || 
                     'Date' || datAson || 'Month' || frwdMonth || 'Rate' ||RateType;
     BEGIN 
        SELECT DISTINCT irat_effective_date
        INTO datIntAvaiable
        FROM TRTRAN094
        WHERE irat_currency_code = currencyCode --For Libor Spot(Cannot get EURO currency 3 month Libor)
        and IRAT_INTEREST_TYPE =RateType
        and irat_forward_month   = 0
        AND irat_effective_date  = to_date(datAson,'DD-MM-YY');
     exception 
       when no_data_found then 
         frwdMonth:=0;
          SELECT DISTINCT max(irat_effective_date) 
          INTO datIntAvaiable
          FROM TRTRAN094
          WHERE irat_currency_code = currencyCode --For Libor Spot(Cannot get EURO currency 3 month Libor)
          and IRAT_INTEREST_TYPE =RateType
          and irat_forward_month   = 0
          AND irat_effective_date  <= to_date(datAson,'DD-MM-YY');
       end ;
      

           varOperation := 'Spot Rate' || currencyCode || 
                     'Date ' || datIntAvaiable || 'Month ' || frwdMonth || 'Rate ' ||RateType;
     
        SELECT IRAT_SETTLEMENT_PRICE
          INTO numSpotRate
        FROM TRTRAN094
        WHERE irat_currency_code = currencyCode --For Libor Spot(Cannot get EURO currency 3 month Libor)
        and irat_forward_month   = 0
        and IRAT_INTEREST_TYPE =RateType
        and IRAT_SERIAL_NUMBER = (select max(IRAT_SERIAL_NUMBER) from TRTRAN094
                                    WHERE irat_currency_code = currencyCode --For Libor Spot(Cannot get EURO currency 3 month Libor)
                                    and irat_forward_month   = 0
                                    and IRAT_INTEREST_TYPE =RateType
                                    AND irat_effective_date  = datIntAvaiable)
        AND irat_effective_date  = datIntAvaiable;
       
       varOperation := 'Getting Forward Rate ' || currencyCode || 
                     'Date' || datIntAvaiable || 'Month' || frwdMonth || 'Rate' ||RateType;
      if frwdMonth !=0 then 
        -- begin     
        
        select max(irat_forward_month)
        into frwdAvaMonth
        from trtran094
        where irat_effective_date = datIntAvaiable
          and irat_forward_month <=frwdMonth
           and IRAT_INTEREST_TYPE =RateType
          and irat_currency_code = currencyCode;
        
          select  irat_settlement_price
            into numForwardRate
            from trtran094
           where  irat_effective_date = datIntAvaiable
           and IRAT_INTEREST_TYPE =RateType
           AND irat_forward_month  = frwdAvaMonth
          and IRAT_SERIAL_NUMBER= (select max(IRAT_SERIAL_NUMBER) from TRTRAN094
                                    WHERE irat_currency_code = currencyCode --For Libor Spot(Cannot get EURO currency 3 month Libor)
                                    and irat_forward_month = frwdAvaMonth
                                    and IRAT_INTEREST_TYPE =RateType
                                    AND irat_effective_date  = datIntAvaiable)
           and  irat_currency_code = currencyCode;
       -- exception
      else 
          numForwardRate :=0;
      end if;
       numIntRate := numSpotRate + numForwardRate;
     --  numIntRate := numIntRate;
    return numIntRate;   
   EXCEPTION
   WHEN others THEN
         numError := SQLCODE;
      varError := SQLERRM;
        varError := GConst.fncReturnError('fncGetInterestRate', numError, varMessage,
                  varOperation, varError);
    raise_application_error(-20801,varError);
  end fncGetInterestRate;
  
  
function fncIRSIntCalcforperiod(
      datintStartDate in Date,
      datintendDate in Date,
      varReference in varchar,
      SerialNumber in number,
      numIntRate in number,
      numIntDaysType in number)
      return  number
  as 
   numTemp number(15);
   numInterest number(15,6);
   numDealType number(8);
   numPrincipalAmount number(15,2);
   numError number(15);
   datTemp date;
   
   varOperation        GConst.gvarOperation%Type;
   varMessage          GConst.gvarMessage%Type;
   varError            GConst.gvarError%Type;
  begin 
    --  80800001	AMIRS
    --  80800002	ACIRS
    --  80800003	IRS
    varOperation:= 'Getting Data ';
    
    select iirs_deal_type 
      into numDealType
     from trtran091
    where iirs_irs_number=varReference
    and iirs_record_status not in (10200005,10200006);
    
    if ((numDealType= 80800001) or (numDealType= 80800002)) then--  	80800001	AMIRS 80800002	ACIRS
       
       -- this is to select the outstanding amount with incase if that is exist with the range of startdate and endate
      begin 
        select min(iirn_Effective_Date) 
          into datTemp
         from trtran091c
        where iirn_irs_number= varReference
        and iirn_effective_date < datintStartDate;
      exception 
       when others then
         datTemp := null;
      end ;
      
       if datTemp is null then 
           select iirs_notional_amount
             into numPrincipalAmount
             from trtran091
             where iirs_irs_number=varReference
               and iirs_record_status not in (10200005,10200006);
       else
        begin
            select iirn_outstanding_amount
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date =  (select max(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date <= datintStartDate);
                                          --and iirn_effective_date <= datintendDate );
        exception 
         when no_data_found then
         --  if  numPrincipalAmount = null then
           -- this is to select the outstanding amount with incase if it does not exist with the range of startdate and endate
             select iirn_outstanding_amount
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date = (select max(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date <= datintStartDate);
          -- end if;
        end;
      end if;   
    elsif (numdealtype =80800004) then --CCIRS
           -- this is to select the outstanding amount with incase if that is exist with the range of startdate and endate
           
      begin
       VarOperation := 'Pick the Min Date';
       
        select MAX(iirn_Effective_Date) 
          into datTemp
         from trtran091c
        where iirn_irs_number= varReference
        and iirn_effective_date < datintStartdate ;
      exception 
       when others then
         datTemp := null;
      end ;
       VarOperation := 'Check the Date is null' ||datTemp;
       
       if datTemp is null then 
           select iirL_notional_amount 
             into numPrincipalAmount
             from trtran091A
             where iirl_irs_number=varReference
             and iirl_serial_number= SerialNumber
             and iirl_record_status not in (10200005,10200006);
       else
       
         VarOperation := 'Check with the ' ||datintStartDate || ' and ' || datintendDate ;
         
--         begin 
--            select decode(serialnumber,1,IIRn_OUTSTANDING_amount,IIRN_OUTSTANDING_payment) -- serial number 1 for the receive amount 1 for the payment 
--              into numPrincipalAmount
--             from trtran091c 
--             where iirn_irs_number= varReference
--             and iirn_Effective_Date =  (select MIN(iirn_Effective_Date) from trtran091c
--                                          where iirn_irs_number= varReference
--                                          and iirn_effective_date > datintStartDate
--                                          and iirn_effective_date < datintendDate );
--        exception
--        when no_data_found then                                 
         --  if  numPrincipalAmount = null then
           -- this is to select the outstanding amount with incase if it does not exist with the range of startdate and endate
             select decode(serialnumber,1,IIRn_OUTSTANDING_amount,IIRN_OUTSTANDING_payment) -- serial number 1 for the receive amount 1 for the payment 
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date = (select max(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date <= datintStartDate);
        -- end;
      end if;  
    elsif (numDealType= 80800003) then --Plain IRS
           select iirs_notional_amount
              into numPrincipalAmount
             from trtran091
            where iirs_irs_number=varReference
            and iirs_record_status not in (10200005,10200006);
    end if;
 
      select fncIRSIntCalcualtion(datintStartDate,datintEndDate,numPrincipalAmount,numIntRate,numIntDaysType) 
        into numInterest
      from dual;
      
    return numInterest;
  EXCEPTION
   WHEN others THEN
      numError := SQLCODE;
      varError := SQLERRM;
        varError := GConst.fncReturnError('fncIRSIntCalcforperiod', numError, varMessage,
                  varOperation, varError);
    raise_application_error(-20801,varError);
end fncIRSIntCalcforperiod;

function fncIRSIntCalcualtion (
         datintStartDate in date,
         datintendDate in Date, 
         numPrincipalAmount in number,
         numIntRate in  number,
         numIntChargeType in number)
         return number
as
   numTemp number(15);
   numInterest number(15,6);
      numError number(15);
   varOperation        GConst.gvarOperation%Type;
   varMessage          GConst.gvarMessage%Type;
   varError            GConst.gvarError%Type;
   numIntRateC    number(15,10);
begin 

-- 41200004	30/360
--41200005	ACT/360
--41200006	ACT/365
--41200007	ACT/366
numIntRateC:= numintRate/100;

         if numIntChargeType = 41200004 then --30/360
            numTemp:= days360(datintStartDate,datintendDate);
            numInterest := numPrincipalAmount*numIntRateC*30/360;
         elsif numIntChargeType = 41200005 then --ACT/360
            numTemp:= datintendDate-datintStartDate;
            numInterest := numPrincipalAmount*numIntRateC*numTemp/360;
         elsif numIntChargeType = 41200006 then --ACT/365
            numTemp:=  datintendDate-datintStartDate;
            numInterest := numPrincipalAmount*numIntRateC * numTemp/365;
         elsif numIntChargeType = 41200007 then --ACT/366
            numTemp:=  datintendDate-datintStartDate;
            numInterest := numPrincipalAmount*numIntRateC * numTemp/366;
         else
           numInterest :=0;
        end if;
  return numInterest;
     EXCEPTION
   WHEN others THEN
         numError := SQLCODE;
      varError := SQLERRM;
        varError := GConst.fncReturnError('fncIRSGetInterestRate', numError, varMessage,
                  varOperation, varError);
    raise_application_error(-20801,varError);
 end fncIRSIntCalcualtion;

function days360(
       p_start_date           date,
       p_end_date             date,
       p_rule_type            char default 'F'
       )
    RETURN number
IS
  v_mm1    pls_integer;
  v_dd1    pls_integer;
  v_yyyy1  pls_integer;
  v_mm2    pls_integer;
  v_dd2    pls_integer;
  v_yyyy2  pls_integer;
BEGIN
  v_yyyy1 := to_number(to_char(p_start_date,'yyyy'));
  v_mm1   := to_number(to_char(p_start_date,'mm'));
  v_dd1   := to_number(to_char(p_start_date,'dd'));
  v_yyyy2 := to_number(to_char(p_end_date,'yyyy'));
  v_mm2   := to_number(to_char(p_end_date,'mm'));
  v_dd2   := to_number(to_char(p_end_date,'dd'));
  IF p_rule_type = 'F' THEN
     IF v_dd1 = 31 THEN v_dd1 := 30; END IF;
     IF v_mm1 = 2  AND v_dd1 = to_number(to_char(last_day(p_start_date),'dd'))
          THEN v_dd1 := 30; END IF;
     IF v_dd2 = 31
          THEN IF v_dd1 < 30
                    THEN v_dd2 := 1;
                         v_mm2 := v_mm2 + 1;
                         IF v_mm2 = 13 THEN v_mm2 := 1;
                                            v_yyyy2 := v_yyyy2 +1;
                         END IF;
                    ELSE v_dd2 := 30;
               END IF;
     END IF;
     IF v_mm2 = 2  AND v_dd2 = to_number(to_char(last_day(p_end_date),'dd'))
          THEN v_dd2 := 30;
               IF  (v_dd1 < 30)
                   THEN v_dd2 := 1;
                        v_mm2 := 3;
               END IF;
     END IF;
     IF v_mm2 IN (4, 6, 9, 11) AND v_dd2 = 30
          AND v_dd1 < 30
          THEN v_dd2 := 1;
               v_mm2 := v_mm2 + 1;
     END IF;
  ELSIF p_rule_type = 'T' THEN
     IF v_dd1 = 31 THEN v_dd1 := 30; END IF;
     IF v_dd1 = 31 THEN v_dd1 := 30; END IF;
     IF v_mm1 = 2  AND v_dd1 = to_number(to_char(last_day(p_start_date),'dd'))
          THEN v_dd1 := 30; END IF;
     IF v_dd2 = 31 THEN v_dd2 := 30; END IF;
     IF v_mm2 = 2  AND v_dd2 = to_number(to_char(last_day(p_end_date),'dd'))
          THEN v_dd2 := 30; END IF;
  ELSE RAISE_APPLICATION_ERROR('-20002','3VL Not Allowed Here');
  END IF;
  RETURN (v_yyyy2 - v_yyyy1) * 360
       + (v_mm2 - v_mm1) * 30
       + (v_dd2 - v_dd1);
END; 

function fncIRSOutstanding(
      datintStartDate in Date,
      datintendDate in Date,
      varReference in varchar,
      SerialNumber in number)
      return  number
as
   numTemp number(15);
   numInterest number(15,6);
   numDealType number(8);
   numPrincipalAmount number(15,2);
   numError number(15);
   datTemp date;
   
   varOperation        GConst.gvarOperation%Type;
   varMessage          GConst.gvarMessage%Type;
   varError            GConst.gvarError%Type;
  begin 
    --  80800001	AMIRS
    --  80800002	ACIRS
    --  80800003	IRS
    
    select iirs_deal_type 
      into numDealType
     from trtran091
    where iirs_irs_number=varReference
    and iirs_record_status not in (10200005,10200006);
    
    if ((numDealType= 80800001) or (numDealType= 80800002)) then--  	80800001	AMIRS 80800002	ACIRS
       
       -- this is to select the outstanding amount with incase if that is exist with the range of startdate and endate
      begin 
        select min(iirn_Effective_Date) 
          into datTemp
         from trtran091c
        where iirn_irs_number= varReference
        and iirn_effective_date < datintStartDate;
      exception 
       when others then
         datTemp := null;
      end ;
      
       if datTemp is null then 
           select iirs_notional_amount
             into numPrincipalAmount
             from trtran091
             where iirs_irs_number=varReference
               and iirs_record_status not in (10200005,10200006);
       else
        begin
            select iirn_outstanding_amount
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date =  (select max(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date < = datintStartDate);
        exception 
         when no_data_found then
         --  if  numPrincipalAmount = null then
           -- this is to select the outstanding amount with incase if it does not exist with the range of startdate and endate
             select iirn_outstanding_amount
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date = (select max(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date <= datintStartDate);
          -- end if;
        end;
      end if;   
    elsif (numdealtype =80800004) then --CCIRS
           -- this is to select the outstanding amount with incase if that is exist with the range of startdate and endate
           
      begin
       VarOperation := 'Pick the Min Date';
       
        select min(iirn_Effective_Date) 
          into datTemp
         from trtran091c
        where iirn_irs_number= varReference
        and iirn_effective_date <= datintendDate;
      exception 
       when others then
         datTemp := null;
      end ;
       VarOperation := 'Check the Date is null' ||datTemp;
       
       if datTemp is null then 
           select iirL_notional_amount 
             into numPrincipalAmount
             from trtran091A
             where iirl_irs_number=varReference
             and iirl_serial_number= SerialNumber
             and iirl_record_status not in (10200005,10200006);
       else
       
         VarOperation := 'Check with the ' ||datintStartDate || ' and ' || datintendDate ;
         
         begin 
            select decode(serialnumber,1,IIRn_OUTSTANDING_amount,IIRN_OUTSTANDING_payment) -- serial number 1 for the receive amount 1 for the payment 
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date =  (select min(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date >= datintStartDate
                                          and iirn_effective_date <= datintendDate );
        exception
        when no_data_found then                                 
         --  if  numPrincipalAmount = null then
           -- this is to select the outstanding amount with incase if it does not exist with the range of startdate and endate
             select decode(serialnumber,1,IIRn_OUTSTANDING_amount,IIRN_OUTSTANDING_payment) -- serial number 1 for the receive amount 1 for the payment 
              into numPrincipalAmount
             from trtran091c 
             where iirn_irs_number= varReference
             and iirn_Effective_Date = (select max(iirn_Effective_Date) from trtran091c
                                          where iirn_irs_number= varReference
                                          and iirn_effective_date < datintStartDate);
         end;
      end if;  
    elsif (numDealType= 80800003) then --Plain IRS
           select iirs_notional_amount
              into numPrincipalAmount
             from trtran091
            where iirs_irs_number=varReference
            and iirs_record_status not in (10200005,10200006);
    end if;
 
      
    return numPrincipalAmount;
  EXCEPTION
   WHEN others THEN
      numError := SQLCODE;
      varError := SQLERRM;
        varError := GConst.fncReturnError('fncIRSIntCalcforperiod', numError, varMessage,
                  varOperation, varError);
    raise_application_error(-20801,varError);
end fncIRSOutstanding;
end PKGIRS;
/