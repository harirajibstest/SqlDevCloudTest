CREATE TABLE "TEST_VSTSRedgate".trtran004a (
  hgco_company_code NUMBER(8) NOT NULL,
  hgco_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  hgco_deal_number VARCHAR2(25 BYTE) NOT NULL,
  hgco_deal_serial NUMBER(5) NOT NULL,
  hgco_hedged_qty NUMBER(15,2) NOT NULL,
  hgco_hedged_amt NUMBER(15,2),
  hgco_create_date DATE NOT NULL,
  hgco_add_date DATE,
  hgco_entry_detail XMLTYPE,
  hgco_record_status NUMBER(8) NOT NULL,
  hgco_hedging_with NUMBER(8),
  hgco_multiple_currency NUMBER(8),
  CONSTRAINT pk_trtran004a PRIMARY KEY (hgco_company_code,hgco_trade_reference,hgco_deal_number,hgco_deal_serial)
);