CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGVARCOVAR" 
as 
procedure COVAR_Position_populate(
CompanyCode in varchar,LocationCode in Varchar,
ProductCode in varchar,SubProductCode in Varchar,
IncludHedging in char);

procedure CoVar_populateRates ( 
      DatFromDate date,
      datToDate date);
      
procedure COVAR_Populate_Var_Covar ( 
      datform date,
      datTo date,
      AdjustEarnings number);

procedure COVAR_POPULATE_HEDGERATIO;      

end;
 
 
 
 
 
 
 
/