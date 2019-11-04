CREATE TABLE "TEST_VSTSRedgate".trsystem022a (
  usco_company_code NUMBER(8) NOT NULL,
  usco_user_id VARCHAR2(50 BYTE) NOT NULL,
  usco_report_displaycom NUMBER(8),
  CONSTRAINT trsystem022a_pk PRIMARY KEY (usco_company_code,usco_user_id)
);