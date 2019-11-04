CREATE TABLE "TEST_VSTSRedgate".trmaster403 (
  cdde_isin_number VARCHAR2(25 BYTE) NOT NULL,
  cdde_bank_code NUMBER(8),
  cdde_face_value VARCHAR2(20 BYTE),
  cdde_maturity_date DATE,
  cdde_credit_rating VARCHAR2(15 BYTE),
  cdde_rating_agency VARCHAR2(100 BYTE),
  cdde_cd_details VARCHAR2(50 BYTE),
  cdde_rta_agent VARCHAR2(200 BYTE),
  cdde_redeem_details VARCHAR2(500 BYTE),
  cdde_issuer_contact VARCHAR2(500 BYTE),
  cdde_cd_demat VARCHAR2(200 BYTE),
  cdde_security_name VARCHAR2(100 BYTE),
  CONSTRAINT trmaster403_pk PRIMARY KEY (cdde_isin_number)
);