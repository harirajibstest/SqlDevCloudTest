CREATE TABLE "TEST_VSTSRedgate".trtran015e (
  chga_company_code NUMBER(8) NOT NULL,
  chga_bank_code NUMBER(8) NOT NULL,
  chga_effective_date DATE NOT NULL,
  chga_charge_type NUMBER(8) NOT NULL,
  chga_charging_event NUMBER(8),
  chga_sanction_applied VARCHAR2(30 BYTE) NOT NULL,
  chga_screen_name VARCHAR2(50 BYTE) NOT NULL,
  chga_create_date DATE,
  chga_entry_detail XMLTYPE,
  chga_record_status NUMBER(8),
  chga_currency_code NUMBER(8) NOT NULL,
  chga_limit_type NUMBER(8) NOT NULL,
  chga_location_code NUMBER(8),
  chga_lob_code NUMBER(8),
  chga_ref_number VARCHAR2(25 BYTE),
  CONSTRAINT trtran015e_pk PRIMARY KEY (chga_company_code,chga_bank_code,chga_effective_date,chga_sanction_applied,chga_limit_type,chga_currency_code,chga_screen_name,chga_charge_type)
);