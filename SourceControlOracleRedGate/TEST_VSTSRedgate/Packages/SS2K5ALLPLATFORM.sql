CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate".SS2K5ALLPLATFORM AS 
                        FUNCTION StageCapture(projectId NUMBER, pluginClassIn VARCHAR2, projExists BOOLEAN:=FALSE, p_scratchModel BOOLEAN := FALSE) RETURN VARCHAR2;
                        FUNCTION amINewid(myc clob) return number; -- public function as called from sql
                        Function getPrecision(typein varchar2 , precisionin number, scalein number) return number; -- public function as called from sql
                        Function getnewscale(typein varchar2 , precisionin number, scalein number) return number; -- public function as called from sql
                        FUNCTION printUDTDef(basename VARCHAR2, p  NUMBER, s NUMBER,m NUMBER )  RETURN VARCHAR2; --public function used from sql                       
                        FUNCTION GetStatus(iid INTEGER) RETURN VARCHAR2;
END;
/