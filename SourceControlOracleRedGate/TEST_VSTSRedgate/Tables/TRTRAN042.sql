CREATE TABLE "TEST_VSTSRedgate".trtran042 (
  intr_company_code NUMBER(8) NOT NULL,
  intr_local_bank NUMBER(8) NOT NULL,
  intr_interest_type NUMBER(8) NOT NULL,
  intr_effective_date DATE NOT NULL,
  intr_from_period NUMBER(5),
  intr_from_type NUMBER(8),
  intr_to_period NUMBER(5),
  intr_to_type NUMBER(8),
  intr_from_amount NUMBER(15,2),
  intr_to_amount NUMBER(15,2),
  intr_interest_rate NUMBER(15,6) NOT NULL,
  intr_create_date DATE NOT NULL,
  intr_entry_detail XMLTYPE,
  intr_record_status NUMBER(8) NOT NULL,
  intr_location_code NUMBER(8)
);