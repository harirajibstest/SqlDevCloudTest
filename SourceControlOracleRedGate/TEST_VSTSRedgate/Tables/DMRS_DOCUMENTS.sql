CREATE TABLE "TEST_VSTSRedgate".dmrs_documents (
  document_id VARCHAR2(70 BYTE) NOT NULL,
  document_ovid VARCHAR2(36 BYTE) NOT NULL,
  document_name VARCHAR2(256 BYTE) NOT NULL,
  business_info_id VARCHAR2(70 BYTE) NOT NULL,
  business_info_ovid VARCHAR2(36 BYTE) NOT NULL,
  business_info_name VARCHAR2(256 BYTE) NOT NULL,
  parent_id VARCHAR2(70 BYTE),
  parent_ovid VARCHAR2(36 BYTE),
  parent_name VARCHAR2(256 BYTE),
  doc_reference VARCHAR2(2000 BYTE),
  doc_type VARCHAR2(1000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);