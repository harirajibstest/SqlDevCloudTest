CREATE TABLE "TEST_VSTSRedgate".trcovar004 (
  varc_calc_date DATE NOT NULL,
  varc_company_code NUMBER(8) NOT NULL,
  varc_location_code NUMBER(8) NOT NULL,
  varc_product_code NUMBER(8) NOT NULL,
  varc_subproduct_code NUMBER(8) NOT NULL,
  varc_exposure_type NUMBER(8) NOT NULL,
  varc_portfolio_variance NUMBER(30,25),
  varc_portfolio_volatility NUMBER(30,25),
  varc_var_95 NUMBER(15,6),
  varc_var_delta NUMBER(15,6),
  varc_component_var95 NUMBER(15,6),
  varc_component_var99 NUMBER(15,6),
  varc_adjust_earnings NUMBER(15,2),
  varc_sensitivity_95 NUMBER(15,6),
  varc_sensitivity_99 NUMBER(15,6),
  varc_portfolio_amount NUMBER(15,2),
  varc_portfolio_absamount NUMBER(15,2),
  varc_var_99 NUMBER(15,2),
  CONSTRAINT trcovar004_pk PRIMARY KEY (varc_calc_date,varc_company_code,varc_location_code,varc_product_code,varc_subproduct_code,varc_exposure_type)
);