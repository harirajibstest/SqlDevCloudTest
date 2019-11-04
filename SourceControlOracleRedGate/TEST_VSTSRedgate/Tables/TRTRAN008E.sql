CREATE TABLE "TEST_VSTSRedgate".trtran008e (
  srno NUMBER(5),
  reversal_receipt_number VARCHAR2(30 BYTE),
  "TYPE" VARCHAR2(40 BYTE),
  receipt_number VARCHAR2(30 BYTE),
  line_number NUMBER(5),
  receipt_date DATE,
  gl_date DATE,
  "NAME" VARCHAR2(50 BYTE),
  debit_credit_flag VARCHAR2(2 BYTE),
  receipt_amount NUMBER(15,2),
  receivable_activity VARCHAR2(50 BYTE),
  account_code VARCHAR2(40 BYTE),
  bank_name VARCHAR2(360 BYTE),
  branch_name VARCHAR2(360 BYTE),
  ifsc_code VARCHAR2(15 BYTE),
  bank_account_number VARCHAR2(30 BYTE),
  currency_code VARCHAR2(15 BYTE),
  exchange_rate NUMBER(15,2),
  exchange_date DATE,
  record_status VARCHAR2(40 BYTE),
  error_message VARCHAR2(2000 BYTE),
  attribute1 VARCHAR2(150 BYTE),
  attribute2 VARCHAR2(150 BYTE),
  attribute3 VARCHAR2(150 BYTE),
  last_updated_by NUMBER(15),
  last_update_date DATE,
  last_update_login NUMBER(15),
  created_by NUMBER(15),
  creation_date DATE,
  cash_receipt_id NUMBER(15),
  receipt_method_id NUMBER(15),
  activity_id NUMBER(15)
);