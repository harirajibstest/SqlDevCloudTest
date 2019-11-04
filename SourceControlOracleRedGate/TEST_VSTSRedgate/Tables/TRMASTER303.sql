CREATE TABLE "TEST_VSTSRedgate".trmaster303 (
  ctry_company_code NUMBER(8) NOT NULL,
  ctry_pick_code NUMBER(8) NOT NULL,
  ctry_short_description VARCHAR2(15 BYTE) NOT NULL,
  ctry_long_description VARCHAR2(50 BYTE) NOT NULL,
  ctry_currency_code NUMBER(8) NOT NULL,
  ctry_region_code NUMBER(8) NOT NULL,
  ctry_create_date DATE NOT NULL,
  ctry_add_date DATE NOT NULL,
  ctry_entry_detail XMLTYPE,
  ctry_record_status NUMBER(8) NOT NULL,
  ctry_location_code NUMBER(8)
);