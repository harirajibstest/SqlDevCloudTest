CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoptcontractxl (company,orderdate,po_no,name_of_supplier,notional,uncovered,deliveryperiod,paymentterm,product,refno,dealdate,dealtype,companyname,bank,dealnotional,maturity,settlement,bp,sp,bc,sc,premiumcross,premiuminr,bankref,dealnumber,canceldate,cancelrate,gainloss,netgain,impdate,impinvoiceno,supplier,impduedate,ispotdate,importvalue,expdate,expinvoiceno,expbank,customer,productname,eduedate,espotdate,export_os_usd,profitandloss) AS
select pkgReturnCursor.fncGetDescription(trpt_ord_company, 2) Company,
      trpt_ord_date OrderDate,
      trpt_ord_reference PO_No,
      pkgReturnCursor.fncGetDescription(trpt_ord_supplier, 1) Name_of_Supplier,
      trpt_ord_notional Notional,
      trpt_ord_uncovered Uncovered,
      to_char(trpt_ord_matfrom, 'dd/mm/yy')
      || decode(trpt_ord_matfrom, null, '', ' to ')
      || to_char(trpt_ord_matdate, 'dd/mm/yy') DeliveryPeriod,
      trpt_ord_payterm PaymentTerm,
      pkgReturnCursor.fncGetDescription(trpt_ord_product, 1) Product,
      trpt_ord_number REFNO,
      trpt_deal_date DealDate,
      decode(trpt_deal_type, 32200001, 'Forward', 32200002, 'Future', 32200003, 'Options') DealType,
      pkgReturnCursor.fncGetDescription(trpt_deal_company, 2) Companyname,
      pkgReturnCursor.fncGetDescription(trpt_deal_bank, 2) Bank,
      trpt_deal_amount DealNotional,
      trpt_deal_matdate Maturity,
      trpt_deal_setl_date Settlement,
      trpt_deal_bp BP,
      trpt_deal_sp SP,
      trpt_deal_bc BC,
      trpt_deal_sc SC,
      trpt_deal_premcross PremiumCROSS,
      trpt_deal_preminr PremiumINR,
      trpt_deal_bankref BankRef,
      trpt_deal_number DealNumber,
      trpt_cancel_date CancelDate,
      trpt_rbi_refrate CancelRate,
      trpt_cancel_amount GainLoss,
      trpt_profit_loss - trpt_deal_preminr NetGain,
      --trpt_gain_loss NetGain,
      case
         when trpt_import_export > 25900050
         then trpt_inv_date
         else null
      end ImpDate,
      case
         when trpt_import_export > 25900050
         then trpt_inv_no
         else null
      end IMPInvoiceno,
      case
         when trpt_import_export > 25900050
         then pkgReturnCursor.fncGetDescription(trpt_inv_supplier, 1)
         else null
      end Supplier,
      case
         when trpt_import_export > 25900050
         then trpt_inv_duedate
         else null
      end impDuedate,
      case
         when trpt_import_export > 25900050
         then trpt_inv_spotdate
         else null
      end iSpotDate,
      --case when trpt_import_export> 25900050 then pkgReturnCursor.fncGetDescription(trpt_inv_bank, 2) else null end,
      case
         when trpt_import_export > 25900050
         then trpt_inv_amount
         else null
      end ImportValue,
      --case when trpt_import_export> 25900050 then trpt_inv_product else null end,
      case
         when trpt_import_export <= 25900050
         then trpt_inv_date
         else null
      end Expdate,
      case
         when trpt_import_export <= 25900050
         then trpt_inv_no
         else null
      end EXPInvoiceno,
      case
         when trpt_import_export <= 25900050
         then pkgReturnCursor.fncGetDescription(trpt_inv_bank, 2)
         else null
      end ExpBank,
      case
         when trpt_import_export <= 25900050
         then pkgReturnCursor.fncGetDescription(trpt_inv_supplier, 1)
         else null
      end Customer,
      case
         when trpt_import_export <= 25900050
         then pkgReturnCursor.fncGetDescription(trpt_inv_product, 2)
         else null
      end Productname,
      case
         when trpt_import_export <= 25900050
         then trpt_inv_duedate
         else null
      end eDueDate,
      case
         when trpt_import_export <= 25900050
         then trpt_inv_spotdate
         else null
      end eSpotDate,
      case
         when trpt_import_export <= 25900050
         then trpt_inv_amount
         else null
      end Export_OS_USD,
      trpt_profit_loss ProfitandLoss
      from trsystem985
  order by trpt_group_no,
      trpt_row_no
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;