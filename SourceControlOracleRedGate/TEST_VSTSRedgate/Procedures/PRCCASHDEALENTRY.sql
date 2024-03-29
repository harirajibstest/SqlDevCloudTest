CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCCASHDEALENTRY" 
(FrmDate  Date ,RefferenceNo  Varchar,CashRate  number,AmountFcy  number,WorkDate  date)
as
    DealNumber      varchar (25 byte);
    numCode1        number  (8)      ;
    varTemp         varchar (50 Byte);
    numCode         number  (8)      ;
    CompanyCode     varchar (15 byte);
    BuySell         Varchar (10 byte);
    BuysellCode     number  (8)      ;
    UserID          varchar (10 byte);
begin
    for Cur_Trade in(Select * from trtran002 where TRAD_TRADE_REFERENCE = RefferenceNo)
    loop
    CompanyCode :=  ''||pkgreturncursor.fncgetdescription(Cur_Trade.TRAD_COMPANY_CODE,2)||'';
    If Cur_Trade.TRAD_IMPORT_EXPORT > 25900000 then
        BuySell := 'B/';
        BuysellCode := 25300001;
    else
        BuySell := 'S/';
        BuysellCode := 25300002;
    end if;
    UserID := 'Chan123';
    varTemp :=  CompanyCode || '/CSH/'|| 'H/'||BuySell;
    varTemp := varTemp  || PKGGLOBALMETHODS.fncGenerateSerial(10900014, Cur_Trade.TRAD_COMPANY_CODE);
    Insert Into trtran001 
    (DEAL_COMPANY_CODE,DEAL_DEAL_NUMBER,DEAL_SERIAL_NUMBER,DEAL_EXECUTE_DATE,DEAL_HEDGE_TRADE,DEAL_BUY_SELL,DEAL_SWAP_OUTRIGHT,
    DEAL_DEAL_TYPE,DEAL_COUNTER_PARTY,DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_EXCHANGE_RATE,DEAL_LOCAL_RATE,DEAL_BASE_AMOUNT,
    DEAL_OTHER_AMOUNT,DEAL_AMOUNT_LOCAL,DEAL_MATURITY_CODE,DEAL_MATURITY_FROM,DEAL_MATURITY_DATE,DEAL_MATURITY_MONTH,DEAL_USER_ID,
    DEAL_CONFIRM_DATE,DEAL_DEALER_REMARKS,DEAL_TIME_STAMP,
    DEAL_EXECUTE_TIME,DEAL_CONFIRM_TIME,DEAL_PROCESS_COMPLETE,DEAL_COMPLETE_DATE,DEAL_CREATE_DATE,DEAL_ENTRY_DETAIL,DEAL_RECORD_STATUS,
    DEAL_USER_REFERENCE,DEAL_FIXED_OPTION,DEAL_DELIVARY_NO,DEAL_FORWARD_RATE,DEAL_SPOT_RATE,DEAL_MARGIN_RATE,
    DEAL_BACKUP_DEAL,DEAL_STOP_LOSS,DEAL_TAKE_PROFIT,DEAL_INIT_CODE,DEAL_BANK_REFERENCE,
    DEAL_BO_REMARK)
    Values
    (Cur_Trade.TRAD_COMPANY_CODE,varTemp,1,WorkDate,26000001,BuysellCode,25200002,25400001,Cur_Trade.TRAD_LOCAL_BANK,Cur_Trade.TRAD_TRADE_CURRENCY ,30400003,CashRate,
    AmountFcy,AmountFcy*CashRate,0,0,0,FrmDate,FrmDate,0,UserID,FrmDate,'Cash Deal',null,null,null,
    12400001,FrmDate,FrmDate,Null,10200001,'Cash Deal',0,0,null,null,null,0,0,0,0,null,null);
    Insert Into trtran004
    (HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,HEDG_DEAL_NUMBER,HEDG_DEAL_SERIAL,HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,
    HEDG_CREATE_DATE,HEDG_ENTRY_DETAIL,HEDG_RECORD_STATUS,HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY)
    Values
    (Cur_Trade.TRAD_COMPANY_CODE,RefferenceNo,varTemp,1,AmountFcy,AmountFcy*CashRate,0,FrmDate,null,10200001,32200001,12400002);
    Insert Into trtran006
    (
    CDEL_COMPANY_CODE,CDEL_DEAL_NUMBER,CDEL_DEAL_SERIAL,CDEL_REVERSE_SERIAL,CDEL_TRADE_REFERENCE,CDEL_TRADE_SERIAL,
    CDEL_CANCEL_DATE,CDEL_DEAL_TYPE,CDEL_CANCEL_TYPE,CDEL_CANCEL_AMOUNT,CDEL_CANCEL_RATE,CDEL_OTHER_AMOUNT,CDEL_LOCAL_RATE,
    CDEL_CANCEL_INR,CDEL_HOLDING_RATE,CDEL_HOLDING_RATE1,CDEL_DEALER_HOLDING,CDEL_DEALER_HOLDING1,CDEL_PROFIT_LOSS,
    CDEL_USER_ID,CDEL_DEALER_REMARK,CDEL_TIME_STAMP,CDEL_CREATE_DATE,CDEL_ENTRY_DETAIL,CDEL_RECORD_STATUS,CDEL_PL_VOUCHER,
    CDEL_DELIVERY_FROM,CDEL_DELIVERY_SERIAL,CDEL_FORWARD_RATE,CDEL_SPOT_RATE,CDEL_MARGIN_RATE,CDEL_PANDL_SPOT,
    CDEL_PANDL_USD,CDEL_CANCEL_REASON,CDEL_CONFIRM_TIME,CDEL_CONFIRM_DATE,CDEL_BANK_REFERENCE,CDEL_BO_REMARK)
    Values
    (Cur_Trade.TRAD_COMPANY_CODE,varTemp,1,1,RefferenceNo,0,FrmDate,26000001,27000002,AmountFcy,CashRate,AmountFcy*CashRate,1,AmountFcy*1,
    0,0,0,0,0,UserID,Cur_Trade.TRAD_LOCAL_BANK,null,FrmDate,null,10200001,Null,Null,Null,Null,Null,0,0,33500001,null,FrmDate,null,null,null
    );
  end loop;
end PrcCashDealEntry;
/