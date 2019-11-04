CREATE TABLE "TEST_VSTSRedgate".dmrs_glossaries (
  glossary_id VARCHAR2(70 BYTE) NOT NULL,
  glossary_ovid VARCHAR2(36 BYTE) NOT NULL,
  glossary_name VARCHAR2(256 BYTE) NOT NULL,
  file_name VARCHAR2(256 BYTE),
  description VARCHAR2(4000 BYTE),
  incomplete_modifiers CHAR,
  case_sensitive CHAR,
  unique_abbrevs CHAR,
  separator_type VARCHAR2(10 BYTE),
  separator_char CHAR,
  date_published TIMESTAMP NOT NULL,
  published_by VARCHAR2(80 BYTE),
  persistence_version NUMBER(5,2) NOT NULL,
  version_comments VARCHAR2(4000 BYTE)
);