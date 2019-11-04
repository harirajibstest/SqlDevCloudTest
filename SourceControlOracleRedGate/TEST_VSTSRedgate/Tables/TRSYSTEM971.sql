CREATE TABLE "TEST_VSTSRedgate".trsystem971 (
  csmt_statement_date DATE NOT NULL,
  csmt_company_code NUMBER(8) NOT NULL,
  csmt_local_bank NUMBER(8) NOT NULL,
  csmt_serial_number NUMBER(5) NOT NULL,
  csmt_account_number VARCHAR2(25 BYTE),
  csmt_transaction_date DATE,
  csmt_cheque_number VARCHAR2(10 BYTE),
  csmt_debit_amount NUMBER(15,2),
  csmt_credit_amount NUMBER(15,2),
  csmt_balance_amount NUMBER(15,2),
  csmt_voucher_detail VARCHAR2(100 BYTE),
  csmt_merchant_code NUMBER(8)
);