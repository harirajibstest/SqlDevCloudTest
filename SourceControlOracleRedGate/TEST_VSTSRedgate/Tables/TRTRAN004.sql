CREATE TABLE "TEST_VSTSRedgate".trtran004 (
  hedg_company_code NUMBER(8) NOT NULL,
  hedg_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  hedg_deal_number VARCHAR2(25 BYTE) NOT NULL,
  hedg_deal_serial NUMBER(5) NOT NULL,
  hedg_hedged_fcy NUMBER(15,2) NOT NULL,
  hedg_other_fcy NUMBER(15,2),
  hedg_hedged_inr NUMBER(15,2),
  hedg_create_date DATE NOT NULL,
  hedg_entry_detail XMLTYPE,
  hedg_record_status NUMBER(8) NOT NULL,
  hedg_hedging_with NUMBER(8),
  hedg_multiple_currency NUMBER(8),
  hedg_location_code NUMBER(8),
  hedg_linked_date DATE,
  hedg_trade_serial NUMBER(5) DEFAULT 1 NOT NULL,
  hedg_batch_number VARCHAR2(25 BYTE),
  hedg_rollover_reference VARCHAR2(25 BYTE),
  CONSTRAINT pk_trtran0041 PRIMARY KEY (hedg_company_code,hedg_trade_reference,hedg_deal_number,hedg_deal_serial,hedg_trade_serial)
);