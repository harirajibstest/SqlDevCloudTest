CREATE TABLE "TEST_VSTSRedgate".migrlog (
  "ID" NUMBER NOT NULL,
  parent_log_id NUMBER,
  log_date TIMESTAMP NOT NULL,
  severity NUMBER(4) NOT NULL,
  logtext VARCHAR2(4000 BYTE),
  phase VARCHAR2(100 BYTE),
  ref_object_id NUMBER,
  ref_object_type VARCHAR2(4000 BYTE),
  connection_id_fk NUMBER,
  CONSTRAINT migrlog_pk PRIMARY KEY ("ID"),
  CONSTRAINT migr_migrlog_fk FOREIGN KEY (parent_log_id) REFERENCES "TEST_VSTSRedgate".migrlog ("ID")
);