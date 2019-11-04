CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."MIGRATION_TRANSFORMER" AS
FUNCTION check_identifier_length(p_ident VARCHAR2) RETURN VARCHAR2;
FUNCTION add_suffix(p_work VARCHAR2, p_suffix VARCHAR2, p_maxlen NUMBER) RETURN VARCHAR2;
FUNCTION check_reserved_word(p_work VARCHAR2) RETURN VARCHAR2;
FUNCTION sys_check(p_work VARCHAR2) RETURN VARCHAR2;
FUNCTION check_allowed_chars(p_work NVARCHAR2) RETURN NVARCHAR2;
FUNCTION transform_identifier(p_identifier NVARCHAR2)  RETURN NVARCHAR2;
FUNCTION getDisallowedCharsNames(p_work NVARCHAR2) RETURN VARCHAR2;
FUNCTION getNameForNullCase(p_work NVARCHAR2) RETURN NVARCHAR2;
PROCEDURE set_oracle_long_identifier(b_flag INT);
FUNCTION get_oracle_long_identifier RETURN NUMBER;
END;
/