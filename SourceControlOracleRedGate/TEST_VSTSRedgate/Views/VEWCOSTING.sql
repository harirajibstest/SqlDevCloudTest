CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewcosting (company,fxbkdwith,bank,currency,place,lcdate,lcduedate,fxduedate,lcnumber,lcamount,lcrate,userref,amountcovered,vesselname,app,contractno,lcremarks,utilizedamount,uncoveredamount,actualamount,bkdrate,dealdate,dlno,actualamtbooked,totactualamtbkd,systemdate,companyname,asondate,mtmrate,mtmspot,mtmfrwdprim,spotratepo,fwdprimiumpo,totalratepo,diffrence,mtmpandl,hedgeamount,spotratehedge,frwdmaginhedge,totalratehedge,diffrencehedge,pandl,totalpandl,remarks,impexp,entrydate,primiumpcfc) AS
select  a.TRAD_COMPANY_CODE as  Company,
               pkgreturncursor.fncgetdescription(DEAL_COUNTER_PARTY,2)as FXBkdWith,
               TRAD_LOCAL_BANK as Bank,
               a.TRAD_TRADE_CURRENCY as Currency,
               (select LBNK_ADDRESS_4 from TRMASTER306 where LBNK_PICK_CODE = a.TRAD_LOCAL_BANK) as Place, 
               a.trad_entry_date as LcDate,
               a.TRAD_MATURITY_DATE as LCDueDate,
               DEAL_MATURITY_DATE as FxDueDate,
               a.TRAD_TRADE_REFERENCE as LCNumber,
               a.TRAD_TRADE_FCY as LCAmount,
               a.trad_trade_rate as LcRate,
               (select trad_user_reference from trtran002 where trad_trade_reference = a.trad_reverse_reference) as Userref,
               (select sum(HEDG_HEDGED_FCY)  from trtran004,trtran001 
                where  HEDG_DEAL_NUMBER = deal_deal_number 
                       and hedg_deal_serial = deal_serial_number
                       and HEDG_TRADE_REFERENCE= a.trad_trade_reference
                       and deal_execute_DATE <= (select FROMDATE from trsystem981)                      
                       and deal_RECORD_STATUS not in(10200005,10200006)
                       and hedg_RECORD_STATUS not in(10200005,10200006)
                       and (deal_process_complete = 12400002 or (deal_process_complete=12400001 and deal_complete_date> (select FROMDATE from trsystem981)))
               ) as AmountCovered,
               (select pkgreturncursor.fncgetdescription(TRAD_VESSEL_NAME,2) from trtran002 where trad_trade_reference = a.TRAD_REVERSE_REFERENCE) as VesselName,
               (select trad_app from trtran002 where trad_trade_reference = a.TRAD_REVERSE_REFERENCE) as App,
               (select TRAD_CONTRACT_NO from trtran002 where trad_trade_reference = a.trad_reverse_reference )as ContractNo,
               a.trad_trade_remarks as LCRemarks,
               HEDG_HEDGED_FCY as UtilizedAmount,
               (TRAD_TRADE_FCY - (select sum(HEDG_HEDGED_FCY)  from trtran004,trtran001 
                                  where  HEDG_DEAL_NUMBER = deal_deal_number 
                                         and hedg_deal_serial = deal_serial_number
                                         and HEDG_TRADE_REFERENCE= a.trad_trade_reference
                                         and deal_execute_DATE <=  (select FROMDATE from trsystem981)
                                         and deal_RECORD_STATUS not in(10200005,10200006)
                                         and hedg_RECORD_STATUS not in(10200005,10200006)
                                         and (deal_process_complete = 12400002 or (deal_process_complete=12400001 and deal_complete_date> (select FROMDATE from trsystem981))))
               ) as UnCoveredAmount,
               deal_base_amount as  ActualAmount,
               DEAL_EXCHANGE_RATE as BkdRate,
               DEAL_EXECUTE_DATE as DealDate,
               DEAL_DEAL_NUMBER as DlNo,
               DEAL_BASE_AMOUNT as ActualAmtBooked,
               (select sum(hedgefcy) from 
                        (select sum(HEDG_HEDGED_FCY)  as hedgefcy
                        from   trtran002,trtran001,trtran004
                        where  DEAL_DEAL_NUMBER = HEDG_DEAL_NUMBER
                               and DEAL_SERIAL_NUMBER = HEDG_DEAL_SERIAL
                               and HEDG_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
                               and ((TRAD_PROCESS_COMPLETE = 12400001  and TRAD_COMPLETE_DATE >  (select FROMDATE from trsystem981)) or TRAD_PROCESS_COMPLETE = 12400002)                                   
                               and TRAD_reference_DATE <=  (select FROMDATE from trsystem981)
                               and TRAD_RECORD_STATUS not in(10200005,10200006)
                               and deal_RECORD_STATUS not in(10200005,10200006)
                               and hedg_RECORD_STATUS not in(10200005,10200006)
                               and (deal_process_complete = 12400002 or (deal_process_complete=12400001 and deal_complete_date> (select FROMDATE from trsystem981)))
                        group by HEDG_DEAL_NUMBER) ) as TotActualAmtBkd,
               pkgreturnreport.GetSystemDate() as SystemDate,
                '' as CompanyName,
               (select FROMDATE from trsystem981) as  AsonDate,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) as MTMRATE,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),Null)),Null) as MTMSPOT,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) -
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),Null)),Null) mtmFrwdPrim,
               nvl(trad_spot_rate,0) as SpotRatePo,
               nvl(TRAD_FORWARD_RATE,0) as FWDPrimiumPo,
               nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0) TotalRatePO,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) - (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) diffrence,
               case when TRAD_IMPORT_EXPORT > 25900050 then 
               (((nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) - pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE))
                    *
               (TRAD_TRADE_FCY - (select sum(HEDG_HEDGED_FCY)  from trtran004,trtran001 
                                   where  HEDG_DEAL_NUMBER = deal_deal_number 
                                   and hedg_deal_serial = deal_serial_number
                                   and HEDG_TRADE_REFERENCE= trad_trade_reference
                                   and deal_execute_DATE <=  (select FROMDATE from trsystem981)
                                   and deal_RECORD_STATUS not in(10200005,10200006)
                                   and hedg_RECORD_STATUS not in(10200005,10200006)
                                   and (deal_process_complete = 12400002 or (deal_process_complete=12400001 and deal_complete_date> (select FROMDATE from trsystem981))))))
               else
               ((pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) - (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)))
                    *
               (TRAD_TRADE_FCY - (select sum(HEDG_HEDGED_FCY)  from trtran004,trtran001 
                                   where  HEDG_DEAL_NUMBER = deal_deal_number 
                                   and hedg_deal_serial = deal_serial_number
                                   and HEDG_TRADE_REFERENCE= trad_trade_reference
                                   and deal_execute_DATE <=  (select FROMDATE from trsystem981)
                                   and deal_RECORD_STATUS not in(10200005,10200006)
                                   and hedg_RECORD_STATUS not in(10200005,10200006)
                                   and (deal_process_complete = 12400002 or (deal_process_complete=12400001 and deal_complete_date> (select FROMDATE from trsystem981))))))
               
               end as MTMPandL,
               HEDG_HEDGED_FCY HedgeAmount,
               DEAL_SPOT_RATE SpotrateHedge,
               DEAL_MARGIN_RATE + DEAL_FORWARD_RATE FrwdMaginHEdge,
               DEAL_EXCHANGE_RATE TotalrateHedge,
               (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) -  (DEAL_SPOT_RATE + DEAL_MARGIN_RATE + DEAL_FORWARD_RATE) DiffrenceHedge,
               case when TRAD_IMPORT_EXPORT > 25900050 then
               ((nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) -  (DEAL_SPOT_RATE + DEAL_MARGIN_RATE + DEAL_FORWARD_RATE)) * HEDG_HEDGED_FCY 
               else
               ((DEAL_SPOT_RATE + DEAL_MARGIN_RATE + DEAL_FORWARD_RATE) - (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) ) * HEDG_HEDGED_FCY
               end as PandL,
               0 as TotalPandL,
               '' as Remarks,
               TRAD_IMPORT_EXPORT ImpExp,
               TRAD_ENTRY_DATE EntryDate,
               0 PrimiumPCFC
        from   trtran002 a,trtran001,trtran004
        where  DEAL_DEAL_NUMBER = HEDG_DEAL_NUMBER
               and DEAL_SERIAL_NUMBER = HEDG_DEAL_SERIAL
               and HEDG_TRADE_REFERENCE = a.TRAD_TRADE_REFERENCE
               and ((TRAD_PROCESS_COMPLETE = 12400001 and TRAD_COMPLETE_DATE > (select FROMDATE from trsystem981)) or TRAD_PROCESS_COMPLETE = 12400002)                                   
               and a.TRAD_ENTRY_DATE <=  (select FROMDATE from trsystem981)
               and (deal_process_complete = 12400002 or (deal_process_complete=12400001 and deal_complete_date> (select FROMDATE from trsystem981)))
               /*and a.TRAD_IMPORT_EXPORT in(25900001,25900053,25900017)*/
               and a.TRAD_RECORD_STATUS not in(10200005,10200006)
               and deal_RECORD_STATUS not in(10200005,10200006,10200012)
               and hedg_RECORD_STATUS not in(10200005,10200006)
               --order by TRAD_reference_DATE
               
               Union
               
               select  a.TRAD_COMPANY_CODE as  Company,
               pkgreturncursor.fncgetdescription(FCLN_LOCAL_BANK,2)as FXBkdWith,
               TRAD_LOCAL_BANK as Bank,
               TRAD_TRADE_CURRENCY as Currency,
               (select LBNK_ADDRESS_4 from TRMASTER306 where LBNK_PICK_CODE = a.TRAD_LOCAL_BANK) as Place, 
               a.trad_entry_date as LcDate,
               a.TRAD_MATURITY_DATE as LCDueDate,
               FCLN_MATURITY_TO as FxDueDate,
               a.TRAD_TRADE_REFERENCE as LCNumber,
               a.TRAD_TRADE_FCY as LCAmount,
               a.trad_trade_rate as LcRate,
               (select trad_user_reference from trtran002 where trad_trade_reference = a.trad_reverse_reference) as Userref,
               (select sum(LOLN_ADJUSTED_FCY)  from trtran010,trtran005 
                where  LOLN_LOAN_NUMBER = FCLN_LOAN_NUMBER 
                       and LOLN_TRADE_REFERENCE= a.trad_trade_reference
                       and FCLN_SANCTION_DATE <= (select FROMDATE from trsystem981)                      
                       and FCLN_RECORD_STATUS not in(10200005,10200006)
                       and LOLN_RECORD_STATUS not in(10200005,10200006)
                       and (FCLN_PROCESS_COMPLETE = 12400002 or (FCLN_PROCESS_COMPLETE=12400001 and FCLN_COMPLETE_DATE> (select FROMDATE from trsystem981)))
               ) as AmountCovered,
               (select pkgreturncursor.fncgetdescription(TRAD_VESSEL_NAME,2) from trtran002 where trad_trade_reference = a.TRAD_REVERSE_REFERENCE) as VesselName,
               (select trad_app from trtran002 where trad_trade_reference = a.TRAD_REVERSE_REFERENCE) as App,
               (select TRAD_CONTRACT_NO from trtran002 where trad_trade_reference = a.trad_reverse_reference )as ContractNo,
               a.trad_trade_remarks as LCRemarks,
               LOLN_ADJUSTED_FCY as UtilizedAmount,
               --(TRAD_TRADE_FCY - HEDG_HEDGED_FCY ) as UnCoveredAmount,
               (TRAD_TRADE_FCY - (select sum(LOLN_ADJUSTED_FCY)  from trtran010,trtran005 
                where  LOLN_LOAN_NUMBER = FCLN_LOAN_NUMBER 
                       and LOLN_TRADE_REFERENCE= a.trad_trade_reference
                       and FCLN_SANCTION_DATE <= (select FROMDATE from trsystem981)                      
                       and FCLN_RECORD_STATUS not in(10200005,10200006)
                       and LOLN_RECORD_STATUS not in(10200005,10200006)
                       and (FCLN_PROCESS_COMPLETE = 12400002 or (FCLN_PROCESS_COMPLETE=12400001 and FCLN_COMPLETE_DATE> (select FROMDATE from trsystem981))))
               ) as UnCoveredAmount,
               FCLN_SANCTIONED_FCY as  ActualAmount,
               FCLN_CONVERSION_RATE as BkdRate,
               FCLN_SANCTION_DATE as DealDate,
               FCLN_LOAN_NUMBER as DlNo,
               FCLN_SANCTIONED_FCY as ActualAmtBooked,
               (select sum(LOLN_ADJUSTED_FCY) from 
                        (select sum(LOLN_ADJUSTED_FCY)  as hedgefcy
                        from   trtran002,trtran005,trtran010
                        where  FCLN_LOAN_NUMBER = LOLN_LOAN_NUMBER
                               and LOLN_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
                               and ((TRAD_PROCESS_COMPLETE = 12400001  and TRAD_COMPLETE_DATE >  (select FROMDATE from trsystem981)) or TRAD_PROCESS_COMPLETE = 12400002)                                   
                               and TRAD_reference_DATE <=  (select FROMDATE from trsystem981)
                               and TRAD_RECORD_STATUS not in(10200005,10200006)
                               and FCLN_RECORD_STATUS not in(10200005,10200006)
                               and LOLN_RECORD_STATUS not in(10200005,10200006)
                               and (FCLN_PROCESS_COMPLETE = 12400002 or (FCLN_PROCESS_COMPLETE=12400001 and FCLN_COMPLETE_DATE> (select FROMDATE from trsystem981)))
                        group by LOLN_LOAN_NUMBER) ) as TotActualAmtBkd,
               pkgreturnreport.GetSystemDate() as SystemDate,
               '' as CompanyName,
               (select FROMDATE from trsystem981) as  AsonDate,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) as MTMRATE,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),Null)),Null) as MTMSPOT,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) -
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),Null)),Null) mtmFrwdPrim,
               nvl(trad_spot_rate,0) as SpotRatePo,
               nvl(TRAD_FORWARD_RATE,0) as FWDPrimiumPo,
               nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0) TotalRatePO,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) - (nvl(TRAD_TRADE_RATE,0)) diffrence,
               ((pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) - (nvl(TRAD_TRADE_RATE,0)))
                    *
               (TRAD_TRADE_FCY -  (select sum(LOLN_ADJUSTED_FCY)  from trtran010,trtran005 
                where  LOLN_LOAN_NUMBER = FCLN_LOAN_NUMBER 
                       and LOLN_TRADE_REFERENCE= a.trad_trade_reference
                       and FCLN_SANCTION_DATE <= (select FROMDATE from trsystem981)                      
                       and FCLN_RECORD_STATUS not in(10200005,10200006)
                       and LOLN_RECORD_STATUS not in(10200005,10200006)
                       and (FCLN_PROCESS_COMPLETE = 12400002 or (FCLN_PROCESS_COMPLETE=12400001 and FCLN_COMPLETE_DATE> (select FROMDATE from trsystem981))))))MTMPandL,
               LOLN_ADJUSTED_FCY HedgeAmount,
               FCLN_CONVERSION_RATE SpotrateHedge,
               pkgforexprocess.fncGetRate(FCLN_CURRENCY_CODE,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(FCLN_LOCAL_BANK,(select FROMDATE from trsystem981),FCLN_MATURITY_FROM)),FCLN_MATURITY_FROM) - FCLN_CONVERSION_RATE FrwdMaginHEdge,
               FCLN_CONVERSION_RATE  + (pkgforexprocess.fncGetRate(FCLN_CURRENCY_CODE,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(FCLN_LOCAL_BANK,(select FROMDATE from trsystem981),FCLN_MATURITY_FROM)),FCLN_MATURITY_FROM) - FCLN_CONVERSION_RATE) TotalrateHedge,
               (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) -  (FCLN_CONVERSION_RATE) DiffrenceHedge,
               case when TRAD_IMPORT_EXPORT > 25900050 then
               ((nvl(trad_spot_rate,0)) -  (FCLN_CONVERSION_RATE)) * LOLN_ADJUSTED_FCY 
               else
               (((pkgforexprocess.fncGetRate(FCLN_CURRENCY_CODE,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(FCLN_LOCAL_BANK,(select FROMDATE from trsystem981),FCLN_MATURITY_FROM)),FCLN_MATURITY_FROM) - FCLN_CONVERSION_RATE) + FCLN_CONVERSION_RATE ) - (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0))) * LOLN_ADJUSTED_FCY
               end as PandL, -- Trade forward rate is ignored ,
               0 as TotalPandL,
               'Against PCFC' as Remarks,
               TRAD_IMPORT_EXPORT ImpExp,
               TRAD_ENTRY_DATE EntryDate,
               pkgforexprocess.fncGetRate(FCLN_CURRENCY_CODE,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(FCLN_LOCAL_BANK,(select FROMDATE from trsystem981),FCLN_MATURITY_FROM)),FCLN_MATURITY_FROM) PrimiumPCFC
        from   trtran002 a,trtran010,trtran005
        where  LOLN_TRADE_REFERENCE = a.TRAD_TRADE_REFERENCE
               and LOLN_LOAN_NUMBER = FCLN_LOAN_NUMBER
               and ((TRAD_PROCESS_COMPLETE = 12400001 and TRAD_COMPLETE_DATE > (select FROMDATE from trsystem981)) or TRAD_PROCESS_COMPLETE = 12400002)                                   
               and a.TRAD_ENTRY_DATE <=  (select FROMDATE from trsystem981)
               and (FCLN_PROCESS_COMPLETE = 12400002 or (FCLN_PROCESS_COMPLETE=12400001 and FCLN_COMPLETE_DATE> (select FROMDATE from trsystem981)))
               /*and a.TRAD_IMPORT_EXPORT in(25900001,25900053,25900017)*/
               and a.TRAD_RECORD_STATUS not in(10200005,10200006)
               and FCLN_RECORD_STATUS not in(10200005,10200006)
               and LOLN_RECORD_STATUS not in(10200005,10200006)
        UNION
          select  TRAD_COMPANY_CODE as  Company,
               null as FXBkdWith,
               TRAD_LOCAL_BANK as Bank,
               TRAD_TRADE_CURRENCY as Currency,
               (select LBNK_ADDRESS_4 from TRMASTER306 where LBNK_PICK_CODE = TRAD_LOCAL_BANK) as Place, 
               trad_entry_date as LcDate,
               TRAD_MATURITY_DATE as LCDueDate,
               null as FxDueDate,
               TRAD_TRADE_REFERENCE as LCNumber,
               TRAD_TRADE_FCY as LCAmount,
               trad_trade_rate as LcRate,
               (select trad_user_reference from trtran002 where trad_trade_reference = trad_reverse_reference) as Userref,
               0 AmountCovered,
               (select pkgreturncursor.fncgetdescription(TRAD_VESSEL_NAME,2) from trtran002 where trad_trade_reference = TRAD_REVERSE_REFERENCE) as VesselName,
               (select trad_app from trtran002 where trad_trade_reference = TRAD_REVERSE_REFERENCE) as App,
               (select TRAD_CONTRACT_NO from trtran002 where trad_trade_reference = trad_reverse_reference )as ContractNo,
               trad_trade_remarks as LCRemarks,
               0 as UtilizedAmount,
               TRAD_TRADE_FCY as UnCoveredAmount,
               0 as ActualAmount,
               0 as BkdRate,
               null as DealDate,
               null as DlNo,
               0 as ActualAmtBooked,
               0 as TotActualAmtBkd,
               pkgreturnreport.GetSystemDate() as SystemDate,
                '' as CompanyName,
               (select FROMDATE from trsystem981) as  AsonDate,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) as MTMRATE,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),Null)),Null) as MTMSPOT,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) -
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),Null)),Null) mtmFrwdPrim,
               nvl(trad_spot_rate,0) as SpotRatePo,
               nvl(TRAD_FORWARD_RATE,0) as FWDPrimiumPo,
               nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0) TotalRatePO,
               pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) - (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) diffrence,
                case when TRAD_IMPORT_EXPORT > 25900050 then
               ((nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)) - (pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE))
                    *
               (TRAD_TRADE_FCY)) 
               else 
               ((pkgforexprocess.fncGetRate(TRAD_TRADE_CURRENCY,30400003,(select FROMDATE from trsystem981),0,(pkgForexProcess.fncAllotMonth(TRAD_LOCAL_BANK,(select FROMDATE from trsystem981),TRAD_MATURITY_DATE)),TRAD_MATURITY_DATE) - (nvl(trad_spot_rate,0) +  nvl(TRAD_FORWARD_RATE,0)))
                    *
               (TRAD_TRADE_FCY)) 
               end as MTMPandL,
               0 HedgeAmount,
               0 SpotrateHedge,
               0 FrwdMaginHEdge,
               0 TotalrateHedge,
               0 DiffrenceHedge,
               0 as PandL,
               0 as TotalPandL,
               '' as Remarks,
               TRAD_IMPORT_EXPORT ImpExp,
               TRAD_ENTRY_DATE EntryDate,
               0 PrimiumPCFC
        from   trtran002 
        where TRAD_TRADE_REFERENCE not in (select  HEDG_TRADE_REFERENCE from trtran004 where hedg_record_status not in (10200005,10200006,10200012)) 
               and TRAD_TRADE_REFERENCE not in (select  LOLN_TRADE_REFERENCE from trtran010)
               and ((TRAD_PROCESS_COMPLETE = 12400001 and TRAD_COMPLETE_DATE > (select FROMDATE from trsystem981)) or TRAD_PROCESS_COMPLETE = 12400002)                                   
               and TRAD_ENTRY_DATE <=  (select FROMDATE from trsystem981)
               and TRAD_RECORD_STATUS not in(10200005,10200006)
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;