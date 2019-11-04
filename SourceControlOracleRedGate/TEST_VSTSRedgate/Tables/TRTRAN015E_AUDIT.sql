CREATE TABLE "TEST_VSTSRedgate".trtran015e_audit (
  chga_company_code NUMBER(8) NOT NULL,
  chga_bank_code NUMBER(8) NOT NULL,
  chga_effective_date DATE NOT NULL,
  chga_charge_type NUMBER(8) NOT NULL,
  chga_charging_event NUMBER(8) NOT NULL,
  chga_sanction_applied VARCHAR2(30 BYTE) NOT NULL,
  chga_screen_name VARCHAR2(50 BYTE) NOT NULL,
  chga_create_date DATE,
  chga_entry_detail XMLTYPE,
  chga_record_status NUMBER(8),
  chga_currency_code NUMBER(8) NOT NULL,
  chga_limit_type NUMBER(8) NOT NULL,
  chga_location_code NUMBER(8),
  chga_lob_code NUMBER(8),
  chga_ref_number VARCHAR2(25 BYTE)
);