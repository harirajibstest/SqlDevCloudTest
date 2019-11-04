CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewrealizedpandlrepfur (company,dealnumber,dealtype,refno,counterparty,initiator,trader,buysell,currency,maturitydate,executedate,strikerate,canceldate,cancelrate,cancleamount,realizedpandl,washrate,cancleamtinr,remarks) AS
SELECT Company,
    Dealnumber,
    Dealtype,
    Refno,
    Counterparty,
    Initiator,
    Trader,
    Buysell,
    Currency,
    Maturitydate,
    Executedate,
    Strikerate,
    Canceldate,
    Cancelrate,
    Cancleamount,
    Realizedpandl,
    Washrate,
    Cancleamtinr,
    Remarks

  FROM
    (SELECT Pkgreturncursor.Fncgetdescription(Cfut_Company_Code,2) AS Company,
      Cfut_Deal_Number                                             AS Dealnumber,
      'Future' Dealtype,
      Cfut_User_Reference                                     AS Refno,
      Pkgreturncursor.Fncgetdescription(Cfut_Counter_Party,2) AS Counterparty,
      Pkgreturncursor.Fncgetdescription(Cfut_Backup_Deal,2)   AS Initiator,
      Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2)     AS Trader,
      Pkgreturncursor.Fncgetdescription(Cfut_Buy_Sell,2)      AS Buysell,
      Pkgreturncursor.Fncgetdescription(Cfut_Base_Currency,2)
      ||'/'
      || Pkgreturncursor.Fncgetdescription(Cfut_Other_Currency,2) AS Currency,
      Cfut_Maturity_Date                                          AS Maturitydate,
      Cfut_Execute_Date                                           AS Executedate,
      Cfut_Exchange_Rate                                          AS Strikerate,
      Cfrv_Execute_Date Canceldate,
      Cfrv_Lot_Price Cancelrate,
      Cfrv_Cancel_Amount Cancleamount,
      Cfrv_Profit_Loss Realizedpandl,
      Cfrv_Lot_Price Washrate,
      (Cfrv_Cancel_Amount * Cfrv_Lot_Price) AS Cancleamtinr,
      DECODE (Cfut_Record_Status,10200001,'unconfirmed',10200003,'Confirmed',10200002,'first Confi') Remarks
    FROM trtran061,
      trtran063
    WHERE Cfut_Deal_Number      =Cfrv_Deal_Number
    AND Cfrv_Record_Status NOT IN(10200005,10200006)
    AND Cfut_Record_Status NOT IN(10200005,10200006)
    UNION
    SELECT Pkgreturncursor.Fncgetdescription(DEAL_COMPANY_CODE,2) AS Company,
      Deal_Deal_Number                                            AS Dealnumber,
      'Forward' Dealtype,
      Deal_User_Reference                                     AS Refno,
      Pkgreturncursor.Fncgetdescription(Deal_Counter_Party,2) AS Counterparty,
      Pkgreturncursor.Fncgetdescription(Deal_Backup_Deal,2)   AS Initiator,
      Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2)     AS Trader,
      Pkgreturncursor.Fncgetdescription(Deal_Buy_Sell,2)      AS Buysell,
      Pkgreturncursor.Fncgetdescription(Deal_Base_Currency,2)
      ||'/'
      || Pkgreturncursor.Fncgetdescription(Deal_Other_Currency,2) AS Currency,
      Deal_Maturity_Date                                          AS Maturitydate,
      Deal_Execute_Date                                           AS Executedate,
      Deal_Exchange_Rate                                          AS Strikerate,
      Cdel_Cancel_Date Canceldate,
      Cdel_Cancel_Rate Cancelrate,
      Cdel_Cancel_Amount Cancleamount,
      Cdel_Profit_Loss Realizedpandl,
      Cdel_Local_Rate Washrate,
      (Cdel_Cancel_Amount * Cdel_Cancel_Rate) AS Cancleamtinr,
      DECODE (Deal_Record_Status,10200001,'unconfirmed',10200003,'Confirmed',10200002,'first Confi') Remarks
    FROM Trtran001,
      Trtran006
    WHERE Deal_Deal_Number      =Cdel_Deal_Number
    AND Deal_Record_Status NOT IN(10200005,10200006)
    AND Cdel_Record_Status NOT IN(10200005,10200006)
    )
  ORDER BY Dealnumber
 
 
 
 ;