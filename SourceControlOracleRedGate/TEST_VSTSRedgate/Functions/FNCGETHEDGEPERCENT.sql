CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETHEDGEPERCENT" (
      datWorkDate in date,
      CalculationType in varchar,
      ProductCode in number,
      SubProductCode in number,
      Currency in number)
      return  number
    as
      numTemp number(15,2);
    begin 
    if SubProductCode is null then 
       select round(((select sum(HEDG_MON_Forward1+HEDG_MON_Forward2+HEDG_MON_Forward3+HEDG_MON_Forward4+
                              HEDG_MON_Forward5+HEDG_MON_Forward6+HEDG_MON_Forward7+HEDG_MON_Forward8+
                              HEDG_MON_Forward9+HEDG_MON_Forward10+HEDG_MON_Forward11+
                              HEDG_MON_Forward12)
                              from trsystem970
                              where hedg_Exposure_type in   ('Hedge Buy','Hedge Sell')  
                              and HEDG_CALCULATION_TYPE=CalculationType
                              and HEDG_DATE_ASON=datWorkDate
                              and hedg_currency_code=Currency
                              and hedg_product_code=ProductCode
--                              and hedg_subproduct_code=SubProductCode
                              ) /
             
              nvl((select (case when sum(HEDG_MON_Forward1+HEDG_MON_Forward2+HEDG_MON_Forward3+HEDG_MON_Forward4+
                              HEDG_MON_Forward5+HEDG_MON_Forward6+HEDG_MON_Forward7+HEDG_MON_Forward8+
                              HEDG_MON_Forward9+HEDG_MON_Forward10+HEDG_MON_Forward11+
                              HEDG_MON_Forward12) =0 then 1 
                              else sum(HEDG_MON_Forward1+HEDG_MON_Forward2+HEDG_MON_Forward3+HEDG_MON_Forward4+
                              HEDG_MON_Forward5+HEDG_MON_Forward6+HEDG_MON_Forward7+HEDG_MON_Forward8+
                              HEDG_MON_Forward9+HEDG_MON_Forward10+HEDG_MON_Forward11+
                              HEDG_MON_Forward12) end)
                              from trsystem970
                              where hedg_Exposure_type in ('Import','Export') 
                              and HEDG_CALCULATION_TYPE=CalculationType
                              and HEDG_DATE_ASON=datWorkDate
                              and hedg_currency_code=Currency
                              and hedg_product_code=ProductCode
--                              and hedg_subproduct_code=SubProductCode
                              ),1)
                             
             )*100 ,0) into numTemp
             from dual;
      else
      select round(((select sum(HEDG_MON_Forward1+HEDG_MON_Forward2+HEDG_MON_Forward3+HEDG_MON_Forward4+
                              HEDG_MON_Forward5+HEDG_MON_Forward6+HEDG_MON_Forward7+HEDG_MON_Forward8+
                              HEDG_MON_Forward9+HEDG_MON_Forward10+HEDG_MON_Forward11+
                              HEDG_MON_Forward12)
                              from trsystem970
                              where hedg_Exposure_type in   ('Hedge Buy','Hedge Sell')  
                              and HEDG_CALCULATION_TYPE=CalculationType
                              and HEDG_DATE_ASON=datWorkDate
                              and hedg_currency_code=Currency
                              and hedg_product_code=ProductCode
                              and hedg_subproduct_code=SubProductCode
                              ) /
             
              nvl((select (case when sum(HEDG_MON_Forward1+HEDG_MON_Forward2+HEDG_MON_Forward3+HEDG_MON_Forward4+
                              HEDG_MON_Forward5+HEDG_MON_Forward6+HEDG_MON_Forward7+HEDG_MON_Forward8+
                              HEDG_MON_Forward9+HEDG_MON_Forward10+HEDG_MON_Forward11+
                              HEDG_MON_Forward12) =0 then 1 
                              else sum(HEDG_MON_Forward1+HEDG_MON_Forward2+HEDG_MON_Forward3+HEDG_MON_Forward4+
                              HEDG_MON_Forward5+HEDG_MON_Forward6+HEDG_MON_Forward7+HEDG_MON_Forward8+
                              HEDG_MON_Forward9+HEDG_MON_Forward10+HEDG_MON_Forward11+
                              HEDG_MON_Forward12) end)
                              from trsystem970
                              where hedg_Exposure_type in ('Import','Export') 
                              and HEDG_CALCULATION_TYPE=CalculationType
                              and HEDG_DATE_ASON=datWorkDate
                              and hedg_currency_code=Currency
                              and hedg_product_code=ProductCode
                              and hedg_subproduct_code=SubProductCode
                              ),1)
                             
             )*100 ,0) into numTemp
             from dual;
        end if;     
    return  numTemp ;            
    end ;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/