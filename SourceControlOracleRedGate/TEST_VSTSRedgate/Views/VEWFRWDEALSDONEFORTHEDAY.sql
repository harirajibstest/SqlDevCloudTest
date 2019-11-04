CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfrwdealsdonefortheday (company,dealnumber,dealtype,refno,counterparty,initiator,trader,buysell,currency,maturitydate,executedate,bookcancamount,bookingrate,bookcancrate,pandl,washrate,status) AS
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
    Baseamount,
    "BookCancAmount",
    "BookCancRate",
    Pandl,
    Washrate,
    Status
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
      Cfut_Base_Amount                                            AS BaseAmount,
      Cfut_Exchange_Rate "BookCancAmount",
      Cfut_Exchange_Rate "BookCancRate",
      1 Pandl,
      1 Washrate,
      'booked' Status
    FROM Trtran061
    WHERE Cfut_Record_Status NOT IN(10200005,10200006)
    UNION
    SELECT Pkgreturncursor.Fncgetdescription(Cfut_Company_Code,2) AS Company,
      Cfut_Deal_Number                                            AS Dealnumber,
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
      Cfrv_Execute_Date                                           AS Executedate,
      Cfrv_Cancel_Amount "BookCancAmount",
      Cfut_Exchange_Rate AS Bookingrate,
      Cfrv_Lot_Price "BookCancRate",
      Cfrv_Profit_Loss Pandl,
      Cfrv_Lot_Price Washrate,
      'Canceled' Status
    FROM Trtran061,
      Trtran063
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
      Deal_Base_Amount                                            AS BaseAmount,
      Deal_Exchange_Rate "BookCancAmount",
      Deal_Exchange_Rate "BookCancRate",
      1 Pandl,
      1 Washrate,
      'Booked' Status
    FROM Trtran001
    WHERE Deal_Record_Status NOT IN(10200005,10200006)
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
      Cdel_Cancel_Date                                            AS Executedate,
      Cdel_Cancel_Amount "BaseAmount",
      Deal_Exchange_Rate "BookCancAmount",
      Cdel_Cancel_Rate "BookCancRate",
      Cdel_Profit_Loss PandL,
      Cdel_Local_Rate Washrate,
      CASE Cdel_Cancel_Type
        WHEN 27000001
        THEN 'Cancelled'
        WHEN 27000002
        THEN 'Delivery'
      END AS Status
    FROM Trtran001,
      Trtran006
    WHERE Deal_Deal_Number      =Cdel_Deal_Number
    AND Deal_Record_Status NOT IN(10200005,10200006)
    AND Cdel_Record_Status NOT IN(10200005,10200006)
    )
  ORDER BY Dealnumber
 
 
 
 ;