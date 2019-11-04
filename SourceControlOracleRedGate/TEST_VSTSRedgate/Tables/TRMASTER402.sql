CREATE TABLE "TEST_VSTSRedgate".trmaster402 (
  cpde_isin_number VARCHAR2(25 BYTE) NOT NULL,
  cpde_company_name VARCHAR2(100 BYTE),
  cpde_issue_date DATE,
  cpde_face_value NUMBER(15,2),
  cpde_maturity_date DATE,
  cpde_credit_rating VARCHAR2(15 BYTE),
  cpde_rating_agency VARCHAR2(100 BYTE),
  cpde_nsdl_details VARCHAR2(200 BYTE),
  cpde_cp_details VARCHAR2(200 BYTE),
  cpde_rta_agent VARCHAR2(200 BYTE),
  cpde_ipa_details VARCHAR2(500 BYTE),
  cpde_company_address VARCHAR2(500 BYTE),
  cpde_ipa_demat VARCHAR2(500 BYTE),
  cpde_security_name VARCHAR2(100 BYTE),
  CONSTRAINT trmaster402_pk PRIMARY KEY (cpde_isin_number)
);