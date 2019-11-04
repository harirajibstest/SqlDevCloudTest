CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."IS_NUMBER" ( p_str IN VARCHAR2 )
  RETURN VARCHAR2 DETERMINISTIC PARALLEL_ENABLE
IS
  l_num NUMBER;
BEGIN
  l_num := to_number( p_str );
  RETURN 'Y';
EXCEPTION
  WHEN value_error THEN
    RETURN 'N';
END is_number;
 
 
 
 
 
 
 
 
 
 
 
/