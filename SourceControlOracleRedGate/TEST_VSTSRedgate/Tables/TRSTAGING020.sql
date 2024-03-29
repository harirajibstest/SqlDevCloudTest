CREATE TABLE "TEST_VSTSRedgate".trstaging020 (
  record_type VARCHAR2(2 BYTE),
  company_code VARCHAR2(10 BYTE) NOT NULL,
  location_code VARCHAR2(10 BYTE),
  lob_code VARCHAR2(10 BYTE),
  document_no VARCHAR2(15 BYTE),
  contract_date DATE,
  reference_no VARCHAR2(20 BYTE),
  reference_date DATE,
  customercode VARCHAR2(15 BYTE),
  customername VARCHAR2(50 BYTE),
  currency_code VARCHAR2(3 BYTE),
  payment_terms VARCHAR2(10 BYTE),
  item_number VARCHAR2(10 BYTE),
  total_weight NUMBER(15,6),
  total_value NUMBER(15,6),
  product_code VARCHAR2(15 BYTE),
  product_desc VARCHAR2(50 BYTE),
  uom_code VARCHAR2(10 BYTE),
  uom_qty NUMBER(15,6),
  uom_rate NUMBER(15,6),
  sales_remarks VARCHAR2(50 BYTE),
  delivery_date DATE,
  exchange_rate NUMBER(15,6)
);