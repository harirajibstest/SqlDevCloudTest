CREATE TABLE "TEST_VSTSRedgate".trtran034 (
  bint_company_code NUMBER(8),
  bint_location_code NUMBER(8),
  bint_deal_number VARCHAR2(25 BYTE) NOT NULL,
  bint_serial_number NUMBER(5) NOT NULL,
  bint_charge_date DATE,
  bint_charge_type NUMBER(8),
  bint_charge_amount NUMBER(15,2),
  bint_interest_upto DATE,
  bint_create_date DATE,
  bint_entry_detail XMLTYPE,
  bint_record_status NUMBER(8),
  CONSTRAINT trtran034_pk PRIMARY KEY (bint_deal_number,bint_serial_number)
);