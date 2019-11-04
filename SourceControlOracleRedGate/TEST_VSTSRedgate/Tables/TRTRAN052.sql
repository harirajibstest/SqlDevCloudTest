CREATE TABLE "TEST_VSTSRedgate".trtran052 (
  cmtr_company_code NUMBER(8) NOT NULL,
  cmtr_deal_number VARCHAR2(25 BYTE) NOT NULL,
  cmtr_serial_number NUMBER(5) NOT NULL,
  cmtr_mtm_date DATE NOT NULL,
  cmtr_mtm_rate NUMBER(15,2),
  cmtr_profit_loss NUMBER(15,2),
  cmtr_margin_amount NUMBER(15,2),
  cmtr_create_date DATE NOT NULL,
  cmtr_entry_detail XMLTYPE,
  cmtr_record_status NUMBER(8) NOT NULL,
  cmtr_mtm_user NUMBER(15,2),
  cmtr_pl_voucher VARCHAR2(25 BYTE),
  cmtr_mtm_amount NUMBER(15,2),
  cmtr_margin_excess NUMBER(15,2),
  CONSTRAINT trtran052_pk PRIMARY KEY (cmtr_company_code,cmtr_deal_number,cmtr_serial_number,cmtr_mtm_date)
);