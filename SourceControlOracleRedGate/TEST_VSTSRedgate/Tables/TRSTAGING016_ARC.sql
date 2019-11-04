CREATE TABLE "TEST_VSTSRedgate".trstaging016_arc (
  transactiontype NVARCHAR2(100),
  bank NVARCHAR2(100),
  referencedate VARCHAR2(20 BYTE),
  amountfcy NUMBER(15,6),
  maturitydate VARCHAR2(20 BYTE),
  contractnumber VARCHAR2(100 BYTE),
  buyer_seller VARCHAR2(200 BYTE),
  currency NVARCHAR2(100),
  userreference VARCHAR2(100 BYTE),
  exchangerate NUMBER(15,6),
  company VARCHAR2(100 BYTE),
  "LOCATION" VARCHAR2(100 BYTE),
  product VARCHAR2(100 BYTE),
  subproduct VARCHAR2(100 BYTE),
  guid VARCHAR2(50 BYTE),
  rowno NUMBER(5),
  processstatus NUMBER(8),
  remarks VARCHAR2(4000 BYTE),
  sysreferencenumber VARCHAR2(25 BYTE),
  bank_code NUMBER(8),
  currency_code NUMBER(8),
  company_code NUMBER(8),
  location_code NUMBER(8),
  product_code NUMBER(8),
  subproduct_code NUMBER(8),
  transactiontype_code NUMBER(8),
  buyer_seller_code NUMBER(8)
);