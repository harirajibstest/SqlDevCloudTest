CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGREPORTPROGRAMS" AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
PROCEDURE PRCCALCULATEGAPEXPOSURE (
          datDateAsOn in date, 
          GapCalType in number ,
          ProductCode in number,
          SubProductCode in number);
  
procedure prcHedgeStatusReportPopulate(
             varUserid in varchar,
             frmDate in date,
             ProductCode in number,
             SubProductCode in number);
             
procedure prcFxForcastReportPopulate(
            frmdate in date);

procedure prcreport_M_yearlyexp
 ( frmDate in date,
   tempDate in date,
   datTemp in date);            
            
            
procedure prcforexsumprodwisePopulate
(
             varUserid in varchar,
             frmDate in date,
             ProductCode in number,
             SubProductCode in number);

procedure prcFxForcastRptPopulatePreYear(
            frmdate in date);     
            
procedure prcHedgeStatusUSDRptPopulate(
             Varuserid In Varchar,
             frmDate in date,
             Productcode In Number,
             SubProductCode in number);              
END PKGREPORTPROGRAMS;
 
 
/