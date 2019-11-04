CREATE TABLE "TEST_VSTSRedgate".dmrs_glossary_terms (
  term_id VARCHAR2(70 BYTE) NOT NULL,
  term_ovid VARCHAR2(36 BYTE) NOT NULL,
  term_name VARCHAR2(256 BYTE) NOT NULL,
  short_description VARCHAR2(4000 BYTE),
  abbrev VARCHAR2(256 BYTE),
  alt_abbrev VARCHAR2(256 BYTE),
  prime_word CHAR,
  class_word CHAR,
  modifier CHAR,
  qualifier CHAR,
  glossary_id VARCHAR2(70 BYTE) NOT NULL,
  glossary_ovid VARCHAR2(36 BYTE) NOT NULL,
  glossary_name VARCHAR2(256 BYTE) NOT NULL,
  plural VARCHAR2(256 BYTE)
);