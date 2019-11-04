CREATE TABLE "TEST_VSTSRedgate".trsystem993 (
  csmt_statement_date DATE,
  csmt_company_code NUMBER(8),
  csmt_local_bank NUMBER(8),
  csmt_serial_number NUMBER(5),
  csmt_account_number VARCHAR2(25 BYTE),
  csmt_transaction_date DATE,
  csmt_cheque_number VARCHAR2(10 BYTE),
  csmt_debit_amount NUMBER(15,4),
  csmt_credit_amount NUMBER(15,4),
  csmt_balance_amount NUMBER(15,2),
  csmt_voucher_detail VARCHAR2(100 BYTE),
  csmt_recon_inr NUMBER(15,2),
  csmt_recon_date DATE,
  bcac_recon_flag NUMBER(8),
  csmt_recon_remarks VARCHAR2(100 BYTE)
);