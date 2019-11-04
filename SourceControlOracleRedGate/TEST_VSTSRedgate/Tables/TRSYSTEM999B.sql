CREATE TABLE "TEST_VSTSRedgate".trsystem999b (
  gpic_synonym_name VARCHAR2(25 BYTE) NOT NULL,
  gpic_pick_group NUMBER(3) NOT NULL,
  gpic_record_status NUMBER(8),
  gpic_desc_type NUMBER(1),
  gpic_display_name VARCHAR2(50 BYTE),
  CONSTRAINT trsystem999b_pk PRIMARY KEY (gpic_synonym_name,gpic_pick_group)
);