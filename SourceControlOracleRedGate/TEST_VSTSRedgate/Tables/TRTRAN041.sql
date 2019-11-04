CREATE TABLE "TEST_VSTSRedgate".trtran041 (
  bint_company_code NUMBER(8) NOT NULL,
  bint_local_bank NUMBER(8) NOT NULL,
  bint_base_type NUMBER(8) NOT NULL,
  bint_serial_number NUMBER(5) NOT NULL,
  bint_effective_date DATE NOT NULL,
  bint_interest_rate NUMBER(15,6) NOT NULL,
  bint_create_date DATE NOT NULL,
  bint_entry_detail XMLTYPE,
  bint_record_status NUMBER(8) NOT NULL
);