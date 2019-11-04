CREATE TABLE "TEST_VSTSRedgate".trtran011_archive (
  rdel_company_code NUMBER(8) NOT NULL,
  rdel_risk_reference VARCHAR2(15 BYTE) NOT NULL,
  rdel_deal_number VARCHAR2(25 BYTE) NOT NULL,
  rdel_serial_number NUMBER(5) NOT NULL,
  rdel_risk_type NUMBER(8) NOT NULL,
  rdel_risk_date DATE NOT NULL,
  rdel_limit_usd NUMBER(15,2),
  rdel_amount_excess NUMBER(15,2),
  rdel_action_taken NUMBER(8),
  rdel_stake_holder VARCHAR2(500 BYTE),
  rdel_mobile_number VARCHAR2(15 BYTE),
  rdel_email_id VARCHAR2(2000 BYTE),
  rdel_message_text VARCHAR2(1000 BYTE),
  rdel_sent_status NUMBER(8),
  rdel_sent_timestamp VARCHAR2(25 BYTE),
  rdel_record_status NUMBER(8),
  rdel_create_date DATE,
  rdel_entry_detail XMLTYPE,
  rdel_cal_usd NUMBER(15,2),
  rdel_cal_local NUMBER(15,2),
  rdel_cal_percent NUMBER(15,2),
  rdel_limit_local NUMBER(15,2),
  rdel_limit_percent NUMBER(15,2),
  rdel_limit_fcy NUMBER(15,2),
  rdel_cal_fcy NUMBER(15,2),
  rdel_location_code NUMBER(8),
  rdel_product_code NUMBER(8),
  rdel_subproduct_code NUMBER(8),
  rdel_currency_product NUMBER(8),
  rdel_action_type NUMBER(8),
  rdel_insert_serial NUMBER(5)
);