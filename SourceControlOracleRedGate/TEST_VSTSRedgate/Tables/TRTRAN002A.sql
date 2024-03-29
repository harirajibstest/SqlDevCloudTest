CREATE TABLE "TEST_VSTSRedgate".trtran002a (
  unln_company_code NUMBER(8) NOT NULL,
  unln_effective_date DATE NOT NULL,
  unln_aandl_code NUMBER(8) NOT NULL,
  unln_line_item VARCHAR2(1 BYTE) NOT NULL,
  unln_forward_months NUMBER(2),
  unln_currency_code NUMBER(8),
  unln_base_amount NUMBER(15,2),
  unln_spot_rate NUMBER(15,6),
  unln_forward_rate NUMBER(15,6),
  unln_margin_rate NUMBER(15,6),
  unln_exchange_rate NUMBER(15,6),
  unln_due_date DATE,
  unln_trade_reference VARCHAR2(25 BYTE),
  unln_process_complete NUMBER(8),
  unln_complete_date DATE,
  unln_create_date DATE NOT NULL,
  unln_add_date DATE NOT NULL,
  unln_entry_detail XMLTYPE,
  unln_record_status NUMBER(8),
  CONSTRAINT pk_trtran002a PRIMARY KEY (unln_company_code,unln_effective_date,unln_aandl_code,unln_line_item)
);