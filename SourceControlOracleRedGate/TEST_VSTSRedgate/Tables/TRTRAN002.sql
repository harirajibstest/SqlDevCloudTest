CREATE TABLE "TEST_VSTSRedgate".trtran002 (
  trad_company_code NUMBER(8) NOT NULL,
  trad_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  trad_reverse_reference VARCHAR2(100 BYTE),
  trad_reverse_serial NUMBER(5),
  trad_import_export NUMBER(8) NOT NULL,
  trad_local_bank NUMBER(8),
  trad_entry_date DATE NOT NULL,
  trad_user_reference VARCHAR2(1000 BYTE),
  trad_reference_date DATE,
  trad_buyer_seller NUMBER(8),
  trad_trade_currency NUMBER(8) NOT NULL,
  trad_product_code NUMBER(8),
  trad_product_description VARCHAR2(200 BYTE),
  trad_trade_fcy NUMBER(15,2) NOT NULL,
  trad_trade_rate NUMBER(15,6) NOT NULL,
  trad_trade_inr NUMBER(15,2) NOT NULL,
  trad_period_code NUMBER(8),
  trad_trade_period NUMBER(5),
  trad_tenor_code NUMBER(8),
  trad_tenor_period NUMBER(5),
  trad_maturity_from DATE,
  trad_maturity_date DATE,
  trad_process_complete NUMBER(8) DEFAULT 12400002,
  trad_complete_date DATE,
  trad_trade_remarks VARCHAR2(4000 BYTE),
  trad_create_date DATE NOT NULL,
  trad_entry_detail XMLTYPE,
  trad_record_status NUMBER(8) NOT NULL,
  trad_vessel_name VARCHAR2(500 BYTE),
  trad_port_name VARCHAR2(500 BYTE),
  trad_beneficiary VARCHAR2(50 BYTE),
  trad_usance VARCHAR2(50 BYTE),
  trad_bill_date DATE,
  trad_contract_no VARCHAR2(50 BYTE),
  trad_app VARCHAR2(50 BYTE),
  trad_transaction_type NUMBER(8),
  trad_product_quantity NUMBER(15,3),
  trad_product_rate NUMBER(15,4),
  trad_term NUMBER(8),
  trad_voyage VARCHAR2(100 BYTE),
  trad_link_batchno VARCHAR2(25 BYTE),
  trad_link_date DATE,
  trad_lc_beneficiary VARCHAR2(100 BYTE),
  trad_forward_rate NUMBER(15,6),
  trad_margin_rate NUMBER(15,6),
  trad_spot_rate NUMBER(15,6),
  trad_subproduct_code NUMBER(8),
  trad_product_category NUMBER(8),
  trad_add_date DATE,
  trad_location_code NUMBER(8),
  trad_uom_code NUMBER(8),
  trad_price_type NUMBER(8),
  trad_local_currency NUMBER(8),
  trad_destination_port VARCHAR2(500 BYTE),
  trad_rate_type NUMBER(8),
  CONSTRAINT pk_trtran002 PRIMARY KEY (trad_company_code,trad_trade_reference)
);