CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewforwardfuture (companycode,companyname,dealnumber,dealref,buysellcode,buysell,hedgecode,hedgetrade,bankcode,bankname,dealdate,dealamount,currencycode,othercode,currency,transcode,trans,exrate,maturity,completedate,canceldate,cancelamount,cancelrate,pandlfcy,status,dealtype,userid,initcode,asondate,balancefcy,balanceinr,m2mrate,washrate,mtmpandl,mtmpandlinr,cobrate,usdequalrate,balanceequalusd,spot,"FORWARD",margin,recordstatus,dealconfirmdate,dealconfirmtime,dealboremarks,deal_ourdealername,deal_theirdealername,deal_dealenteredby,edccharges,cancelconfirmtime,cancelconfirmdate,cancelboremarks,canceldealerremarks,cancelourdealername,canceltheirdealername,cancelenteredby,cashflowdate,userreference) AS
SELECT CompanyCode,
    CompanyName,
    DealNumber,
    dealref,
    BuySellCode,
    BuySell,
    HedgeCode,
    HedgeTrade,
    BankCode,
    BankName,
    DealDate,
    DealAmount,
    CurrencyCode,
    OtherCode,
    Currency,
    TransCode,
    Trans,
    Exrate,
    Maturity,
    CompleteDate,
    CancelDate,
    CancelAmount,
    Cancelrate,
    Pandlfcy,
    Status,
    Dealtype,
    Userid,
    Initcode,
    Asondate,
    BalanceFcy,
    BalanceINR,
    M2MRate,
    WashRate,
    mtmpandl,
    mtmpandlinr,
    cobrate,
    USDEqualRate,
    BalanceEqualUSD,
    Spot,
    Forward,
    Margin,
    RecordStatus,
    DealConfirmDate, DealConfirmTime, DealBORemarks, Deal_OurDealerName, Deal_TheirDealerName ,
Deal_DealEnteredby,  EDCCharges,  CancelConfirmTime,  CancelConfirmDate,
CancelBoRemarks,  CancelDealerRemarks,  CancelOurDealerName,  CancelTheirDealerName,
CancelEnteredBy,CashFlowDate,USERREFERENCE
  FROM vewReportForward
  UNION ALL
  SELECT CompanyCode,    CompanyName,    DealNumber,    dealref,
    BuySellCode,    BuySell,    HedgeCode,    HedgeTrade,    BankCode,
    BankName,    DealDate,    DealAmount,    CurrencyCode,    OtherCode,
    Currency,    TransCode,    Trans,    Exrate,    Maturity,    CompleteDate,
    CancelDate,    CancelAmount,    Cancelrate,    Pandlfcy,    Status,
    Dealtype,    Userid,    Initcode,    Asondate,    BalanceFcy,    BalanceINR,
    M2MRate,    WashRate,    mtmpandl,    mtmpandlinr,    cobrate,    USDEqualRate,
    BalanceEqualUSD,    Spot,    Forward,    Margin,    RecordStatus,
    DEALCONFIRMDATE, DEALCONFIRMTIME,DEALBOREMARKS,DEAL_OURDEALERNAME,
   DEAL_THEIRDEALERNAME,DEAL_DEALENTEREDBY,0 EDCCharges,CANCELCONFIRMTIME,
    CANCELCONFIRMDATE,CANCELBOREMARKS,    CANCELDEALERREMARKS,    CANCELOURDEALERNAME,
    CANCELTHEIRDEALERNAME,CancelEnteredBy, CASHFLOWDATE, NULL USERREFERENCE  FROM vewReportFuture;