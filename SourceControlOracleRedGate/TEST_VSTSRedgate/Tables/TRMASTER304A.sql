CREATE TABLE "TEST_VSTSRedgate".trmaster304a (
  cndi_company_code NUMBER(8) NOT NULL,
  cndi_location_code NUMBER(8) NOT NULL,
  cndi_base_currency NUMBER(8) NOT NULL,
  cndi_other_currency NUMBER(8) NOT NULL,
  cndi_direct_indirect NUMBER(8),
  cndi_add_date DATE NOT NULL,
  cndi_create_date DATE NOT NULL,
  cndi_entry_detail XMLTYPE,
  cndi_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trmaster304a PRIMARY KEY (cndi_company_code,cndi_location_code,cndi_base_currency,cndi_other_currency)
);