CREATE TABLE "TEST_VSTSRedgate".report_fxforcast_preyear (
  displayorder NUMBER(2),
  status VARCHAR2(50 BYTE),
  companycode NUMBER(8),
  maturitymonth VARCHAR2(20 BYTE),
  maturitymonthdate VARCHAR2(20 BYTE),
  currencycode NUMBER(8),
  amountfcy NUMBER(20,6),
  amountlocal NUMBER(20,6),
  datatype VARCHAR2(50 BYTE)
);