CREATE TABLE "TEST_VSTSRedgate".trtran062 (
  cfmr_company_code NUMBER(8) NOT NULL,
  cfmr_deal_number VARCHAR2(25 BYTE) NOT NULL,
  cfmr_serial_number NUMBER(5) NOT NULL,
  cfmr_mtm_date DATE NOT NULL,
  cfmr_mtm_rate NUMBER(15,6),
  cfmr_profit_loss NUMBER(15,2),
  cfmr_margin_amount NUMBER(15,2),
  cfmr_create_date DATE NOT NULL,
  cfmr_entry_detail XMLTYPE,
  cfmr_record_status NUMBER(8) NOT NULL,
  cfmr_mtm_user VARCHAR2(25 BYTE),
  cfmr_pl_voucher VARCHAR2(25 BYTE),
  cfmr_mtm_amount NUMBER(15,2),
  cfmr_margin_excess NUMBER(15,2),
  cfmr_location_code NUMBER(8),
  CONSTRAINT trtran062_pk PRIMARY KEY (cfmr_company_code,cfmr_deal_number,cfmr_serial_number,cfmr_mtm_date)
);