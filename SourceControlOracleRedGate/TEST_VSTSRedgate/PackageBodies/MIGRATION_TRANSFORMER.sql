CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."MIGRATION_TRANSFORMER" AS
  -- Maximum length of an identifier
  MAX_IDENTIFIER_LEN NUMBER:=30;
C_DISALLOWED_CHARS   CONSTANT NVARCHAR2(100) := ' .@`!\\"%^&*()-+=[]{};:,.<>?/~'''||UNISTR('\00A3');

--PRIVATE FUNCTION
FUNCTION truncateStringByteSize(p_work VARCHAR2, p_bsize NUMBER) RETURN VARCHAR2
IS
v_work VARCHAR2(4000);
v_bsize NUMBER(10);
BEGIN
 IF LENGTHB(p_work) <= p_bsize THEN
    return p_work;
  END IF;
  v_work := p_work;
  v_work := SUBSTRB(v_work, 1, p_bsize);
  WHILE INSTRC(p_work, v_work , 1, 1) <> 1 LOOP -- a character has been cut in half or in 2/3 or 3/4 by substrb (multibyte can have up to 4 bytes) 
  --note each left over corrupt byte can be a single character
   BEGIN
     v_bsize := LENGTHB(v_work);
  	 v_work := SUBSTRB(v_work, 1, v_bsize-1);
   END;
  END LOOP; 
  return v_work;
END;

FUNCTION add_suffix(p_work VARCHAR2, p_suffix VARCHAR2, p_maxlen NUMBER) RETURN VARCHAR2
IS
  v_suflen NUMBER := LENGTHB(p_suffix);
  v_truncamount NUMBER;
BEGIN
  IF LENGTHB(p_work) < p_maxlen - v_suflen THEN
    RETURN p_work || p_suffix;
  END IF;
  v_truncamount := LENGTHB(p_work) + v_suflen - p_maxlen;
  RETURN truncateStringByteSize(p_work, LENGTHB(p_work)-v_truncamount) || p_suffix;
END add_suffix;


FUNCTION check_identifier_length(p_ident VARCHAR2) RETURN VARCHAR2
IS
  v_work VARCHAR2(4000);
BEGIN
  return truncateStringByteSize(p_ident,  MAX_IDENTIFIER_LEN);
END;

FUNCTION check_reserved_word(p_work VARCHAR2) RETURN VARCHAR2
IS
  v_count NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_count FROM MIGRATION_RESERVED_WORDS WHERE KEYWORD = UPPER(p_work);
  IF v_count > 0 THEN
    -- It is a reserved word
    RETURN add_suffix(p_work, '_', MAX_IDENTIFIER_LEN);
  END IF;
  RETURN p_work;
END check_reserved_word;

FUNCTION sys_check(p_work VARCHAR2) RETURN VARCHAR2
IS
BEGIN
  IF LENGTH(p_work) < 4 THEN
    return p_work;
  END IF;
  IF SUBSTR(p_work, 1, 4) <> 'SYS_' THEN
    return p_work;
  END IF;
  RETURN 'SIS_' || SUBSTR(p_work, 5);
END sys_check;

FUNCTION first_char_check(p_work NVARCHAR2) RETURN NVARCHAR2
/**
 * Never want to start with anything but AlphaNumeri
 */
IS
  v_firstChar NCHAR(1);
  v_allowed NCHAR(200);
BEGIN
  v_allowed := C_DISALLOWED_CHARS || '0123456789_$#';
  v_firstChar := SUBSTR(p_work,1,1);
  if INSTR(v_allowed, v_firstChar) > 0 THEN
    return 'A' ||p_work;
  END IF;
  return p_work;
END first_char_check;



FUNCTION lTrimNonAlphaNumeric(p_work NVARCHAR2) RETURN NVARCHAR2
/**
 *Remove all non alphanumeric characters from the start 
 */
IS
  v_testChar VARCHAR2(2000);
  v_index NUMBER;
  v_work NVARCHAR2(4000):=p_work;
  v_forbiddenChars VARCHAR2(100);
  v_firstgoodchar NUMBER;
BEGIN
  v_forbiddenChars := C_DISALLOWED_CHARS ||'_$#';
  IF v_work IS NULL THEN
    RETURN 'UNKNOWN';
  END IF;
   FOR v_index in 1..LENGTH(v_work) LOOP
    v_testChar := SUBSTR(p_work, v_index, 1);
    IF INSTR(v_forbiddenChars, v_testChar) <= 0 THEN
      v_firstgoodchar := v_index;
      EXIT;--make sure to leave loop now as first real char reached
    END IF;
  END LOOP;
  return substr(p_work,v_firstgoodchar);
END lTrimNonAlphaNumeric;

FUNCTION removeQuotes(p_work NVARCHAR2) RETURN NVARCHAR2
/**
 * Removed Quotes around a identifier name
 */
IS
  v_firstChar NCHAR(1);
  v_lastChar NCHAR(1);
  v_quote NCHAR(200):= '"[]'; -- strip these from start and end;
  v_work NVARCHAR2(4000) := p_work;
BEGIN
  v_firstChar := SUBSTR(v_work,1,1);
  v_lastChar  := SUBSTR(v_work,LENGTH(v_work),1);
  if INSTR(v_quote, v_firstChar) > 0 THEN
  	v_work := SUBSTR(v_work, 2);
  	if INSTR(v_quote, v_lastChar) > 0 THEN
  	  v_work := SUBSTR(v_work,0,LENGTH(v_work)-1);
      return v_work;
    END IF;
      return v_work;
  END IF;
  return v_work;
END removeQuotes;


FUNCTION check_allowed_chars(p_work NVARCHAR2) RETURN NVARCHAR2
/* The documentation states 
 * "Nonquoted identifiers can contain only alphanumeric characters from your database character set and the
 *  underscore (_), dollar sign ($), and pound sign (#). Database links can also contain periods (.) and "at" signs (@).
 *  Oracle strongly discourages you from using $ and # in nonquoted identifiers."
 *  Heres a couple of gotchas
 *  1) We don't know where we will be generated to, so dunno what that database character set will be
 *  2) We've now way of knowing if a character is alphanumeric on the character set.
 * So... Here's what we'll do
 *  1) given that its come from a database, we'll assume with was alphanumeric
 *  2) We'll remove any "regular" symbol characters (i.e. one's on my keyboard!)
 *  3) We'll be storing in NVARCHAR2 in the hope that this will preserve everything.
 * 
 */
IS
  v_testChar VARCHAR2(2000);
  v_index NUMBER;
  -- Folowing syntax is a workaround for a problem with wrap.  Do not change it.
  v_forbiddenChars NVARCHAR2(100) := C_DISALLOWED_CHARS;
  v_work VARCHAR2(4000) := p_work;
  v_endswithunderscore boolean := FALSE;
BEGIN
  IF INSTR('_',SUBSTR(p_work, LENGTH(p_work))) >0 THEN
    v_endswithunderscore := TRUE;
  END IF;


  FOR v_index in 1..LENGTH(v_work) LOOP
    v_testChar := SUBSTR(p_work, v_index, 1);

    --check for existing underscores.these existed in the original and should be preserved as later we remove multiple underscores
    --bug:10405027
    IF v_testChar = '_' THEN
    	v_work :=SUBSTR(v_work,1,v_index-1)||'!' || SUBSTR(v_work,v_index+1);
    ELSIF INSTR(v_forbiddenChars, v_testChar) > 0 THEN
      v_work := SUBSTR(v_work, 1, v_index-1) || '_' || SUBSTR(v_work, v_index+1);
    END IF;
  END LOOP;

  --NOW REMOVE DOUBLE UNDERSCORES see bug 6647397
  v_work := replace(replace (replace (v_work,'__','_'),'__','_'),'__','_');--replace 2 underscores with 1 underscore

  --bug:10405027 , original underscore and a new one
  v_work := replace(v_work,'!_','_');
  v_work := replace(v_work,'_!','_'); 

  --NOW ADD BACK IN EXISTING ORGINAL UNDERSCORES bug:10405027
  v_work := replace(v_work,'!','_');

  --REMOVE THE LT CHAR IF IT IS AN UNDERSCORE
  IF v_endswithunderscore=false AND INSTR('_',SUBSTR(v_Work,LENGTH(v_work))) > 0 THEN
    v_work := SUBSTR(v_work,0,LENGTH(v_work)-1);
  END IF;
  return v_work;
END check_allowed_chars;

FUNCTION transform_identifier(p_identifier NVARCHAR2)  RETURN NVARCHAR2
IS
  v_work VARCHAR2(4000);
BEGIN
  v_work := p_identifier;
  BEGIN
	  -- There are 10 rules defined for identifier naming:
	  -- See http://st-doc.us.oracle.com/10/102/server.102/b14200/sql_elements008.htm#i27570

	  v_work := removeQuotes(v_work);
	  v_work := lTrimNonAlphaNumeric(v_work);
	  IF v_work is null THEN
	    v_work := getNameForNullCase(p_identifier);	 ---bug no. 8904200 
	  END IF;

	  --moving this to first as we can shrink the size of the name if they have more than 1 invalid char in a row.
	  --see bug 6647397
	   -- 5. Must begin withan alpha character from your character set
	  v_work := first_char_check(v_work);
	   -- 6. Alphanumeric characters from your database charset plus '_', '$', '#' only
	  v_work := check_allowed_chars(v_work);
	  -- 1. Length
	  v_work := check_identifier_length(v_work);
	  -- 2. Reserved words
	  v_work := check_reserved_word(v_work);
	  -- 3. "Special words" -I've handled these in reserved words, but still have to check if it starts with SYS
	  v_work := sys_check(v_work);
	  -- 4. "You should use ASCII characters in database names, global database names, and database link names,
	  --    because ASCII characters provide optimal compatibility across different platforms and operating systems."
	  -- This doesn't apply as we are not doing anything with DB names
	  -- 7. Name collisions; we'll handle this at a higher level.
	  -- 8. Nonquoted identifiers are case insensitive.  This is a doubl edged sword: If we use quoted, we can possible
	  --    Keep it similar to the source platform.  However this is not how it is typically done in Oracle.
	  -- 9. Columns in the same table.  See point 7. above.
	  -- 10. All about overloading for functions and parameters.  We don't have to handle this here either, at this
	  --     Should all be done by parsing technology.
  EXCEPTION WHEN OTHERS THEN
   v_work := p_identifier;
  END;  
  return v_work;
END transform_identifier;
FUNCTION fix_all_schema_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  v_ret NUMBER;
BEGIN
  v_ret := 0;
  -- First, we transform all identifiers to meet our rules
  -- Then, we need to see if we've caused any collisions in the process
  -- And if so, fix them
  -- Right now, this is a dummy stub.
  return v_ret;
END fix_all_schema_identifiers;

FUNCTION fix_all_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  v_ret NUMBER;
BEGIN
  v_ret := fix_all_schema_identifiers(p_connectionid);
  return v_ret;
END fix_all_identifiers;  

FUNCTION getNameForNullCase(p_work NVARCHAR2) RETURN NVARCHAR2
IS
  v_work VARCHAR2(4000);
  v_testChar VARCHAR2(2000);
  v_index NUMBER;
BEGIN
  FOR v_index in 1..LENGTH(p_work) LOOP
    v_testchar := SUBSTR(p_work,v_index,1);
    v_work := v_work || getDisallowedCharsNames(v_testchar);
  END LOOP;
  return v_work;
END;

FUNCTION getDisallowedCharsNames(p_work NVARCHAR2) RETURN VARCHAR2
IS
  v_work VARCHAR2(4000) := p_work;
BEGIN
  ----' .@`!"%^&*()-+=[]{};:,.<>?/~''' 
    v_work := ( CASE p_work
    WHEN '.' THEN 'DOT'
    WHEN '@' THEN 'AT'
    WHEN '`' THEN 'APOSTROPHE'
    WHEN '!' THEN 'EXCLAMATION'
    WHEN '"' THEN 'D_QUOTE'
    WHEN '%' THEN 'PERCENT'
    WHEN '^' THEN 'CARET'
    WHEN '&' THEN 'AMPERSAND'
    WHEN '*' THEN 'STAR'
    WHEN '(' THEN 'LEFTPARENTHESIS'
    WHEN ')' THEN 'RIGHTPARANTHESIS'
    WHEN '-' THEN 'MINUS'
    WHEN '+' THEN 'PLUS'
    WHEN '=' THEN 'EQUAL'
    WHEN '[' THEN 'LEFTSQUARE_B'
    WHEN ']' THEN 'RIGHTSQUARE_B'
    WHEN '{' THEN 'LEFTCURLY_B'
    WHEN '}' THEN 'RIGHTCURLY_B'
    WHEN ';' THEN 'COLON'
    WHEN ':' THEN 'SEMICOLON'
    WHEN ',' THEN 'COMMA'
    WHEN '<' THEN 'LESSTHAN'
    WHEN '>' THEN 'GREATERTHAN'
    WHEN '?' THEN 'QUESTIONMARK'
    WHEN '~' THEN 'TILDE'
    WHEN '/' THEN 'BACKSLASH'
    WHEN '''' THEN 'S_QUOTE'
    WHEN '$' THEN 'DOLLAR'
    ELSE 'UNKNOWN'
    END);
    return v_work;
END;

PROCEDURE set_oracle_long_identifier(b_flag INT)
/**
 * Setting for usage of 12.2 Database 128 bytes Long identifier
 */
IS
BEGIN
  if (b_flag = 1) then
    MAX_IDENTIFIER_LEN := 128;
  elsif (b_flag = 0) then
    MAX_IDENTIFIER_LEN := 30;
  END IF;
END set_oracle_long_identifier;

FUNCTION get_oracle_long_identifier RETURN NUMBER
/**
 * Get the setting for usage of 12.2 Database 128 byte Long identifier
 */
IS
BEGIN
  IF MAX_IDENTIFIER_LEN = 0 THEN
     MAX_IDENTIFIER_LEN := 30;
    return 30;
  END IF;

  IF MAX_IDENTIFIER_LEN = 30 THEN
    return 30;
  END IF;

  IF (MAX_IDENTIFIER_LEN = 128) THEN
    return 128;
  END IF;
  return 0;
END get_oracle_long_identifier;

END;
/