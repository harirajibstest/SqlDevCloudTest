CREATE TABLE "TEST_VSTSRedgate".trstaging016 (
  transactiontype NVARCHAR2(100),
  bank NVARCHAR2(100),
  referencedate VARCHAR2(50 BYTE),
  amountfcy NUMBER(15,6),
  maturitydate VARCHAR2(50 BYTE),
  contractnumber VARCHAR2(100 BYTE),
  buyer_seller VARCHAR2(200 BYTE),
  currency NVARCHAR2(100),
  userreference VARCHAR2(100 BYTE),
  exchangerate NUMBER(15,6),
  company VARCHAR2(100 BYTE),
  "LOCATION" VARCHAR2(100 BYTE),
  product VARCHAR2(100 BYTE),
  subproduct VARCHAR2(100 BYTE),
  guid VARCHAR2(50 BYTE)
);