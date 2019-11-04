CREATE TABLE "TEST_VSTSRedgate".trtran053 (
  crev_company_code NUMBER(8) NOT NULL,
  crev_deal_number VARCHAR2(25 BYTE) NOT NULL,
  crev_reverse_deal VARCHAR2(25 BYTE) NOT NULL,
  crev_reverse_lot NUMBER(5) NOT NULL,
  crev_create_date DATE,
  crev_record_status NUMBER(8),
  crev_profit_loss NUMBER(15,2),
  crev_pl_voucher VARCHAR2(25 BYTE),
  crev_execute_date DATE,
  crev_serial_number NUMBER(5),
  crev_reverse_serial NUMBER(5),
  crev_lot_price NUMBER(15,4)
);