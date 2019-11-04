CREATE TABLE "TEST_VSTSRedgate".trcovar003 (
  copo_calc_date DATE NOT NULL,
  copo_company_code NUMBER(8) NOT NULL,
  copo_location_code NUMBER(8) NOT NULL,
  copo_product_code NUMBER(8) NOT NULL,
  copo_subproduct_code NUMBER(8) NOT NULL,
  copo_currency_code NUMBER(8) NOT NULL,
  copo_forcurrency_code NUMBER(8) NOT NULL,
  copo_maturity_month NUMBER(2) NOT NULL,
  copo_exposure_type NUMBER(8) NOT NULL,
  copo_transaction_amount NUMBER(15,2),
  copo_cal_weight NUMBER(15,6),
  copo_signed_weight NUMBER(15,6),
  copo_var_delta NUMBER(30,20),
  copo_component_var95 NUMBER(15,6),
  copo_component_var99 NUMBER(15,6),
  copo_matrix_multipler NUMBER(30,20),
  CONSTRAINT trcovar003_pk PRIMARY KEY (copo_calc_date,copo_company_code,copo_location_code,copo_product_code,copo_subproduct_code,copo_currency_code,copo_forcurrency_code,copo_maturity_month,copo_exposure_type)
);