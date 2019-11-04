CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGBULKDATALOAD" AS
Procedure prcSchemDataload;

Procedure prcNavLoad;

Procedure prcNAVHistory;

Procedure prcXlsRateUpLoad;

--Procedure prcCPLoad;
--
--Procedure prcCDLoad;
--
--Procedure prcCPTrade;
--
--Procedure prcCDTrade;

Procedure prcFXALLDATA;


Function fncGetPickCode(
         PickDescription in varchar,
         pickCode in number,
         AddNewEntry in char) return number;
--function fncGetSchemeCode(
--         PickKeyValue in number)
--         return number;
function fncGetPickCode1(
         PickSapCode in varchar,
         PickDescription in varchar,
         pickCode in number,
         AddNewEntry in char) return number;
         
procedure prcProcessPickup
              ( numKeyGroup in number,
                PickShortDescription in varchar,
                PickLongDescription in varchar,
                numPickValue out number);

procedure prcPopulateExposure;
PROCEDURE prcFORWARDContractLoad;
Procedure prcFXGOFXALLDATA;
Procedure Prcexposuredataload;
PROCEDURE PRCFUTURESDATALOAD;
procedure prcEDELFUTURESDataLoad;
procedure PRCFUTURESDATAINSERT;
Procedure prcOPTIONVALUATIONDATALOAD;
Procedure prcBloomburgDataload;
Procedure prcShippingDetails;
Procedure prcDueDateAlert(NumDay in Number);
Procedure prcIRSMTMUpload;
--Procedure prcShippingEntry (Traderefernce in Varchar2,Entrity in Varchar2,workdate in Date,numAction in number);

function extract_number(in_number varchar2) return varchar2;
   procedure prcProcessPickupsap
              ( pickSapCode in varchar,
                numKeyGroup in number,
                PickShortDescription in varchar,
                PickLongDescription in varchar,
                numPickValue out number);
                
--Procedure prcSalesInvoice;
----Procedure prcsalesorderupload;
--Procedure prcPurchaseOrder;
--Procedure prcPurchaseInvoice;
procedure ValidateData
(LoadName in varchar);
end;
/