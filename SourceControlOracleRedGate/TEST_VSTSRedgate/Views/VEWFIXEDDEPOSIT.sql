CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfixeddeposit ("S.No","FD No","Sys Ref No","Bank Name","Rate per FD Certificate","Closure Rate of Interest","Value Date","Actual Maturity Date","Maturity Date","No. of Days","Closure after Maturity Date","FD Prematured","Total Principal Amount","Opening Principal amount","Principal Added during period","Principal Matured during perio","Closing Principal Amount","Opening Accrued interest","Total Gross Interest","TDS on Interest","Net interest","Closing Accrued Interest"," FD Matured During the period","Amount Credited to Bank A/c","Amount Re-invested","Difference","A/c No") AS
select
             RowNum as SNo,
             --pkgreturncursor.fncgetdescription(FDCL_COMPANY_CODE,1) as Company,            
             FDRF_BANK_REFERENCE as FDNo,
             FDRF_FD_NUMBER as SysRefNo,
             pkgreturncursor.fncgetdescription(FDRF_LOCAL_BANK,2) as BankName,
             FDRF_interest_rate RateperFDCertificate,
             FDCL_INTEREST_RATE ActualRateofpayment,
             FDRF_REFERENCE_DATE DateofDeposit,
             fdcl_closure_date ActualMaturityDate,
             fdrf_maturity_date         MaturityDate,
             (fdrf_maturity_date - FDRF_REFERENCE_DATE) as NoDays,
             decode(sign(fdrf_maturity_date -nvl(FDcl_CLOSURE_dATE,fdrf_maturity_date)) ,1,'No','Yes') as  MaturityafterMaturityDate, 
             decode(sign(fdrf_maturity_date -nvl(FDcl_CLOSURE_dATE,fdrf_maturity_date)) ,1,'Yes','No') as IstheFDprematured,
             fdrf_deposit_amount TotalAmount,
             decode( sign(fdrf_reference_date-(select Fromdate from  TRSYSTEM981)),-1 ,fdrf_deposit_amount,0) as  PrincipalOpenbeforefromdate ,
             decode( sign(fdrf_reference_date-(select Fromdate from  TRSYSTEM981)),1 ,fdrf_deposit_amount,0) as Additionsduringtheyear ,
             (select nvl(sum(nvl(fdcl_deposit_amount,0)),0) from trtran047a
                    where fdcl_fd_number=fdrf_fd_number  and fdcl_sr_number=fdrf_sr_number
                    and fdcl_closure_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981) and fdcl_record_status =10200003) as MaturedDuringtheyear, ---need to check
             (fdrf_deposit_amount - (select nvl(sum(nvl(fdcl_deposit_amount,0)),0) from trtran047a
                                      where fdcl_fd_number=fdrf_fd_number  and fdcl_sr_number=fdrf_sr_number
                                      and fdcl_closure_date <= (select ToDate from  TRSYSTEM981) and fdcl_record_status not in (10200005,10200006))) as Closingasat31032013,
             (select nvl(sum(decode(INTC_CHARGING_TYPE,42200004,-INTC_INTCHARGE_AMOUNT,INTC_INTCHARGE_AMOUNT)) ,0) 
                  from trtran047b
                  where INTC_SCHEME_CODE=fdrf_scheme_code
                  and   INTC_FD_NUMBER=FDRF_FD_NUMBER
                  and   INTC_FD_SRNUMBER=FDRF_sr_NUMBER 
                  and   INTC_CREDIT_TO  =42300003
                  and INTC_CHARGING_TYPE <> 42200003
                  and  intc_charging_date <(select Fromdate from  TRSYSTEM981)
                  and   intc_record_status between 10200001 and 10200004)  as IntAccruednotdueasfromdate ,
              (select nvl(sum(decode(INTC_CHARGING_TYPE,42200004,-INTC_INTCHARGE_AMOUNT,INTC_INTCHARGE_AMOUNT)) ,0) 
                  from trtran047b
                  where INTC_SCHEME_CODE=fdrf_scheme_code
                  and   INTC_FD_NUMBER=FDRF_FD_NUMBER
                  and   INTC_FD_SRNUMBER=FDRF_sr_NUMBER 
                  and   INTC_CREDIT_TO  =42300003
                  and INTC_CHARGING_TYPE <> 42200003
                  and  intc_charging_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981)
                  and   intc_record_status between 10200001 and 10200004)  as GrossintIncomeinCurrentFY ,
              (select nvl(sum(nvl(TDSC_TDS_AMOUNT +nvl(TDSC_SERCHARGE_AMOUNT,0),0)),0)  
                   from trtran047c 
                   where tdsc_SCHEME_CODE=fdrf_scheme_code
                     and tdsc_fd_number=fdrf_fd_number
                     and TDSC_FD_SRNUMBER=fdrf_sr_number 
                     and TDSC_DEDUCTED_DATE <= (select ToDate from  TRSYSTEM981)
                     and tdsc_record_status between 10200001 and 10200004 )   as TDSonInterest,
                (select nvl(sum(decode(INTC_CHARGING_TYPE,42200004,-INTC_INTCHARGE_AMOUNT,INTC_INTCHARGE_AMOUNT)) ,0) 
                  from trtran047b
                  where INTC_SCHEME_CODE=fdrf_scheme_code
                  and   INTC_FD_NUMBER=FDRF_FD_NUMBER
                  and   INTC_FD_SRNUMBER=FDRF_sr_NUMBER 
                  and   INTC_CREDIT_TO  =42300003
                  and INTC_CHARGING_TYPE <> 42200003
                  and  intc_charging_date <= (select ToDate from  TRSYSTEM981)
                  and   intc_record_status between 10200001 and 10200004) - 
                                        (select nvl(sum(nvl(TDSC_TDS_AMOUNT +nvl(TDSC_SERCHARGE_AMOUNT,0),0)),0)  
                                               from trtran047c 
                                               where tdsc_SCHEME_CODE=fdrf_scheme_code
                                                 and tdsc_fd_number=fdrf_fd_number
                                                 and TDSC_FD_SRNUMBER=fdrf_sr_number 
                                                 and TDSC_DEDUCTED_DATE < (select ToDate from  TRSYSTEM981)
                                                 and tdsc_record_status between 10200001 and 10200004 ) as Netinterestfortheyear ,
                (select nvl(sum(decode(INTC_CHARGING_TYPE,42200001,INTC_INTCHARGE_AMOUNT,-INTC_INTCHARGE_AMOUNT)) ,0) 
                  from trtran047b
                  where INTC_SCHEME_CODE=fdrf_scheme_code
                  and   INTC_FD_NUMBER=FDRF_FD_NUMBER
                  and   INTC_FD_SRNUMBER=FDRF_sr_NUMBER 
                  and   INTC_CREDIT_TO  =42300003
                  and INTC_CHARGING_TYPE <> 42200005
                  and  intc_charging_date <=(select ToDate from  TRSYSTEM981)
                  and   intc_record_status between 10200001 and 10200004)  as IntAccruednotdueontodate ,
              decode( sign(nvl(fdrf_complete_date,fdrf_reference_date)-(select Fromdate from  TRSYSTEM981)) ,1,decode(sign( (select ToDate from  TRSYSTEM981)-fdrf_complete_date) ,1 , 'Yes','No'),'No') as FDMaturedduringtheperiod ,
              
              (select sum(nvl(fdcl_deposit_amount,0))+ sum(nvl(fdcl_int_paidamt,0)) from trtran047a
                                      where fdcl_fd_number=fdrf_fd_number  and fdcl_sr_number=fdrf_sr_number
                                      and fdcl_closure_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981) and fdcl_record_status not in (10200005,10200006)
                                      and fdcl_closure_type <> 31600004)           as AmountCreditedtoBankAc,

              (select sum(nvl(fdcl_deposit_amount,0))+ sum(nvl(fdcl_int_paidamt,0)) from trtran047a
                                      where fdcl_fd_number=fdrf_fd_number  and fdcl_sr_number=fdrf_sr_number
                                      and fdcl_closure_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981) and fdcl_record_status not in (10200005,10200006)
                                      and fdcl_closure_type = 31600004)           as AmountReinvested,
              (((select nvl(sum(nvl(fdcl_deposit_amount,0)),0) from trtran047a
                    where fdcl_fd_number=fdrf_fd_number  and fdcl_sr_number=fdrf_sr_number
                    and fdcl_closure_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981) and fdcl_record_status not in (10200005,10200006)) + 
              
              (select nvl(sum(decode(INTC_CHARGING_TYPE,42200004,-INTC_INTCHARGE_AMOUNT,INTC_INTCHARGE_AMOUNT)) ,0) 
                  from trtran047b
                  where INTC_SCHEME_CODE=fdrf_scheme_code
                  and   INTC_FD_NUMBER=FDRF_FD_NUMBER
                  and   INTC_FD_SRNUMBER=FDRF_sr_NUMBER 
                  and   INTC_CREDIT_TO  =42300003
                  and INTC_CHARGING_TYPE <> 42200003
                  and  intc_charging_date <(select Fromdate from  TRSYSTEM981)
                  and   intc_record_status between 10200001 and 10200004) +
             ((select nvl(sum(decode(INTC_CHARGING_TYPE,42200001,INTC_INTCHARGE_AMOUNT,42200005,INTC_INTCHARGE_AMOUNT,-INTC_INTCHARGE_AMOUNT)) ,0) 
                  from trtran047b
                  where INTC_SCHEME_CODE=fdrf_scheme_code
                  and   INTC_FD_NUMBER=FDRF_FD_NUMBER
                  and   INTC_FD_SRNUMBER=FDRF_sr_NUMBER 
                  and   INTC_CREDIT_TO  =42300003
                  and INTC_CHARGING_TYPE <> 42200003
                  and  intc_charging_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981)
                  and   intc_record_status between 10200001 and 10200004) - 
                                        (select nvl(sum(nvl(TDSC_TDS_AMOUNT +nvl(TDSC_SERCHARGE_AMOUNT,0),0)),0)  
                                               from trtran047c 
                                               where tdsc_SCHEME_CODE=fdrf_scheme_code
                                                 and tdsc_fd_number=fdrf_fd_number
                                                 and TDSC_FD_SRNUMBER=fdrf_sr_number 
                                                 and TDSC_DEDUCTED_DATE < (select ToDate from  TRSYSTEM981)
                                                 and tdsc_record_status between 10200001 and 10200004 ))) -
            (select sum(nvl(fdcl_deposit_amount,0))+ sum(nvl(fdcl_int_paidamt,0)) from trtran047a
                                      where fdcl_fd_number=fdrf_fd_number  and fdcl_sr_number=fdrf_sr_number
                                      and fdcl_closure_date between (select Fromdate from  TRSYSTEM981) and (select ToDate from  TRSYSTEM981) and fdcl_record_status not in (10200005,10200006))) as Difference,
                                      
              NVL(FDCL_CREDIT_ACNO, FDRF_CREDIT_ACNO)  as AcNo        
            -- pkgreturncursor.fncgetdescription(FDRF_CREDIT_ACNO,2) as AcNo
                      
             --(select Fromdate from  TRSYSTEM981) as AsonDate,
             --(select ToDate from  TRSYSTEM981) As ToDate             
      from trtran047, trtran047a
            where FDRF_FD_NUMBER=FDCL_FD_NUMBER(+)
            and fdrf_sr_number=fdcl_sr_number(+)
            and FDRF_RECORD_STATUS not in(10200005,10200006)
            and nvl(FDCL_RECORD_STATUS,10200001) not in(10200005,10200006)
            and fdrf_reference_date < (select ToDate from  TRSYSTEM981)
            and (FDRF_PROCESS_COMPLETE=12400002 OR FDRF_COMPLETE_DATE > (select Fromdate from  TRSYSTEM981))
            order by FDrf_FD_NUMBER
 
 
 
 
 
 
 
 
 
 ;