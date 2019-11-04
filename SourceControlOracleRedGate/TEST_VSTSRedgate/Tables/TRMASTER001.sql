CREATE TABLE "TEST_VSTSRedgate".trmaster001 (
  pick_company_code NUMBER(8) NOT NULL,
  pick_key_group NUMBER(3) NOT NULL,
  pick_key_number NUMBER(5) NOT NULL,
  pick_key_value NUMBER(8) NOT NULL,
  pick_short_description VARCHAR2(15 BYTE) NOT NULL,
  pick_long_description VARCHAR2(50 BYTE) NOT NULL,
  pick_key_type NUMBER(8) NOT NULL,
  pick_remarks VARCHAR2(500 BYTE),
  pick_entry_detail XMLTYPE,
  pick_record_status NUMBER(8) NOT NULL,
  pick_sap_code VARCHAR2(50 BYTE),
  pick_location_code NUMBER(8)
);