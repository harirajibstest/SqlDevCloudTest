CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETRISKLIMITS" (
      riskType in number, 
      ProductCode in number,
      SubProductCode in number,
      frmdate in date
      ) return varchar
 as 
   varRiskLimitRange varchar(50);
 begin     
   if SubProductCode is null then 
   
    select distinct RISK_LIMIT_PERCENT  || ( case when (RISK_LIMIT_PERCENT != RISK_FLUCT_ALLOWED) then 
                                                     ' - ' ||  RISK_FLUCT_ALLOWED || ' %' else ' %' end)
       into varRiskLimitRange                                              
     from trsystem012
     where risk_risk_type=riskType
      and risk_product_code=ProductCode
     -- and risk_effective_date<= frmdate
       and  risk_effective_date = (select max(risk_effective_date) 
                                      from trsystem012
                                      where  
                                      risk_risk_type=21000017
                                  and risk_product_code=ProductCode
                                  and risk_effective_date<= frmdate);
                                 -- and risk_subproduct_code=SubProductCode 
      --and risk_subproduct_code=SubProductCode;
      
   else
     select RISK_LIMIT_PERCENT  || ( case when (RISK_LIMIT_PERCENT != RISK_FLUCT_ALLOWED) then 
                                                     ' - ' ||  RISK_FLUCT_ALLOWED || ' %' else ' %' end)
       into varRiskLimitRange                                              
     from trsystem012
     where risk_risk_type=riskType
      and risk_product_code=ProductCode
      and risk_subproduct_code=SubProductCode
      and  risk_effective_date = (select max(risk_effective_date) 
                                      from trsystem012
                                      where  
                                      risk_risk_type=21000017
                                  and risk_product_code=ProductCode
                                  and risk_effective_date<= frmdate
                                  and risk_subproduct_code=SubProductCode );
                                                                 
   
   end if;
    return varRiskLimitRange;
end;
 
 
 
 
 
 
 
 
 
 
/