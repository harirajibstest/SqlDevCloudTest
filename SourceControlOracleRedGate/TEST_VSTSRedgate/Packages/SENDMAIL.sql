CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."SENDMAIL" AS
TYPE t_split_array IS TABLE OF VARCHAR2(4000);

FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ',')
  RETURN t_split_array;

END SendMail;
 
 
 
 
 
 
 
 
 
 
 
/