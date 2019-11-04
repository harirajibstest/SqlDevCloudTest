CREATE TABLE "TEST_VSTSRedgate".traudit001 (
  data_company_code NUMBER(8),
  data_location_code NUMBER(8),
  data_user_id VARCHAR2(50 BYTE),
  data_key_guid VARCHAR2(50 BYTE) NOT NULL,
  data_file_name VARCHAR2(100 BYTE),
  data_update_date DATE,
  data_rows_processed NUMBER(15),
  data_rows_notprocessed NUMBER(15),
  data_upload_timestamp TIMESTAMP DEFAULT systimestamp,
  data_file_size VARCHAR2(20 BYTE),
  data_file_createrdate DATE,
  data_file_modifieddate DATE,
  data_upload_status NUMBER(8),
  data_upload_remarks VARCHAR2(100 BYTE),
  data_synonym_name VARCHAR2(150 BYTE),
  CONSTRAINT traudit001_pk PRIMARY KEY (data_key_guid)
);