CREATE TABLE "TEST_VSTSRedgate".trtran012d (
  vols_effective_date DATE NOT NULL,
  vols_base_currency NUMBER(8) NOT NULL,
  vols_other_currency NUMBER(8) NOT NULL,
  vols_surface_type NUMBER(8) NOT NULL,
  vols_rate_valid DATE NOT NULL,
  vols_rate_validstring VARCHAR2(25 BYTE) NOT NULL,
  vols_surface_level NUMBER(5) NOT NULL,
  vols_vols_buyrate NUMBER(15,6),
  vols_vols_sellrate NUMBER(15,6),
  vols_serial_number NUMBER(5) NOT NULL,
  vols_record_status NUMBER(8),
  vols_entry_date DATE,
  vols_create_date DATE,
  CONSTRAINT trtran012d_pk PRIMARY KEY (vols_effective_date,vols_base_currency,vols_other_currency,vols_surface_type,vols_rate_valid,vols_rate_validstring,vols_surface_level,vols_serial_number)
);