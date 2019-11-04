CREATE TABLE "TEST_VSTSRedgate".trsystem051 (
  prmc_effective_date DATE NOT NULL,
  prmc_company_name VARCHAR2(50 BYTE) NOT NULL,
  prmc_address_1 VARCHAR2(50 BYTE) NOT NULL,
  prmc_address_2 VARCHAR2(50 BYTE),
  prmc_address_3 VARCHAR2(50 BYTE),
  prmc_address_4 VARCHAR2(50 BYTE),
  prmc_phone_number VARCHAR2(200 BYTE),
  prmc_fax_number VARCHAR2(200 BYTE),
  prmc_email_id VARCHAR2(100 BYTE),
  prmc_sms_number VARCHAR2(15 BYTE),
  prmc_sms_port VARCHAR2(5 BYTE),
  prmc_sms_baudrate NUMBER(10),
  prmc_mail_userid VARCHAR2(50 BYTE),
  prmc_password_key VARCHAR2(200 BYTE),
  prmc_password_code VARCHAR2(200 BYTE),
  prmc_smtp_server VARCHAR2(50 BYTE),
  prmc_smtp_port NUMBER(10),
  prmc_mail_user VARCHAR2(50 BYTE),
  prmc_create_date DATE,
  prmc_add_date DATE,
  prmc_entry_detail XMLTYPE,
  prmc_record_status NUMBER(8),
  prmc_treasury_module NUMBER(8),
  prmc_money_module NUMBER(8),
  prmc_commodity_currency NUMBER(8),
  prmc_service_tax NUMBER(5,2),
  prmc_expire_date DATE,
  prmc_expired_yesno NUMBER,
  prmc_order_linking_onhedgedeal NUMBER(8),
  prmc_currency_futures NUMBER(8),
  prmc_derivatives_module NUMBER(8),
  prmc_programupdate_folder VARCHAR2(100 BYTE),
  prmc_benchmark_percent NUMBER(5,2),
  prmc_order_linking_futuredeal NUMBER(8),
  prmc_order_linking_optiondeal NUMBER(8),
  prmc_report_date DATE,
  prmc_report_type VARCHAR2(25 BYTE),
  prmc_tradefinance_link NUMBER(8),
  prmc_letter_printing NUMBER(8),
  prmc_voucher_pass NUMBER(8),
  prmc_convert_amountinto NUMBER(15),
  prmc_wallet_path VARCHAR2(500 BYTE),
  prmc_wallet_pswd VARCHAR2(25 BYTE),
  prmc_tls_connect NUMBER(8),
  prmc_smtp_domain VARCHAR2(100 BYTE),
  CONSTRAINT pk_trsystem050 PRIMARY KEY (prmc_effective_date)
);