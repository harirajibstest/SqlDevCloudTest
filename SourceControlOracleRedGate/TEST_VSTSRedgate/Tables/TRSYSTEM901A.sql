CREATE TABLE "TEST_VSTSRedgate".trsystem901a (
  sapo_file_name VARCHAR2(25 BYTE),
  sapo_voucher_date DATE,
  sapo_voucher_reference VARCHAR2(25 BYTE),
  sapo_voucher_serial NUMBER(5),
  sapo_voucher_event NUMBER(8),
  sapo_local_bank NUMBER(8),
  sapo_format_types VARCHAR2(50 BYTE),
  sapo_time_stamp VARCHAR2(25 BYTE),
  sapo_package_name VARCHAR2(30 BYTE),
  sapo_error_text VARCHAR2(4000 BYTE),
  sapo_credit_total NUMBER(15,4),
  sapo_debit_total NUMBER(15,4),
  sapo_process_complete NUMBER(8),
  sapo_completion_date DATE,
  sapo_add_date DATE,
  sapo_emailsent_yesno NUMBER(8)
);