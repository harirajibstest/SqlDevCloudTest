CREATE TABLE "TEST_VSTSRedgate".stage_migrlog (
  svrid_fk NUMBER,
  dbid_gen_fk NUMBER,
  "ID" NUMBER NOT NULL,
  ref_object_id NUMBER,
  ref_object_type VARCHAR2(4000 BYTE),
  log_date TIMESTAMP NOT NULL,
  severity NUMBER(4) NOT NULL,
  logtext VARCHAR2(4000 BYTE),
  phase VARCHAR2(20 BYTE),
  CONSTRAINT stage_migrlog_pk PRIMARY KEY ("ID")
);