CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGVARCOVAR" AS

procedure COVAR_POPULATE_HEDGERATIO 
as
varOperation Varchar(1000);
begin 

varOperation := 'Delete from Hedge Ratio Table';
delete from trcovar006;

varOperation := 'Insert the sesitivity Details into Hedge Ratio Table';

insert into trcovar006
(VRAT_COMPANY_CODE,VART_LOCATIOn_code,VART_PEODUCT_CODE,
VART_SUBPRODUCT_code,VART_ACCEPTABLE_SENSITIVITY,VART_serial_number)
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,varc_sensitivity_95,2
 from Trcovar004
 union all
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,varc_sensitivity_99,1
 from Trcovar004 
 union all
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,20,3
 from Trcovar004 
 union all
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,10,4
 from Trcovar004 
 union all
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,5,5
 from Trcovar004 
 union all
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,2.5,6
 from Trcovar004 
 union all
 select varc_company_code,varc_location_code,varc_product_code,
   varc_subproduct_code,0,7
 from Trcovar004 ;


varOperation := 'Calculate the Open Exposure';

 update Trcovar006 set VART_OPEN_EXPOSURE99= (select varc_var_99 *(vart_acceptable_sensitivity/
       varc_sensitivity_99)*
      (varc_Portfolio_absamount/varc_var_99) from trcovar004),
       VART_OPEN_EXPOSURE95= (select varc_var_95 *(vart_acceptable_sensitivity/
       varc_sensitivity_95)*
      (varc_Portfolio_absamount/varc_var_95) from trcovar004);
      

varOperation := 'Calculate the Hedge Ratio';

 update Trcovar006 set vart_hedge_ratio95=
  (select ((varc_portfolio_absamount-vart_open_exposure95)/varc_portfolio_absamount)*100
    from Trcovar004),
 vart_hedge_ratio99=(select ((varc_portfolio_absamount-vart_open_exposure99)/varc_portfolio_absamount)*100
    from Trcovar004);
 commit;
end COVAR_POPULATE_HEDGERATIO;
----------------------------------------------------------------------------------------------------------
procedure
 COVAR_Populate_Var_Covar ( datform date,
  datTo date,AdjustEarnings number)
 
 as
  VarOperation varchar(2000);
 begin 
 
   VarOperation:= 'Calcualte var and Covar insert all the currencies';
   
   delete from TRCoVar002 ;
  -- where VARI_CALC_date= datTo;
   
    insert into TRCoVar002 (VARI_CALC_date,VARI_Currency_code1,
        VARI_for_currency1,VARI_Currency_code2,VARI_for_currency2)
      select datTo,A.vpos_Currency_code,a.vPos_for_Currency,
             b.vpos_Currency_code,b.Vpos_For_Currency
      from 
      (select distinct Vpos_Currency_code,Vpos_For_Currency 
       from trcovar005) a  cross join
       (select distinct Vpos_Currency_code,Vpos_For_Currency 
       from trcovar005) b;
   
    VarOperation:= 'Update the Variance';
    
    update TRCoVar002 set VARI_Maturity_month=0,
    VARI_Var_CoVar=  (select variance(rate_spotbid_change)
                              from TRCoVar001
                              where rate_currency_code=VARI_Currency_code1 
                              and rate_for_currency=VARI_for_currency1
                              and rate_calc_date between datform and datTo)
    where VARI_Currency_code1=VARI_Currency_code2
     and VARI_for_currency1=VARI_for_currency2;
     

    VarOperation:= 'Update the Co-Variance1';
    
    update TRCoVar002 set VARI_Maturity_month=0,
    VARI_Var_CoVar= (select Covar_pop(r1.rate_spotbid_change,r2.rate_spotBid_change)
                              from TRCoVar001 r1 inner join TRCoVar001 r2
                              on r1.rate_calc_date=R2.rate_calc_date
                              where R1.rate_calc_date between datform and datTo
                              and R1.rate_currency_code=VARI_Currency_code1 
                              and R1.rate_for_currency=VARI_for_currency1
                              and R2.rate_currency_code=VARI_Currency_code2
                              and R2.rate_for_currency=VARI_for_currency2)
     where vari_var_covar is null;    
     
       VarOperation:= 'Populate Positions';
  DELETE FROM trcovar003;
     insert into trcovar003 (COPO_CALC_date ,copo_Company_code ,
          Copo_location_code ,Copo_Product_code ,copo_SubProduct_code ,
          Copo_currency_code,Copo_forcurrency_code , copo_maturity_month,
          copo_exposure_type ,copo_transaction_amount)
          
          select sysdate,Vpos_company_code,vpos_location_code,
          Vpos_product_code,Vpos_subproduct_code,Vpos_currency_code,Vpos_for_currency,0,
          1,Vpos_transaction_amount
          from trcovar005;

       VarOperation:= 'Populate Weights';
update trcovar003 m set copo_cal_weight = abs(copo_transaction_amount)/ 
    (select sum(abs(copo_transaction_amount))
      from trcovar003 s);
      
--      where m.COPO_CALC_date=s.COPO_CALC_date
--       and m.copo_Company_code= s.copo_Company_code
--       and m.Copo_location_code =s.Copo_location_code
--       and m.Copo_Product_code = s.Copo_Product_code
--       and m.copo_SubProduct_code=s.copo_SubProduct_code
--       and m.copo_maturity_month =s.copo_maturity_month
--       and m.copo_exposure_type =s.copo_exposure_type);

       VarOperation:= 'Matrix mutiplier';
       
update trcovar003 set COPO_matrix_multipler=
  (select Multipler from 
   (select vari_currency_code2,vari_for_currency2, sum(copo_cal_weight*vari_var_covar) Multipler
    from trcovar002 inner join trcovar003
    on vari_currency_code1= Copo_currency_code
    and vari_for_currency1=Copo_forcurrency_code
    group by vari_currency_code2,vari_for_currency2) mul
    where vari_currency_code2= Copo_currency_code
    and vari_for_currency2= Copo_forcurrency_code);

delete from trcovar004;

       VarOperation:= 'Calculate Consolidate positions';
       
insert into trcovar004 (VARC_CALC_date,VARC_Company_code,
VARC_location_code,VARC_Product_code,VARC_SubProduct_code,
VARC_exposure_type,
 VARC_Portfolio_amount,VARC_Portfolio_ABSamount)
 select sysdate,copo_company_code,30299999,33399999,33899999,1,
-- copo_location_code,copo_product_code,copo_subproduct_code,
-- copo_exposure_type,
 sum(copo_transaction_amount),sum(abs(copo_transaction_amount))
 from trcovar003
 group by copo_company_code;
 --,copo_location_code,copo_product_code,copo_subproduct_code,
 --copo_exposure_type;
 
        VarOperation:= 'Calculate portfolio Variance';

 update trcovar004 set VARC_Portfolio_variance=
   (select  sum(copo_cal_weight*copo_matrix_multipler) Multipler
    from trcovar003);
--      where copo_Company_code=VARC_Company_code
--        and Copo_location_code= VARC_location_code
--        and Copo_Product_code=VARC_Product_code
--        and copo_SubProduct_code=VARC_SubProduct_code
--    group by copo_Company_code ,Copo_location_code ,Copo_Product_code ,copo_SubProduct_code);
 
 commit;
 
       VarOperation:= 'Calculate portfolio Volatility';
  update trcovar004 set VARC_Portfolio_volatility = sqrt(abs(VARC_Portfolio_variance));
  -- 1.644853627 is the NORMSINV(0.95)
  --2.326347874 is the NORMSINV(0.99)

       VarOperation:= 'Calculate portfolio Var 95';
  update trcovar004 set VARC_Var_95 = VARC_Portfolio_volatility* sqrt(252)*1.644853627* VARC_Portfolio_ABSamount,
      VARC_Var_99= VARC_Portfolio_volatility* sqrt(252)*2.326347874* VARC_Portfolio_ABSamount;
  
        VarOperation:= 'Update the Adjust Earnings'; 
 update trcovar004 set VARC_adjust_earnings =AdjustEarnings;
  
          VarOperation:= 'Update the Sensitivity'; 
          
 update trcovar004 set VARC_sensitivity_95 =(VARC_Var_95/VARC_adjust_earnings)*100,
      VARC_sensitivity_99= (VARC_Var_99/VARC_adjust_earnings)*100;
      
    VarOperation:= 'Update the Var Delta '; 
update  trcovar003 set copo_var_delta = copo_matrix_multipler/
    (select VARC_Portfolio_volatility from trcovar004);
    
--      where copo_Company_code=VARC_Company_code
--        and Copo_location_code= VARC_location_code
--        and Copo_Product_code=VARC_Product_code
--        and copo_SubProduct_code=VARC_SubProduct_code);
  
    -- 1.644853627 is the NORMSINV(0.95)
  --2.326347874 is the NORMSINV(0.99)
   VarOperation:= 'Update the Var Component VaR '; 
 update trcovar003 set copo_component_var95 = copo_var_delta* copo_transaction_amount*SQRT(252)*1.644853627,
    copo_component_var99 = copo_var_delta* copo_transaction_amount*SQRT(252)*2.326347874;
    
     
  commit;
 end COVAR_Populate_Var_Covar;
--------------------------------------------------------------------------------------------------------------------
procedure CoVar_populateRates ( DatFromDate date,datToDate date)
as
datRatesAva date;
DatRatesNextAva date;
VarOperation varchar(2000);
datTemp1 date;
begin 
  
    VarOperation := 'Get the latest date rates avaliable from Spcefied from date';
    select min(drat_effective_Date)
       into datRatesAva
     from trtran012 
     where drat_effective_date > =DatFromDate
      and drat_record_status not in (10200005,10200006);
      
    VarOperation := 'Get the next date rates avaliable from Latest rates Avaliable date';

    select min(drat_effective_Date)
       into DatRatesNextAva
     from trtran012 
     where drat_effective_date >datRatesAva
      and drat_record_status not in (10200005,10200006);
      
  dbms_output.put_line('Before Loop');
  
    while ( DatRatesNextAva <= dattodate)
    loop 
    
    delete from TRCoVar001 where rate_calc_date=DatRatesNextAva;
    
    dbms_output.put_line('inside the loop' || to_char(DatRatesNextAva) );

  
        insert into TRCoVar001 (RATE_CALC_date,Rate_Currency_code,Rate_for_currency,
           Rate_Maturity_month,Rate_SpotBid_change,Rate_SpotASK_change)
      select DatRatesNextAva,prev.drat_currency_code,prev.drat_for_currency,0,
      LN(Today.drat_spot_bid/Prev.drat_spot_bid),
       lN(Today.drat_spot_ask/Prev.drat_spot_ask)
      from (select drat_currency_code,drat_for_currency,drat_spot_bid,drat_spot_Ask
              from trtran012 T inner join 
               (select distinct Vpos_Currency_code,Vpos_For_Currency 
                 from trcovar005) Pos
          on drat_currency_code= vpos_currency_code
          and drat_for_currency=vpos_for_currency
          where drat_serial_number = (select max(drat_serial_number)
                                     from trtran012 Se
                                     where se.drat_currency_code=t.drat_currency_code
                                       and se.drat_for_currency= t.drat_for_currency
                                       and se.drat_effective_date= t.drat_effective_date)
          and drat_effective_date=datRatesAva)Prev
          inner join 
          (select drat_currency_code,drat_for_currency,drat_spot_bid,Drat_spot_ask
              from trtran012 T inner join 
                 (select distinct Vpos_Currency_code,Vpos_For_Currency 
                    from trcovar005) Pos
                    on drat_currency_code= vpos_currency_code
                    and drat_for_currency=vpos_for_currency
                    where drat_serial_number = (select max(drat_serial_number)
                                               from trtran012 Se
                                               where se.drat_currency_code=t.drat_currency_code
                                                 and se.drat_for_currency= t.drat_for_currency
                                                 and se.drat_effective_date= t.drat_effective_date)
                    and drat_effective_date=DatRatesNextAva)Today
            on Today.drat_currency_code =Prev.drat_currency_code
           and Today.drat_for_currency =Prev.drat_for_currency;
        
        
    VarOperation := 'Get the next date rates avaliable from Latest rates Avaliable date';
    datRatesAva:= DatRatesNextAva;
    
    select min(drat_effective_Date)
       into DatRatesNextAva
     from trtran012 
     where drat_effective_date >datRatesAva
      and drat_record_status not in (10200005,10200006);
      
        dbms_output.put_line('Next the loop' || to_char(DatRatesNextAva) );

  
    end loop;
    commit;
end CoVar_populateRates;

--------------------------------------------------------------------------------------------------------------------------
procedure COVAR_Position_populate(
CompanyCode in varchar,LocationCode in Varchar,
ProductCode in varchar,SubProductCode in Varchar,
IncludHedging in char)
as
begin
delete from trcovar005;
insert into trcovar005 (Vpos_company_code,Vpos_location_code,
Vpos_Product_code,Vpos_subProduct_code,Vpos_currency_code,
Vpos_For_Currency,Vpos_Transaction_amount)
select posn_company_code, posn_location_code,
Posn_product_code, posn_subproduct_code,Posn_currency_code,
Posn_For_currency,sum(case when (posn_account_code <25900050) then -1*posn_transaction_amount
                           else posn_transaction_amount end)
from trsystem997 
where (posn_company_code = decode(CompanyCode,'30199999',posn_company_code)
       or instr(CompanyCode,posn_company_code)>0)
and (posn_Location_code = decode(LocationCode,'30299999',posn_Location_code)
     or instr(LocationCode,Posn_Location_code)>0)
and (posn_Product_code = decode(ProductCode,'33399999',posn_Product_code)
     or instr(ProductCode,Posn_Product_code)>0)
and (posn_subProduct_code = decode(subProductCode,'33899999',posn_subProduct_code)
     or instr(subProductCode,Posn_subProduct_code)>0)
and ((IncludHedging='Y') or ((IncludHedging='N') and (posn_account_code not in (25900011,25900012,25900014,25900015,
                                      25900018,25900019,25900020,25900021,25900022,25900023,
                                      25900061,25900062,25900074,25900075,25900078,25900079,
                                      25900082,25900083,25900084,25900085))))
group by  posn_company_code, posn_location_code,
Posn_product_code, posn_subproduct_code,Posn_currency_code,
Posn_For_currency;

commit;

end COVAR_Position_populate;
end PKGVarCovar;
/