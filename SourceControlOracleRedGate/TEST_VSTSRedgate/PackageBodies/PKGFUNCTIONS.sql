CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGFUNCTIONS" as

function fncsum( num1 number , num2 number) return number
is
begin
        return(num1+num2);
end;

function fncproduct ( argument1 number , argument2  number) return number
is
begin
        return(argument1 * argument2);
end;

function fncdate ( Admissiondate  date) return date
is
begin
        return(Admissiondate);
end;
function fncdynamic( arguments varchar2) return number
is
  vararguments  varchar2(4000);
  varTemp       varchar2(100);
  varoper       varchar2(10);
  numtemp       number;
  numfirst      number;
  numsecond     number;
  vardummy      varchar2(100);
  numi          number;
  varstatus     varchar2(10):='F';
  varcondition  varchar2(100);
begin
 vararguments :=arguments||';';
for numi  in  1.. length(vararguments)
loop
  if substr(vararguments,numi,1) in ('+','-','/','*',';') then

         if varstatus ='F' then
             numfirst:= to_number(varTemp);
             varstatus:='S';
         else
             numsecond := to_number(varTemp);
            case varoper
            when '+' then
              select numfirst + numsecond into numtemp   from dual;
            when '-' then
              select numfirst - numsecond into numtemp   from dual;
            when '*' then
              select numfirst * numsecond into numtemp   from dual;
            when '/' then
              select numfirst / numsecond into numtemp   from dual;
            else
                   vardummy :='';
            end case;
              numfirst:=numtemp;
          end if;
            varoper:= substr(vararguments,numi,1);
            varTemp:='';
   else
      varTemp:=varTemp||substr(vararguments,numi,1);
  end if;
 end loop;
    return (numfirst);
end ;

function fncevaluate(vararguments  varchar2 )
          return varchar2
is
    varoper       varchar2(3000);
    varTemp       varchar2(100);
    vartemp1      varchar2(500);
    vartemp2      varchar2(500);
    numtemp       number;
    numi          number;
    numstart      number;
    numfirst      number;
    numend        number;
    numtemp2      number;
    varresult     varchar2(100);
    numBresult    number;
    varsub        varchar2(500);
    varfinal      varchar2(500);
begin
   varoper := varoper||'Evaluating terms with in bracket';
      for numi  in  1.. length(vararguments)
      loop
        if substr(vararguments,numi,1) in ('(')  then
          numstart := numi;
          numfirst:=1;
        end if;
        if numfirst =1 then
          if substr(vararguments,numi+1,1) not in ('(',')') then
            varsub:=varsub||substr(vararguments,numi+1,1);
          elsif substr(vararguments,numi+1,1) in (')') then
            numend:=numi+1;
            numfirst:=2;
         end if;
        end if ;
       end loop;
          numBresult:= pkgfunctions.FNCDYNAMIC(varsub||';');
        if substr(numBresult,1,1) not in ('-') then
           varresult:='+'||numBresult;
        else
          varresult := numBresult;
        end if;
           vartemp1 :=substr(vararguments,1,numstart-1);
           vartemp2:=substr(vararguments,numend+1,length(vararguments)-numend);
           varfinal:=vartemp1||varresult||vartemp2;
          if (substr(varfinal,numstart-1,1) in ('+') and substr(varfinal,numstart,1) in ('-'))
              or (substr(varfinal,numstart,1) in ('+') and substr(varfinal,numstart-1,1) in ('-'))then

              vartemp1 :=substr(varfinal,1,numstart-2);
              vartemp2:=substr(varfinal,numstart+1,length(varfinal)-(numstart-1));
              varfinal:=vartemp1||'-'||vartemp2;

           elsif (substr(varfinal,numstart-1,1) in ('+') and substr(varfinal,numstart,1) in ('+'))
                or (substr(varfinal,numstart,1) in ('-') and substr(varfinal,numstart-1,1) in ('-'))then

               vartemp1 :=substr(varfinal,1,numstart-2);
               vartemp2:=substr(varfinal,numstart+1,length(varfinal)-(numstart-1));
               varfinal:=vartemp1||'+'||vartemp2;

           end if ;
        return(varfinal);
      end ;

function fncbracecheck(arguments varchar2)
          return number
is
 numflag  number :=0;
 vartemp  varchar2(3000);
 vardummy  varchar2(3000);
 numloop  number;
 varaguments  varchar2(3000);
 numresult    number;
begin
  vartemp:=arguments;
 for numloop in 1..length(vartemp)
 loop
  if substr(vartemp,numloop,1) in ('(')  then
    numflag:=1;
    exit;
  else
    numflag:=0;
  end if;
 end loop;
   if numflag=1 then
        varaguments:= pkgfunctions.fncevaluate(vartemp);
        numresult := pkgfunctions.fncbracecheck(varaguments);
         vartemp:='';

   else
      numresult := pkgfunctions.fncdynamic(vartemp);
    end if;
   return (numresult);
end ;
function fncApplyRates(
         mtmrate in number,
         scenariorate in number,
         datWorkdate in date)
        RETURN number
 is
    PRAGMA AUTONOMOUS_TRANSACTION;
    numerror    number:=0;
begin
    update trsystem997
         set posn_m2m_inrrate =0.00,posn_usd_rate=0.00;
      commit;
  if  scenariorate = 0 then
      update trsystem997
         set posn_m2m_inrrate = pkgforexprocess.fncgetrate(posn_currency_code,30400003, datWorkdate,
                                         0, posn_maturity_month, posn_due_date, mtmrate),
          posn_usd_rate = pkgforexprocess.fncGetRate(30400004, 30400003, datWorkdate, 0, posn_maturity_month, posn_due_date,mtmrate);
      commit;
  else
      update trsystem997
          set posn_m2m_inrrate = (((posn_fcy_rate/100) * scenariorate) + posn_fcy_rate),
          posn_usd_rate = pkgforexprocess.fncGetRate(30400004, 30400003, datWorkdate, 0, posn_maturity_month, posn_due_date);
          commit;
  end if;

     update trsystem997
         set posn_revalue_inr =
             round(posn_transaction_amount * posn_m2m_inrrate,0),
             posn_revalue_usd =
             round((posn_transaction_amount * posn_m2m_inrrate) / posn_usd_rate,2),
            posn_position_inr =
            decode(sign(25900050 - posn_account_code), 1,
            round(posn_transaction_amount * posn_m2m_inrrate,0) - posn_inr_value,
                  -1, posn_inr_value - round(posn_transaction_amount * posn_m2m_inrrate,0));
       commit;
   update trsystem997
       set posn_position_usd = round(posn_position_inr / posn_usd_rate,2);

   commit;
   return numerror;

exception
   when others then
    rollback;
    return numerror;
end fncApplyRates;
---function for Bank Name  -----

function fncGetLocalbankCode
    ( 
    --pickkeyvalue in number,   
      descriptiontype in varchar2) 
      return number is 
--  created on 22/03/2007    
      numerror number;
      vardescription varchar2(50);
      varoperation gconst.gvaroperation%type;
      varmessage gconst.gvarmessage%type;
      varerror gconst.gvarerror%type;
      begin
        varmessage := 'getting pickup description for: ' || descriptiontype;
        varoperation := 'extracting description';
        
        begin
          select pick_key_value
            into vardescription
            from pickupmaster
            where PICK_SHORT_DESCRIPTION = descriptiontype
            and pick_key_group=306
            and pick_record_status not in(gconst.statusinactive,   gconst.statusdeleted);
         exception
          when no_data_found then
            vardescription := 30699999;
        end;
      
       return vardescription;
      
      exception
      when others then
        numerror := sqlcode;
        varerror := sqlerrm;
        varerror := gconst.fncreturnerror('getdesc',   numerror,   varmessage,   varoperation,   varerror);
        raise_application_error(-20101,   varerror);
        return vardescription;
      
end fncGetLocalbankCode;


--function to get payment description from 1st date to scheduled date
function fncgetpayment
(uploaddt date, contractno varchar2)
return number is
pragma autonomous_transaction;

paidamt number;
numerror number;
varoperation gconst.gvaroperation%type;
varmessage gconst.gvarmessage%type;
varerror gconst.gvarerror%type;
frmdt date;
mon varchar2(50);
yr varchar2(50);
       begin
          varmessage := 'getting Paid Amount for: ' || contractno;
          varoperation := 'extracting amount';
          begin
          mon := to_char(uploaddt,'mon');
          yr := to_char(uploaddt,'yyyy');
          frmdt := to_date('01'||'-'||mon||'-'||yr,'dd-mon-yyyy');
                   
        select nvl(sum(BREL_REVERSAL_FCY),0) into paidamt from trtran003 
        where brel_user_reference in (select trad_contract_no from trtran002 where trad_record_status = 10200005 and brel_user_reference=contractno) 
        and brel_entry_date between frmdt and uploaddt and brel_user_reference = contractno and brel_record_status not in (10200005,10200006);
         exception
          when no_data_found then
            paidamt := 0;
        end;

    return paidamt;
      exception
      when others then
        numerror := sqlcode;
        varerror := sqlerrm;
        varerror := gconst.fncreturnerror('amount',   numerror,   varmessage,   varoperation,   varerror);
        raise_application_error(-20101,   varerror);
        return paidamt;
end fncgetpayment;


end PKGFUNCTIONS ;
/