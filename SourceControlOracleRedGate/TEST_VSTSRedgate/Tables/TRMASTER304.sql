CREATE TABLE "TEST_VSTSRedgate".trmaster304 (
  cncy_company_code NUMBER(8) NOT NULL,
  cncy_pick_code NUMBER(8) NOT NULL,
  cncy_short_description VARCHAR2(15 BYTE) NOT NULL,
  cncy_long_description VARCHAR2(50 BYTE) NOT NULL,
  cncy_decimal_name VARCHAR2(15 BYTE) NOT NULL,
  cncy_decimal_amount NUMBER(1) NOT NULL,
  cncy_decimal_rate NUMBER(1) NOT NULL,
  cncy_traded_yn NUMBER(8) NOT NULL,
  cncy_principal_yn NUMBER(8) NOT NULL,
  cncy_units_dealt NUMBER(5) NOT NULL,
  cncy_fluctuation_allowed NUMBER(15,6),
  cncy_add_date DATE NOT NULL,
  cncy_create_date DATE NOT NULL,
  cncy_entry_detail XMLTYPE,
  cncy_record_status NUMBER(8) NOT NULL,
  cncy_location_code NUMBER(8)
);