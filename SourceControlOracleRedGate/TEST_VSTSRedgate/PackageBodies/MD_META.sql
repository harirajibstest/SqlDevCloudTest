CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."MD_META" AS

    multiplier constant number  := 22695477;
    increment  constant number  := 1;
    "2^32"     constant number  := 2 ** 32;
    "2^16"     constant number  := 2 ** 16;
    "0x7fff"   constant number  := 32767;
    Seed       number := 1;
    g_curr_val NUMBER DEFAULT NULL;
/*
 * Get the next available id for objectids.
 * @return the next id that can be used in objectid fields
 * This code is taken from wwv_flows
 */
FUNCTION get_next_id RETURN NUMBER
IS
BEGIN
/*
	select  to_number(
                 to_char(dbobjectid_sequence.nextval) ||
                      lpad( substr( abs(rand), 1, 5 ),5, '0' ) ||
                   ltrim(to_char(mod(abs(hsecs),1000000),'000000')))
    into    g_curr_val
    from   sys.v_$timer;

	select to_number(
				to_char(dbobjectid_sequence.nextval) ||
					lpad( substr( abs(rand), 1, 5 ), 5, '0') ||
				ltrim(to_char(mod(dbms_random.value(100000000000, 999999999999),1000000),'000000')))
    into    g_curr_val
	from dual;				
*/
	select dbobjectid_sequence.nextval
    into    g_curr_val
	from dual;	
    return g_curr_val;
END get_next_id;
-- Following code taken from wwv_flows_random 
 procedure srand( new_seed in number ) is
 begin
  Seed := new_seed;
 end srand;
--
  function rand return number is
    s number;
  begin
    seed := mod( multiplier * seed + increment, "2^32" );
    begin
       return bitand( seed/"2^16", "0x7fff" );
    --mhichwa
    exception when others then
       select dbobjectid_sequence.nextval into s from dual;
       return s||to_char(sysdate,'HH24MISS');
    end;
  end rand;
--
  procedure get_rand( r OUT number ) is
  begin
    r := rand;
  end get_rand;
--
  function rand_max( n IN number ) return number is
  begin
    return mod( rand, n ) + 1;
  end rand_max;
--
  procedure get_rand_max( r OUT number, n IN number )  is
  begin
    r := rand_max( n );
  end get_rand_max;

 FUNCTION quote(catalog IN VARCHAR2, schema IN VARCHAR2, object IN VARCHAR2, connid LONG ) RETURN VARCHAR2
  AS
  v_plugin VARCHAR2(1000);
  v_result VARCHAR2(4000) :='';
  v_ldelim VARCHAR2(1);
  v_rdelim VARCHAR2(1);
  v_isCatalogRequired BOOLEAN;
  v_isSchemaRequired BOOLEAN;
  v_maxCharsToDelim INT;
  BEGIN
  -- get database type using connid
   SELECT lower(VALUE) 
   INTO v_plugin
   FROM MD_ADDITIONAL_PROPERTIES
   WHERE PROP_KEY = 'PLUGIN_ID'
   AND connection_id_fk = connid;

    -- get the delimeter
    IF      v_plugin like '%sybase12%'   THEN
            v_ldelim := '[';
            v_rdelim := ']';     
            v_isCatalogRequired := true;
            v_isSchemaRequired := true;
            v_maxCharsToDelim := 28;
    ELSIF   v_plugin like '%sybase%'   THEN
            v_ldelim := '[';
            v_rdelim := ']';     
            v_isCatalogRequired := true;
            v_isSchemaRequired := true;    
            v_maxCharsToDelim := 300;
    ELSIF   v_plugin like '%sqlserver%' THEN 
            v_ldelim := '[';
            v_rdelim := ']';    
            v_isCatalogRequired := true;
            v_isSchemaRequired := true;
            v_maxCharsToDelim := 300;
    ELSIF  v_plugin like '%msaccess%'  THEN
            v_ldelim := '[';
            v_rdelim := ']'; 
            v_isCatalogRequired := false;
            v_isSchemaRequired :=false;
            v_maxCharsToDelim := 300;
    ELSIF v_plugin like '%mysql%'    THEN
            v_ldelim :='`'; 
            v_rdelim :='`';
            v_isCatalogRequired :=false;
            v_isSchemaRequired := true;
            v_maxCharsToDelim := 300;
    ELSIF v_plugin like '%db2%'        THEN
            v_ldelim :='"';
            v_rdelim :='"';
            v_isCatalogRequired := false;
            v_isSchemaRequired := true;
            v_maxCharsToDelim := 300;
    ELSIF v_plugin like '%teradata%'   THEN
            v_ldelim :='"';
            v_rdelim :='"';
            v_isCatalogRequired :=false;
            v_isSchemaRequired := true;
            v_maxCharsToDelim := 300;
    ELSE
            v_ldelim :='[';
            v_rdelim :=']';
            v_isCatalogRequired := true;
            v_isSchemaRequired := true;
            v_maxCharsToDelim := 300;
    END IF;

    IF LENGTH(catalog) > v_maxCharsToDelim THEN
      v_result := v_result || catalog ;-- do not quote as it is using the max amount of chars allowed 
    ELSE  
      v_result := v_result || v_ldelim || catalog ||v_rdelim;
    END IF ;

    IF LENGTH(schema) > v_maxCharsToDelim THEN
      v_result := v_result || '.' || schema ;-- do not quote as it is using the max amount of chars allowed 
    ELSE  
      v_result := v_result ||'.' || v_ldelim || schema || v_rdelim;
    END IF ;

    IF LENGTH(object) > v_maxCharsToDelim THEN
      v_result := v_result ||'.' || object ;-- do not quote as it is using the max amount of chars allowed 
    ELSE  
      v_result := v_result ||'.' || v_ldelim || object ||v_rdelim;
    END IF;      


   return v_result; 
END quote;  

--
-- One time initialisation
begin
  select to_char(sysdate,'JSSSSS')
    into seed
    from dual;
end;
/