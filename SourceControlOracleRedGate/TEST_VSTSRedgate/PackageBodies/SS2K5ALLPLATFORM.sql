CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate".SS2K5ALLPLATFORM
AS
TYPE split_varray_type IS VARRAY(255) OF VARCHAR2(32767);
TYPE ref_cur_type
IS
  REF

  CURSOR;
  TYPE key_array IS VARRAY(20) OF NUMBER(38,0);
TYPE str_array_type
IS
  TABLE OF       VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  nProjectId     NUMBER(38,0);
  sev_err CONSTANT NUMBER :=2;
  sev_warn CONSTANT NUMBER :=4;
  sev_others CONSTANT NUMBER :=8;
  bProjectExists BOOLEAN;
  exceptionOccurred BOOLEAN :=FALSE;
  nSvrId         NUMBER(38,0) := NULL;
  RawToNumberFMT constant CHAR(12)     := 'XXXXXXXXXXXX';
  NumberToRawFMT constant CHAR(14)     := 'FM' || RawToNumberFMT;
  NewID          constant CHAR(9 CHAR) := '(newid())';
  NewIDClob CLOB                       :=NewID;--does this string to clob shortcut work in 9ir2?
  NewIDClobLength NUMBER(38,0)         := 9;
  MAX_LEN         NUMBER(38,0)         :=-999;
  pluginClass     VARCHAR2(500)        := NULL;
  CaptureNotClean EXCEPTION;
FUNCTION LOCALSUBSTRB(
    vin        VARCHAR2)
  RETURN VARCHAR2
AS
  v VARCHAR2(4000 CHAR):=SUBSTR(vin, 1, 4000);
  l NUMBER;
BEGIN
  l               := LENGTH(v);
  WHILE (lengthb(v)>4000)
  LOOP
    l := l-1;
    v := SUBSTR(v,1,l);
  END LOOP;
  RETURN v;
END;
FUNCTION GetStatus(iid INTEGER) RETURN varchar2
IS
   status VARCHAR2(4000);
   errMsg VARCHAR2(2000);
BEGIN
   SELECT logtext INTO status FROM migrlog WHERE severity = 666 AND phase = 'CAPTURE' AND connection_id_fk = iid;    
   RETURN status; 
EXCEPTION 
  WHEN OTHERS THEN
     errMsg := SQLERRM;  
     dbms_output.put_line('Status Message : ' || errMsg);
  RETURN ' ';
END GetStatus;

PROCEDURE SetStatus(msg VARCHAR2)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   --dbms_output.put_line(msg);
   --commit;
   --progressStatus := msg;
   --dbms_lock.sleep(2);
   UPDATE migrlog SET logtext = msg,
                  log_date = systimestamp
                  WHERE severity = 666 
                      AND phase = 'CAPTURE'
                      AND connection_id_fk = nProjectId;                   
   COMMIT;
END SetStatus; 

PROCEDURE LogInfo( parent_log_id NUMBER,
                   severity NUMBER,
                   logtextin VARCHAR2,
                   ref_obj_id NUMBER,
                   ref_obj_typein VARCHAR2,
                   connection_id NUMBER)
 IS
 PRAGMA AUTONOMOUS_TRANSACTION;
   errMsg  VARCHAR2(4000) := NULL;
   logtext varchar2(4000) := null;
   ref_obj_type varchar2(4000) := null;
 BEGIN
   IF (severity = sev_err)
   THEN
       exceptionOccurred :=TRUE;
   END IF;
   logtext := LOCALSUBSTRB (logtextin);
   ref_obj_type := LOCALSUBSTRB (ref_obj_typein);
   IF (connection_id is NULL) THEN
          BEGIN
              INSERT INTO STAGE_MIGRLOG ( "SVRID_FK", "DBID_GEN_FK",
                  ID, REF_OBJECT_ID,
                  REF_OBJECT_TYPE, LOG_DATE,
                  SEVERITY, LOGTEXT, PHASE)
              VALUES(null,null,null,ref_obj_id,ref_obj_type,null/* trigger will put in SYSTIMESTAMP */, 1000, logtext,'Capture');
              COMMIT;
          EXCEPTION
             WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE('Capture:LogInfo Failed: ['  || logtext ||  
                 '] insert exception: ' || LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || 
                 LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE)));
          END;
    ELSE
        INSERT INTO MIGRLOG(parent_log_id, 
                       log_date, 
                       severity, 
                       logtext, 
                       phase, 
                       ref_object_id, 
                       ref_object_type, 
                       connection_id_fk) 
         VALUES(parent_log_id, 
                sysdate, 
                severity, 
                logtext, 
                'Capture', 
                ref_obj_id, 
                ref_obj_type, 
                connection_id) ;
    END IF;
    COMMIT;
 EXCEPTION
 WHEN OTHERS THEN
   errMsg := SQLERRM;
   DBMS_OUTPUT.put_line('Log Err: ['  || errMsg       || ']'
                                    || parent_log_id   || ':' 
                                    || severity     || ':'
                                    || logtext      || ':Capture:'
                                    || ref_obj_id   || ':'
                                    || ref_obj_type || ':'
                                    || connection_id);
 END LogInfo;
FUNCTION amINewid
  (
    myc CLOB
  )

  RETURN NUMBER
IS
BEGIN

  IF
    (
      myc IS NULL
    )
    THEN

    RETURN 0;

  END IF;

  IF
    (
      dbms_lob.getlength(myc) != NewIDClobLength
    )
    THEN

    RETURN 0;

  END IF;

  IF
    (
      instr (myc,NewIDClob)!=0
    )--starting at char 1 would be a match
    THEN

    RETURN 1;

  END IF;

  RETURN 0;

END amINewid;

FUNCTION getPrecision
  (
    typein      VARCHAR2 ,
    precisionin NUMBER,
    scalein     NUMBER
  )

  RETURN NUMBER
IS
  lowerType VARCHAR2
  (
    1000
  )
  :=lower
  (
    typein
  )
  ;
BEGIN

  IF
    (
      lowerType='bigint'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='int'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='smallint'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='money'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='tinyint'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='smallmoney'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='bit'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType ='float'
    )
    THEN

    IF
      (
        (precisionin IS NOT NULL) AND ( precisionin = 0 )
      )
      THEN

      RETURN NULL;

    END IF;

  END IF;

  IF
    (
      lowerType='real'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='datetime'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='smalldatetime'
    )
    THEN

    RETURN NULL;

  END IF;
  IF
    (
      lowerType='date'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='time'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='datetime2'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='datetimeoffset'
    )
    THEN

    RETURN NULL;

  END IF;

  --if (lowerType='char')
  --then
  --  scale = null;
  --end if

  IF
    (
      lowerType='text'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType ='varbinary'
    )
    THEN

    IF
      (
        precisionin=-1
      )
      THEN

      RETURN MAX_LEN;

    END IF;

  END IF;

  IF
    (
      lowerType ='nvarchar'
    )
    THEN

    IF
      (
        precisionin=-1
      )
      THEN

      RETURN MAX_LEN;

    END IF;

    RETURN precisionin/2;

  END IF;

  IF
    (
      lowerType ='varchar'
    )
    THEN

    IF
      (
        precisionin=-1
      )
      THEN

      RETURN MAX_LEN;

    END IF;

  END IF;

  IF
    (
      lowerType='nchar'
    )
    THEN

    RETURN precisionin/2;

  END IF;

  IF
    (
      lowerType='sysname'
    )
    THEN

    RETURN NULL;

  END IF;
  --if (lowerType='nchar')
  --then
  --  scale = null;
  --end if;

  IF
    (
      lowerType='ntext'
    )
    THEN

    RETURN NULL;

  END IF;
  --if (lowerType='nvarchar')
  --then
  --  scale = null;
  --end if;
  --if (lowerType='binary')
  -- then
  --  scale = null;
  --end if;

  IF
    (
      lowerType='image'
    )
    THEN

    RETURN NULL;

  END IF;
  --if (lowerType='varbinary')
  --then
  --  scale = null;
  --end if;

  IF
    (
      lowerType='cursor'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='timestamp'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='sql_variant'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='uniqueidentifier'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='table'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='xml'
    )
    THEN

    RETURN NULL;

  END IF;

  RETURN precisionin;

END getPrecision;

FUNCTION getnewscale
  (
    typein      VARCHAR2 ,
    precisionin NUMBER,
    scalein     NUMBER
  )

  RETURN NUMBER
IS
  lowerType VARCHAR2
  (
    1000
  )
  :=lower
  (
    typein
  )
  ;
BEGIN

  IF
    (
      lowerType='bigint'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='int'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='smallint'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='money'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='tinyint'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='smallmoney'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='bit'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='float'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='real'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='datetime'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='smalldatetime'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='date'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='time'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='datetime2'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='datetimeoffset'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='char'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='text'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='varchar'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='sysname'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='nchar'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='ntext'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='nvarchar'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='binary'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='image'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='varbinary'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='cursor'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='timestamp'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='sql_variant'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='uniqueidentifier'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='table'
    )
    THEN

    RETURN NULL;

  END IF;

  IF
    (
      lowerType='xml'
    )
    THEN

    RETURN NULL;

  END IF;

  RETURN scalein;

END getnewscale;


PROCEDURE CaptureConnections
IS
errMsg VARCHAR2(4000) := NULL;
BEGIN

  IF bProjectExists = FALSE
  THEN
  INSERT
  INTO md_projects
    (
      "ID",
      project_name,
      comments
    )
    (SELECT project_id,
        project_name,
        comments
      FROM STAGE_SERVERDETAIL
      WHERE project_id = nProjectId
      AND NOT EXISTS
        ( SELECT 1 FROM md_projects WHERE "ID" = nProjectId
        )
    ) ;
  END IF;

  INSERT
  INTO md_connections
    (
      "ID",
      project_id_fk,
      username,
      dburl,
      "NAME"
    )
    (SELECT SVRID,
        nProjectId,
        username,
        dburl,
        db_name
      FROM STAGE_SERVERDETAIL
      WHERE project_id = nProjectId
    ) ;
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'Capture Connections: ['  || errMsg ||  '] ' || 'nSvrId:Project Id : ' || nSvrId || ' : '|| nProjectId, NULL, NULL, nSvrId);  
END CaptureConnections;

PROCEDURE CaptureDatabases
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN

  INSERT
  INTO md_catalogs
    (
      "ID",
      connection_id_fk,
      catalog_name,
      dummy_flag,
      comments
    )
    (SELECT d.dbid_gen,
        d.svrid_fk,
        d."NAME",
        'N',
        p.VALUE
      FROM STAGE_SS2K5_DATABASES d,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE d.svrid_fk  = nSvrId
      AND p.class(+)    = 0
      AND p.svrid_fk(+) = nSvrId
      AND p.MAJOR_ID(+) = 0
      AND p.MINOR_ID(+) = 0
      AND d.dbid_gen    =p.dbid_gen_fk(+)
    );
EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 
                'CaptureDatabases Failed: [' || errMsg || '] ' || 'Server Id : ' || nSvrId, 
                NULL, NULL, nSvrId);        
END CaptureDatabases;

PROCEDURE CaptureSchemas
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN

  INSERT
  INTO md_schemas
    (
      "ID",
      catalog_id_fk,
      "NAME",
      comments
    )
    (SELECT A.suid_gen,
        A.dbid_gen_fk,
        A."NAME",
        p.VALUE
      FROM STAGE_SS2K5_SCHEMAS A,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE A.svrid_fk = nSvrId
      AND a.schema_id  <16384
      AND a.NAME       !='INFORMATION_SCHEMA'
      AND a.name       !='sys'
      AND EXISTS
        (SELECT 1
        FROM STAGE_SS2K5_OBJECTS o
        WHERE o.schema_id = a.schema_id
        AND o.svrid_fk    = nSvrId
        AND o.dbid_gen_fk = a.dbid_gen_fk
        )
      AND p.class(+) = 3
        /* schema */
      AND p.svrid_fk(+)    = nSvrId
      AND p.MAJOR_ID(+)    = a.schema_id
      AND p.MINOR_ID(+)    = 0
      AND p.dbid_gen_fk(+) = a.dbid_gen_fk
    );
EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 
                'CaptureSchemas Failed: [' || errMsg || '] ' || 'Server Id : ' || nSvrId, 
                NULL, NULL, nSvrId);           
END;

PROCEDURE CaptureTables
IS
  errMsg VARCHAR2(4000) := null;
BEGIN
 -- SetStatus('Capturing Tables');
  INSERT
  INTO md_tables
    (
      "ID",
      schema_id_fk,
      table_name,
      qualified_native_name,
      comments
    )
    (SELECT objid_gen,
        a.schema_id_fk,
        A."NAME",
        C."NAME"
        || '.'
        || B."NAME"
        || '.'
        || A."NAME",
        p.value comments
      FROM stage_ss2k5_tables A,
        stage_ss2k5_schemas B,
        stage_ss2k5_databases C,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE A.SCHEMA_ID_FK = B.SUID_GEN
        --probably better to use concrete nSvrid where possible.
      AND A.NAME NOT IN ('sysdiagrams')
      AND A.svrid_fk    = nSvrId
      AND B.svrid_fk    = nSvrId
      AND C.svrid_fk    = nSvrId
      AND A.dbid_gen_fk = B.dbid_gen_fk
      AND B.dbid_gen_fk = C.dbid_gen
      AND p.class(+)    = 1
        /* object or column */
      AND p.svrid_fk(+)    = nSvrId
      AND p.MAJOR_ID(+)    = a.object_id
      AND p.MINOR_ID(+)    = 0
      AND p.dbid_gen_fk(+) = a.dbid_gen_fk
    );
EXCEPTION 
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 
                'CaptureTables Failed: [' || errMsg || '] ' || 'Server Id : ' || nSvrId, 
                NULL, NULL, nSvrId);
END CaptureTables;
/**
* look up to see if base type is valid.
* @param baseTypeIn the text of a type got from sql server
* @return true if base type is not handled.
*/

FUNCTION baseTypeIsNotHandled
  (
    baseTypeIn VARCHAR2
  )

  RETURN BOOLEAN
IS
  baseTypeUpper VARCHAR2
  (
    1000 CHAR
  )
  ;
  returnValue BOOLEAN := true;
  errMsg VARCHAR2(4000) := NULL;
BEGIN

  IF
    (
      baseTypeIn IS NULL
    )
    THEN

    RETURN true;

  END IF;
  baseTypeUpper := Upper
  (
    baseTypeIn
  )
  ;

  IF
    (
      baseTypeUpper='VARCHAR'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='BIGINT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='DECIMAL'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='INT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='NUMERIC'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='SMALLINT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='MONEY'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='TINYINT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='SMALLMONEY'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='BIT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='FLOAT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='REAL'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='DATETIME'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='SMALLDATETIME'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='DATETIME2'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='DATETIMEOFFSET'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='DATE'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='TIME'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='CHAR'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='TEXT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='SYSNAME'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='NCHAR'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='NTEXT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='NVARCHAR'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='NVARCHAR'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='BINARY'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='IMAGE'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='VARBINARY'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='VARBINARY'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='CURSOR'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='TIMESTAMP'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='SQL_VARIANT'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='UNIQUEIDENTIFIER'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='TABLE'
    )
    THEN

    RETURN false;

  END IF;

  IF
    (
      baseTypeUpper='XML'
    )
    THEN

    RETURN false;

  END IF;

  RETURN returnValue;
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'baseTypeIsNotHandled: ['  || errMsg ||  '] nSvrId:baseTypeIn = ' || nSvrId || ': ' || baseTypeIn, NULL, NULL, nSvrId);
END baseTypeIsNotHandled;

FUNCTION ProcessForUserDefinedDatatype
(
   default_defn VARCHAR2
)
 RETURN VARCHAR2 
IS
   hasAs NUMBER;
   default_txt VARCHAR2(1000);
   errMsg VARCHAR2(4000) := NULL;
BEGIN   
   IF default_defn IS NULL THEN
      RETURN default_defn;
   ELSE
      default_txt := default_defn;
      hasAs := INSTR(LOWER(default_defn), ' as ');
      IF hasAs > 0 THEN
         default_txt := SUBSTR(default_defn, hasAS + 4);
      END IF;
   END IF;
   RETURN default_txt;
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'ProcessForUserDefinedDatatype: ['  || errMsg ||  '] nSvrId:default_defn = ' || nSvrId || ': '|| default_defn, NULL, NULL, nSvrId);
END ProcessForUserDefinedDatatype;

PROCEDURE CaptureColumns
IS
  functionreturn BOOLEAN := false;
  curcolint      NUMBER
  (
    38,0
  )
  ;

  CURSOR curTab
  IS

    SELECT objid_gen,
      object_id,
      DBID_GEN_FK
    FROM stage_ss2k5_tables
    WHERE svrid_fk = nSvrId
    AND NAME NOT IN ('sysdiagrams');

  CURSOR curCol (thisTab NUMBER)
  IS

    SELECT r_c1.colid_gen mycolid,
      r_c1.id_gen_fk myid,
      r_c1."NAME" myname,
      base_type.base_name mybasename,
      CASE
        WHEN ( ( r_c1."PRECISION" = 0 )
        OR ( r_c1."PRECISION"    IS NULL ) )
        THEN SS2K5AllPlatform.getPrecision(base_type.base_name,r_c1. "MAX_LENGTH",r_c1."SCALE")
        ELSE SS2K5AllPlatform.getPrecision(base_type.base_name,r_c1. "PRECISION",r_c1."SCALE")
      END myprecision,
      SS2K5AllPlatform.getnewscale(base_type.base_name,
      CASE
        WHEN ( ( r_c1."PRECISION" = 0 )
        OR ( r_c1."PRECISION"    IS NULL ) )
        THEN r_c1."MAX_LENGTH"
        ELSE r_c1."PRECISION"
      END,r_c1."SCALE")
      --r_c1."SCALE"
      myscale ,
      CASE
        WHEN r_c1.is_Nullable=1
        THEN 'Y'
        ELSE 'N'
      END mynullable,
      dc.definition mydefinition,
      p.value comments
    FROM stage_ss2k5_columns r_c1 ,
      stage_ss2k5_tables tabst,
      (SELECT
        (SELECT tt.name
        FROM stage_ss2k5_types tt
        WHERE tt.user_type_id = t.system_type_id
        AND tt.svrid_fk       = nSvrId
        AND tt.dbid_gen_fk    =t.dbid_gen_fk
        ) base_name,
      t.user_type_id t_user_type_id,
      t.dbid_gen_fk t_dbid_gen_fk
    FROM stage_ss2k5_types t
    WHERE t.svrid_fk = nSvrId
      ) base_type,
      (SELECT *
      FROM stage_ss2k5_dt_constraints x
      WHERE x.object_id != 0
      AND x.object_id   IS NOT NULL
      AND x.svrid_fk     =nSvrId
      ) dc,
      STAGE_SS2K5_SYSPROPERTIES p
    WHERE tabst.objid_gen        = r_c1.id_gen_fk
    AND base_type.t_user_type_id = r_c1.user_type_id
      -- i.e. just table clolumns
      -- r_c1.id_gen_fk is not null --I think there must be some system tables
      -- column in here which are not loaded - so they are null and void. I may
      -- be wrong actually they may be views for example.!!!
    AND dc.object_id (+)        = r_c1.DEFAULT_OBJECT_ID
    AND ( ( dc.dbid_gen_fk      =r_c1.dbid_gen_fk )
    OR ( dc.dbid_gen_fk        IS NULL ) )
    AND tabst.svrid_fk          = nSvrId
    AND tabst.dbid_gen_fk       =r_c1.dbid_gen_fk
    AND base_type.t_dbid_gen_fk =r_c1.dbid_gen_fk
    AND r_c1.svrid_fk           = nSvrId -- want to do it for all database but
      -- join back to this database for secondary tables do not want  cross
      -- database ids.
    AND r_c1.id_gen_fk = thistab
    AND p.class(+)     = 1
      /* object or column */
    AND p.svrid_fk(+)    = nSvrId
    AND p.MAJOR_ID(+)    = r_c1.object_id
    AND p.MINOR_ID(+)    = r_c1.column_id
    AND p.dbid_gen_fk(+) = r_c1.dbid_gen_fk
    ORDER BY r_c1.column_id;
    default_defn VARCHAR2(2000);
    errMsg VARCHAR2(4000) := NULL;
  BEGIN
    --SetStatus('Capturing Columns');
    FOR r_c1 IN curTab
    LOOP
      curcolint := 0;   
      FOR r_c2 IN curcol(r_c1.objid_gen)
      LOOP
        curcolint := curcolint + 1;
        -- assuming 1 to 1 correspondance between suid and uid within a
        -- database
        default_defn := ProcessForUserDefinedDatatype(r_c2.mydefinition);
        functionreturn:=baseTypeIsNotHandled(r_c2.mybasename);

        IF (functionreturn = true) THEN
          BEGIN
          --TODO write to log that basename is not valid - might be a CLR so punting to varbinary(8000)
          INSERT
          INTO MD_COLUMNS
            (
              "ID",
              table_id_fk,
              column_name,
              column_order,
              column_type,
              "PRECISION",
              "SCALE",
              nullable,
              default_value,
              comments
            )
            VALUES
            (
              r_c2.mycolid,
              r_c2.myid,
              r_c2.myname,
              curcolint,
              'varbinary',
              8000,
              NULL,
              'Y',
              default_defn,
              r_c2.comments
            );
        EXCEPTION
          WHEN OTHERS THEN
             errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
             LogInfo(NULL, sev_err, 'CaptureColumns:punting type to varbinary ['  || errMsg ||  
             ']   nSvrId:table_id_fk,column_name:column_order =' || nSvrId||': '||r_c2.myid || ': ' || r_c2.myname || ': ' ||curcolint, NULL, NULL, nSvrId);          
        END;
        ELSE
          BEGIN
          INSERT
          INTO MD_COLUMNS
            (
              "ID",
              table_id_fk,
              column_name,
              column_order,
              column_type,
              "PRECISION",
              "SCALE",
              nullable,
              default_value,
              comments
            )
            VALUES
            (
              r_c2.mycolid,
              r_c2.myid,
              r_c2.myname,
              curcolint,
              r_c2.mybasename,
              r_c2.myprecision,
              r_c2.myscale,
              r_c2.mynullable,
              default_defn,
              r_c2.comments
            );
                EXCEPTION
          WHEN OTHERS THEN
             errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
             LogInfo(NULL, sev_err, 'CaptureColumns:inserting column ['  || errMsg ||  
             ']   nSvrId:table_id_fk:column_name:column_order =' || nSvrId||': '||r_c2.myid || ': ' || r_c2.myname || ': ' ||curcolint, NULL, NULL, nSvrId);          
           END;
        END IF;

      END LOOP; -- column loop

    END LOOP; -- tables loop
    BEGIN
    INSERT
    INTO MD_ADDITIONAL_PROPERTIES
      (
        connection_id_fk,
        ref_id_fk,
        ref_type,
        property_order,
        prop_key,
        "VALUE"
      )
      (SELECT c.svrid_fk,
          c.colid_gen,
          'MD_COLUMNS' ,
          NULL,
          NewID,
          'Y'
        FROM stage_ss2k5_columns c,
          stage_ss2k5_dt_constraints dc
        WHERE c.svrid_fk                             = nSvrId
        AND dc.svrid_fk                              = nSvrId
        AND dc.dbid_gen_fk                           = c.dbid_gen_fk
        AND c.DEFAULT_OBJECT_ID                      = dc.object_id
        AND ss2k5allplatform.amINewid(dc.definition) = 1
        AND EXISTS
          ( SELECT 1 FROM md_tables WHERE id=c.id_gen_fk
          )
      );

    -- handle identity columns
    -- not sure if I should have an is not null on these properties.
    INSERT
    INTO MD_ADDITIONAL_PROPERTIES
      (
        connection_id_fk,
        ref_id_fk,
        ref_type,
        property_order,
        prop_key,
        "VALUE"
      )
      (--note this is broken in 2000 to 2005 upgrades that have not been
        -- rebuilt in some was -> becomes ordinary int column may need
        -- is_identity flag
        SELECT c.svrid_fk,
          c.colid_gen,
          'MD_COLUMNS' ,
          NULL,
          'SEEDVALUE',
          seed_value
        FROM stage_ss2k5_columns c,
          stage_ss2k5_identity_columns i ,
          stage_ss2k5_tables tabst
        WHERE tabst.svrid_fk = nSvrId
        AND tabst.objid_gen  = c.id_gen_fk
        AND c.id_gen_fk     IS NOT NULL
        AND c.id_gen_fk     != 0
        AND c.svrid_fk       = nSvrId
        AND i.svrid_fk       = nSvrId
        AND c.dbid_gen_fk    = i.dbid_gen_fk
        AND i.column_id      = c.column_id
        AND i.object_id      = c.object_id
        AND seed_value      IS NOT NULL
        AND EXISTS
          ( SELECT 1 FROM md_tables t WHERE t.id=c.id_gen_fk
          )
      );

    INSERT
    INTO MD_ADDITIONAL_PROPERTIES
      (
        connection_id_fk,
        ref_id_fk,
        ref_type,
        property_order,
        prop_key,
        "VALUE"
      )
      (--note this is broken in 2000 to 2005 upgrades that have not been
        -- rebuilt in some was -> becomes ordinary int column may need
        -- is_identity flag
        SELECT c.svrid_fk,
          c.colid_gen,
          'MD_COLUMNS' ,
          NULL,
          'INCREMENT',
          increment_value
        FROM stage_ss2k5_columns c,
          stage_ss2k5_identity_columns i ,
          stage_ss2k5_tables tabst
        WHERE tabst.svrid_fk = nSvrId
        AND tabst.objid_gen  = c.id_gen_fk
        AND c.id_gen_fk     IS NOT NULL
        AND c.id_gen_fk     != 0
        AND c.svrid_fk       = nSvrId
        AND i.svrid_fk       = nSvrId
        AND c.dbid_gen_fk    = i.dbid_gen_fk
        AND i.column_id      = c.column_id
        AND i.object_id      = c.object_id
        AND seed_value      IS NOT NULL
        AND increment_value IS NOT NULL
        AND EXISTS
          ( SELECT 1 FROM md_tables t WHERE t.id=c.id_gen_fk
          )
      );

    INSERT
    INTO MD_ADDITIONAL_PROPERTIES
      (
        connection_id_fk,
        ref_id_fk,
        ref_type,
        property_order,
        prop_key,
        "VALUE"
      )
      (--note this is broken in 2000 to 2005 upgrades that have not been
        -- rebuilt in some was -> becomes ordinary int column may need
        -- is_identity flag
        SELECT c.svrid_fk,
          c.colid_gen,
          'MD_COLUMNS' ,
          NULL,
          'LASTVALUE',
          last_value
        FROM stage_ss2k5_columns c,
          stage_ss2k5_identity_columns i ,
          stage_ss2k5_tables tabst
        WHERE tabst.svrid_fk = nSvrId
        AND tabst.objid_gen  = c.id_gen_fk
        AND c.id_gen_fk     IS NOT NULL
        AND c.id_gen_fk     != 0
        AND c.svrid_fk       = nSvrId
        AND i.svrid_fk       = nSvrId
        AND c.dbid_gen_fk    = i.dbid_gen_fk
        AND i.column_id      = c.column_id
        AND i.object_id      = c.object_id
        AND seed_value      IS NOT NULL
        AND last_value      IS NOT NULL
        AND EXISTS
          ( SELECT 1 FROM md_tables t WHERE t.id=c.id_gen_fk
          )
      );
        EXCEPTION
        WHEN OTHERS THEN
             errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
             LogInfo(NULL, sev_err, 'CaptureColumns:Group insert of additional properties for identity ['  || errMsg ||  
             ']   nSvrId: ' || nSvrId, NULL, NULL, nSvrId);          
        END;
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureColumns: Unable to Open master cursor:['  || errMsg ||  '] nSvrId: ' || nSvrId,  NULL, NULL, nSvrId);          
END CaptureColumns;

PROCEDURE CapturePrimaryAndUniqueKeys
IS
  curorder NUMBER
  (
    38,0
  )
  ;

  CURSOR curConst
  IS

    SELECT a.objid_gen myid,
      TRIM(a.name) myname,
      CASE
        WHEN a.type = 'UQ'
        THEN 'UNIQUE'
        ELSE 'PK'
      END mytype,
      t.objid_gen mytable,
      'MSTSQL' mylanguage,
      p.VALUE comments
    FROM STAGE_SS2K5_objects a,
      stage_ss2k5_objects a2,
      stage_ss2k5_tables t,
      STAGE_SS2K5_SYSPROPERTIES p
    WHERE ( a.type    ='PK'
    OR a.type         ='UQ' )
    AND a2.type      IN ('U', 'U ')
    AND a2.object_id  = a.parent_object_id
    AND t.object_id   = a2.object_id
    AND a.svrid_fk    = nSvrId
    AND a2.svrid_fk   = nSvrId
    AND t.svrid_fk    = nSvrId
    AND t.dbid_gen_fk = a2.dbid_gen_fk
    AND a.dbid_gen_fk = a2.dbid_gen_fk
    AND t.NAME NOT IN ('sysdiagrams')
    AND EXISTS
      ( SELECT 1 FROM md_tables WHERE id = t.objid_gen
      ) --might be a sys table for example
  AND p.class(+) = 1
    /* object or column */
  AND p.svrid_fk(+)    = nSvrId
  AND p.MAJOR_ID(+)    = a.object_id
  AND p.MINOR_ID(+)    = 0
  AND p.dbid_gen_fk(+) = a.dbid_gen_fk ;

  CURSOR curConstDetails(thisConst NUMBER)
  IS

    SELECT d.colid_gen myid
    FROM STAGE_SS2K5_OBJECTS a2,
      STAGE_SS2K5_OBJECTS a,
      STAGE_SS2K5_INDEXES b,
      STAGE_SS2K5_INDEX_COLUMNS c,
      STAGE_SS2K5_COLUMNS d,
      STAGE_SS2K5_OBJECTS e
    WHERE ( a.objid_gen = thisConst )
    AND ( a.type        ='PK'
    OR a.type           ='UQ' )
    AND a2.object_id    = a.parent_object_id
    AND a.name          =b.name
    AND c.object_id     = b.object_id
    AND c.index_id      = b.index_id
    AND b.object_id     =a.parent_object_id
    AND d.object_id     = c.object_id
    AND d.column_id     = c.column_id
    AND e.object_id     = a.object_id
    AND a2.type        IN ('U', 'U ')
    AND a.svrid_fk      = nSvrId
    AND b.svrid_fk      = nSvrId
    AND c.svrid_fk      = nSvrId
    AND d.svrid_fk      = nSvrId
    AND e.svrid_fk      = nSvrId
    AND a.dbid_gen_fk   = a2.dbid_gen_fk
    AND b.dbid_gen_fk   = a2.dbid_gen_fk
    AND c.dbid_gen_fk   = a2.dbid_gen_fk
    AND d.dbid_gen_fk   = a2.dbid_gen_fk
    AND e.dbid_gen_fk   = a2.dbid_gen_fk
    AND EXISTS
      ( SELECT 1 FROM md_tables WHERE id = d.id_gen_fk
      ) --might be a sys table for example
  ORDER BY c.column_id;
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  --create the constraints
  --SetStatus('Capturing Primary and Unique keys');
  FOR r_c1 IN curConst
  LOOP
    BEGIN
    INSERT
    INTO MD_CONSTRAINTS
      (
        ID,
        "NAME",
        constraint_type,
        table_id_fk,
        "LANGUAGE",
        comments
      )
      VALUES
      (
        r_c1.myid,
        r_c1.myname,
        r_c1.mytype,
        r_c1.mytable,
        r_c1.mylanguage,
        r_c1.comments
      );

    curorder :=0;

    FOR r_c2 IN curConstDetails
    (
      r_c1.myid
    )
    LOOP
      curorder := curorder + 1;

      --fill in the columns

      INSERT
      INTO MD_CONSTRAINT_DETAILS
        (
          constraint_id_fk,
          column_id_fk,
          detail_order
        )
        VALUES
        (
          r_c1.myid,
          r_c2.myid,
          curorder
        );

    END LOOP;--details
    EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CapturePrimaryAndUniqueKeys: single constraint faied ['  || errMsg ||  
        ']         nSvrId:NAME:constraint_type:table_id_fk  =' || nSvrId || ': '|| r_c1.myname ||': '|| r_c1.mytype||': '|| r_c1.mytable, NULL, NULL, nSvrId);          
    END;
  END LOOP; --constraints
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CapturePrimaryAndUniqueKeys: main outer loop failure ['  || errMsg ||  
        '] nSvrId = '|| nSvrId|| ': ', NULL, NULL, nSvrId);          
END CapturePrimaryAndUniqueKeys;

PROCEDURE CaptureForeignKeys
IS
  curorder NUMBER
  (
    38,0
  )
  ;

  CURSOR curConst
  IS

    SELECT fk.object_id myid,
      o.objid_gen mdid,
      p.value comments,
      fk.dbid_gen_fk theDatabaseGen
    FROM STAGE_SS2K5_FN_KEYS fk,
      STAGE_SS2K5_TABLES lt,
      STAGE_SS2K5_OBJECTS o,
      STAGE_SS2K5_SYSPROPERTIES p
    WHERE o.parent_object_id!=0
    AND o.parent_object_id   =lt.object_id
    AND fk.svrid_fk          = nSvrId
    AND lt.svrid_fk          = nSvrId
    AND o.svrid_fk           = nSvrId
    AND lt.dbid_gen_fk       = fk.dbid_gen_fk
    AND o.dbid_gen_fk        = fk.dbid_gen_fk
    AND o.object_id          = fk.object_id
    AND lt.NAME NOT IN ('sysdiagrams')
    AND EXISTS
      (SELECT 1 FROM md_tables mdt WHERE mdt.id=lt.objid_gen
      )
    --need to put in the server and database checks so there are no false positives
  AND p.class(+) = 1
    /* object or column */
  AND p.svrid_fk(+)       = nSvrId
  AND p.MAJOR_ID(+)    = fk.object_id
  AND p.MINOR_ID(+)    = 0
  AND p.dbid_gen_fk(+) = fk.dbid_gen_fk ;

  CURSOR curConstDetails(constId NUMBER, thedb NUMBER)
  IS

    SELECT
      (SELECT COUNT(1) FROM md_tables mdt2 WHERE mdt2.id=rt.objid_gen
      ) oneIfRtCaptured,
    fk.name fk_name,
    fkc.constraint_object_id fkc_constraint_object_id,
    lc.name lc_name,
    (SELECT s.name
    FROM STAGE_SS2K5_SCHEMAS s
    WHERE s.schema_id = rt.schema_id
    AND s.svrid_fk    = nSvrId
    AND s.dbid_gen_fk = fk.dbid_gen_fk
    AND s.dbid_gen_fk = thedb
    ) schemaname,
    rt.name reftablename,
    rc.name refcolumnname,
    fkc.constraint_column_id fkc_constraint_column_id ,
    lc.colid_gen lc_colid_gen,
    rc.colid_gen rc_colid_gen,
    lt.objid_gen lt_objid_gen,
    rt.objid_gen rt_objid_gen
  FROM STAGE_SS2K5_FN_KEYS fk,
    STAGE_SS2K5_FN_KEY_COLUMNS fkc,
    STAGE_SS2K5_COLUMNS lc,
    STAGE_SS2K5_COLUMNS rc,
    STAGE_SS2K5_TABLES rt,
    STAGE_SS2K5_TABLES lt
  WHERE fk.object_id           = constId
  AND fk.object_id             = fkc.constraint_object_id
  AND lc.object_id             = fkc.parent_object_id
  AND lc.column_id             = fkc.parent_column_id
  AND rc.object_id             = fkc.referenced_object_id
  AND rc.column_id             = fkc.referenced_column_id
  AND fkc.referenced_object_id = rt.object_id
  AND fkc.parent_object_id     = lt.object_id
  AND fk.svrid_fk              = nSvrId
  AND fkc.svrid_fk             = nSvrId
  AND lc.svrid_fk              = nSvrId
  AND rc.svrid_fk              = nSvrId
  AND rt.svrid_fk              = nSvrId
  AND lt.svrid_fk              = nSvrId
  AND fkc.dbid_gen_fk          = fk.dbid_gen_fk
  AND lc.dbid_gen_fk           = fk.dbid_gen_fk
  AND rc.dbid_gen_fk           = fk.dbid_gen_fk
  AND rt.dbid_gen_fk           = fk.dbid_gen_fk
  AND lt.dbid_gen_fk           = fk.dbid_gen_fk
  AND fk.dbid_gen_fk           = thedb
  AND EXISTS
    (SELECT 1 FROM md_tables mdt WHERE mdt.id=lt.objid_gen
    )
  ORDER BY fkc.constraint_column_id ;
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  --('Capturing Foreign Keys');
  --use commit/rollback to commit or back out of a dodgy foreign key constraint
  --create the constraints

  FOR r_c1 IN curConst
  LOOP
    BEGIN
    COMMIT;
    curorder :=0;
    FOR r_c2 IN curConstDetails ( r_c1.myid , r_c1.theDatabaseGen)
    LOOP
      --rc2 contains: oneIfRtCaptured, fk_name, fkc_constraint_object_id, lc_name,
      --schemaname, reftablename,refcolumnname, fkc_constraint_column_id,
      --lc_colid_gen, rc_colid_gen, lt_objid_gen, rt_objid_gen
      --looks like I have selected too many columns
      curorder := curorder + 1;
      --fill in the columns

      --can loop back on itself for a non self referencial example on a different column.
      IF ((r_c2.oneIfRtCaptured!=1)) THEN
        DBMS_OUTPUT.put_line('Skipping foreign key that references table not in repository');
        ROLLBACK;
        EXIT;

      END IF;

      IF (curorder=1) THEN
        INSERT
        INTO MD_CONSTRAINTS
          (
            ID,
            "NAME",
            constraint_type,
            table_id_fk,
            reftable_id_fk,
            "LANGUAGE",
            comments
          )
          VALUES
          (
            r_c1.mdid,
            r_c2.fk_name,
            'FOREIGN KEY',
            r_c2.lt_objid_gen,
            r_c2.rt_objid_gen,
            'MSTSQL',
            r_c1.comments
          );

      END IF;

      INSERT
      INTO MD_CONSTRAINT_DETAILS
        (
          constraint_id_fk,
          column_id_fk,
          detail_order
        )
        VALUES
        (
          r_c1.mdid,
          r_c2.lc_colid_gen,
          curorder
        );

      INSERT
      INTO MD_CONSTRAINT_DETAILS
        (
          ref_flag,
          constraint_id_fk,
          column_id_fk,
          detail_order
        )
        VALUES
        (
          'Y',
          r_c1.mdid,
          r_c2.rc_colid_gen,
          curorder
        );
      --rollback on error
      COMMIT;
      --need to commit correct foreign keys before loopback reference wipes the insert.
    END LOOP;--details
    COMMIT;
    EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureForeignKeys:Single constraint failure ['  || errMsg ||  
        ']  nSvrId:type:sourceObjectId =' || nSvrId || ': FOREIGN KEY: ' || r_c1.myid, NULL, NULL, nSvrId);          
    END;
  END LOOP; --constraints
EXCEPTION
  WHEN OTHERS THEN
     errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
     LogInfo(NULL, sev_err, 'CaptureForeignKeys:Outer loop failure ['  || errMsg ||  
     ']  nSvrId = '||nSvrId, NULL, NULL, nSvrId);
END CaptureForeignKeys;

PROCEDURE CaptureTableLevelCkConstraints
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  --SetStatus('Capturing Table Level Check Constraints');
  INSERT
  INTO md_constraints
    (
      name,
      constraint_type,
      table_id_fk,
      constraint_text,
      LANGUAGE,
      comments
    )
    (SELECT c."NAME",
        'CHECK',
        lt.objid_gen,
        d."DEFINITION" ,
        'MSTSQL',
        p.value comments
      FROM STAGE_SS2K5_OBJECTS a,
        STAGE_SS2K5_OBJECTS a2,
        STAGE_SS2K5_OBJECTS c,
        STAGE_SS2K5_CHECK_CONSTRAINTS d,
        STAGE_SS2K5_TABLES lt,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE a."TYPE"           ='C'
      AND a.object_id          = c.object_id
      AND d."OBJECT_ID"        = a."OBJECT_ID"
      AND d."PARENT_COLUMN_ID" = 0
      AND a.parent_object_id   = a2.object_id
      AND lt.object_id         = a2.object_id
      AND a.svrid_fk           = nSvrId
      AND a2.svrid_fk          = nSvrId
      AND c.svrid_fk           = nSvrId
      AND d.svrid_fk           = nSvrId
      AND lt.svrid_fk          = nSvrId
      AND a2.dbid_gen_fk       = a.dbid_gen_fk
      AND c.dbid_gen_fk        = a.dbid_gen_fk
      AND d.dbid_gen_fk        = a.dbid_gen_fk
      AND lt.dbid_gen_fk       = a.dbid_gen_fk
      AND lt.NAME NOT IN ('sysdiagrams')
      AND EXISTS
        (SELECT 1 FROM md_tables mdt WHERE mdt.id=lt.objid_gen
        )
      AND p.class(+) = 1
        /* object or column */
      AND p.svrid_fk(+)    = nSvrId
      AND p.MAJOR_ID(+)    = a.object_id
      AND p.MINOR_ID(+)    = 0
      AND p.dbid_gen_fk(+) = a.dbid_gen_fk
    );
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureTableLevelCkConstraints Failed: ['  || errMsg ||  '] nSvrId =' || nSvrId ,NULL, NULL, nSvrId);
END CaptureTableLevelCkConstraints;

PROCEDURE CaptureColLevelCkConstraints
IS
  errMsg VARCHAR2(4000) := NULL;
  curconstid NUMBER
  (
    38,0
  )
  ;

  CURSOR curConst
  IS

    SELECT c."NAME" myname,
      'CHECK' mycheck,
      lt.objid_gen mytable,
      d."DEFINITION" mydefinition,
      'MSTSQL' mylanguage,
      col.colid_gen mycolid,
      p.value comments
    FROM STAGE_SS2K5_OBJECTS a,
      STAGE_SS2K5_OBJECTS a2,
      STAGE_SS2K5_OBJECTS c,
      STAGE_SS2K5_CHECK_CONSTRAINTS d,
      STAGE_SS2K5_TABLES lt,
      STAGE_SS2K5_COLUMNS col,
      STAGE_SS2K5_SYSPROPERTIES p
    WHERE a."TYPE"            ='C'
    AND a.object_id           = c.object_id
    AND d."OBJECT_ID"         = a."OBJECT_ID"
    AND d."PARENT_COLUMN_ID" <> 0
    AND a.parent_object_id    = a2.object_id
    AND lt.object_id          = a2.object_id
    AND a.svrid_fk            = nSvrId
    AND col.object_id         = lt.object_id
    AND d."PARENT_COLUMN_ID"  = col.column_id
    AND col.svrid_fk          = nSvrId
    AND a2.svrid_fk           = nSvrId
    AND c.svrid_fk            = nSvrId
    AND d.svrid_fk            = nSvrId
    AND lt.svrid_fk           = nSvrId
    AND col.dbid_gen_fk       = a.dbid_gen_fk
    AND a2.dbid_gen_fk        = a.dbid_gen_fk
    AND c.dbid_gen_fk         = a.dbid_gen_fk
    AND d.dbid_gen_fk         = a.dbid_gen_fk
    AND lt.dbid_gen_fk        = a.dbid_gen_fk
    AND lt.NAME NOT IN ('sysdiagrams')
    AND EXISTS
      (SELECT 1 FROM md_tables mdt WHERE mdt.id=lt.objid_gen
      )
  AND p.class(+) = 1
    /* object or column */
  AND p.svrid_fk(+)    = nSvrId
  AND p.MAJOR_ID(+)    = a.object_id
  AND p.MINOR_ID(+)    = 0
  AND p.dbid_gen_fk(+) = a.dbid_gen_fk ;
BEGIN
  --SetStatus('Capturing Column Level Check Constraints');
  FOR r_c1 IN curConst
  LOOP
    BEGIN
    INSERT
    INTO md_constraints
      (
        name,
        constraint_type,
        table_id_fk,
        LANGUAGE,
        comments
      )
      VALUES
      (
        r_c1.myname,
        r_c1.mycheck,
        r_c1.mytable,
        r_c1.mylanguage,
        r_c1.comments
      )
    RETURNING id
    INTO curConstid;

    INSERT
    INTO md_constraint_details
      (
        constraint_id_fk,
        column_id_fk,
        detail_order,
        constraint_text
      )
      VALUES
      (
        curConstid,
        r_c1.mycolid,
        1,
        r_c1.mydefinition
      );
      EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureColLevelCkConstraints Failed: single constraint failure['  || errMsg ||  
        ']   nSvrId:name:constraint_type:table_id_fk = '
        ||nSvrId|| ': ' ||r_c1.myname|| ': ' ||
        r_c1.mycheck|| ': ' ||
        r_c1.mytable, NULL, NULL, nSvrId);          
      END;
  END LOOP;
EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureColLevelCkConstraints Failed: outer loop failure['  || errMsg ||  
        ']  nSvrId = '|| nSvrId, NULL, NULL, nSvrId);          
END CaptureColLevelCkConstraints;

PROCEDURE CaptureRules
IS
  errMsg VARCHAR2(4000) := NULL;
  curconstid NUMBER
  (
    38,0
  )
  ;

  CURSOR curConst
  IS

    SELECT a.svrid_fk mysvrid,
      t.objid_gen mytableid,
      a."NAME" mytablename,
      b."NAME" mycolumnname,
      b.colid_gen mycolid,
      b."RULE_OBJECT_ID" myruleid,
      m.definition mymoduledefinition,
      p.value comments
    FROM STAGE_SS2K5_OBJECTS a,
      STAGE_SS2K5_COLUMNS b,
      STAGE_SS2K5_OBJECTS c ,
      STAGE_SS2K5_TABLES t,
      STAGE_ss2k5_sql_modules m,
      STAGE_SS2K5_SYSPROPERTIES p
    WHERE a."TYPE"         = 'U'
    AND b."OBJECT_ID"      = a."OBJECT_ID"
    AND c.object_id        = a."OBJECT_ID"
    AND b."RULE_OBJECT_ID" > 0
    AND m.object_id        =b.rule_object_id
    AND t.object_id        = a.object_id
    AND a.svrid_fk         = nSvrId
    AND t.svrid_fk         = nSvrId
    AND b.svrid_fk         = nSvrId
    AND c.svrid_fk         = nSvrId
    AND m.svrid_fk         = nSvrId
    AND a.dbid_gen_fk      = b.dbid_gen_fk
    AND c.dbid_gen_fk      = a.dbid_gen_fk
    AND t.dbid_gen_fk      = a.dbid_gen_fk
    AND m.dbid_gen_fk      = a.dbid_gen_fk
    AND t.NAME NOT IN ('sysdiagrams')
    AND EXISTS
      (SELECT 1 FROM md_tables mdt WHERE mdt.id=t.objid_gen
      )
  AND p.class(+)       = 1
  AND p.svrid_fk(+)    = nSvrId
  AND p.MAJOR_ID(+)    = a.object_id
  AND p.MINOR_ID(+)    = 0
  AND p.dbid_gen_fk(+) = a.dbid_gen_fk ;
BEGIN
  --SetStatus('Capturing Roles');
  FOR r_c1 IN curConst
  LOOP
    BEGIN
    INSERT
    INTO md_constraints
      (
        name,
        constraint_type,
        table_id_fk,
        LANGUAGE,
        comments
      )
      VALUES
      (
        'rul_'
        || r_c1.mytablename
        || '_'
        || r_c1.mycolumnname,
        'CHECK',
        r_c1.mytableid,
        'MSTSQL',
        r_c1.comments
      )
    RETURNING id
    INTO curConstid;

    INSERT
    INTO MD_ADDITIONAL_PROPERTIES
      (
        connection_id_fk,
        ref_id_fk,
        ref_type,
        property_order,
        prop_key,
        "VALUE"
      )
      VALUES
      (
        r_c1.mysvrid,
        curConstid,
        'MD_CONSTRAINTS',
        1,
        'TYPE',
        'RULE'
      );

    /*TODO check additional properties againt a proper capture */

    INSERT
    INTO md_constraint_details
      (
        constraint_id_fk,
        column_id_fk,
        detail_order,
        constraint_text
      )
      VALUES
      (
        curConstid,
        r_c1.mycolid,
        1,
        r_c1.mymoduledefinition
      );
   EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureRules Failed: single rule failure ['  || errMsg ||  ']         nSvrid:name:constraint_type:table_id_fk = '
        || nSvrId ||': '||
        'rul_'
        || r_c1.mytablename
        || '_'
        || r_c1.mycolumnname||': '||
        'CHECK'||': '||
        r_c1.mytableid, NULL, NULL, nSvrId);          
   END;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
     errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
     LogInfo(NULL, sev_err, 'CaptureRules Failed: outer loop failure ['  || errMsg ||  ']         nSvrid = '
     || nSvrId, NULL, NULL, nSvrId);          
END CaptureRules;

PROCEDURE CaptureConstraints
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  --SetStatus('Capturing Constraints');
  CapturePrimaryAndUniqueKeys;
  CaptureForeignKeys;
  CaptureTableLevelCkConstraints;
  CaptureColLevelCkConstraints;
  CaptureRules;
EXCEPTION
  WHEN OTHERS THEN
     errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
     LogInfo(NULL, sev_err, 'CaptureConstraints Failed: ['  || errMsg ||  ']         nSvrid = '
     || nSvrId, NULL, NULL, nSvrId); 
END CaptureConstraints;

PROCEDURE CaptureIndexes
IS
  errMsg VARCHAR2(4000) := NULL;
  curtableid NUMBER
  (
    38,0
  )
  ;
  curindexid NUMBER
  (
    38,0
  )
  ;
  detailCounter NUMBER
  (
    38,0
  )
  ;
  nIdxDetailId NUMBER
  (
    38,0
  )
  ;
  vIdxtype VARCHAR2
  (
    100
  )
  ;
  vc_Unique CONSTANT VARCHAR2
  (
    100
  )
  := 'unique';
  vc_IndexUnique CONSTANT VARCHAR2
  (
    100
  )
  := 'UNIQUE';
  vc_IndexNonUnique CONSTANT VARCHAR2
  (
    100
  )
  := 'NON_UNIQUE';

  CURSOR getIndex
  IS

    SELECT i.object_id_gen
      /* should really be named different - as object_id is the table id */
      ,
      i."OBJECT_ID" mytableid,
      i."INDEX_ID" myindexid,
      i."NAME" myindexname,
      i."IS_UNIQUE" myisunique,
      o."NAME" mytablename,
      lt.objid_gen mygentableid,
      P.Value Comments,
      i.dbid_gen_fk dbidgenfk
    FROM STAGE_SS2K5_INDEXES i,
      STAGE_SS2K5_OBJECTS o,
      STAGE_SS2K5_TABLES lt,
      STAGE_SS2K5_SYSPROPERTIES p
    WHERE o.type     IN ('U', 'V', 'U ', 'V ')
    AND o."OBJECT_ID" = i."OBJECT_ID"
    AND i.name NOT LIKE '_WA_Sys%'
    AND i.is_primary_key = 0
    AND EXISTS
      (SELECT 1 FROM md_tables mdt WHERE mdt.id=lt.objid_gen
      )
  AND lt.object_id     = o.object_id
  AND i.svrid_fk       = nSvrId
  AND o.svrid_fk       = nSvrId
  AND lt.svrid_fk      = nSvrId
  AND i.dbid_gen_fk    = o.dbid_gen_fk
  AND o.dbid_gen_fk    = lt.dbid_gen_fk
  AND p.class(+)       = 7
  AND p.svrid_fk(+)    = nSvrId
  AND p.MAJOR_ID(+)    = i.object_id
  AND p.MINOR_ID(+)    = i.index_id
  AND p.dbid_gen_fk(+) = i.dbid_gen_fk 
  AND lt.NAME NOT IN ('sysdiagrams');

  CURSOR getDetails(thedatabaseid NUMBER,thetableid NUMBER, theindexid NUMBER)
  IS

    SELECT a.index_column_id,
      b.name,
      a.is_descending_key is_descending_key,
      B.COLID_GEN
    FROM STAGE_SS2K5_INDEX_COLUMNS a ,
      STAGE_SS2K5_COLUMNS b
    WHERE a.index_id = theindexid
    AND b.column_id  = a.column_id
    AND b.object_id  = a.object_id
    AND a.object_id  = thetableid
    AND
      -- tableid exists in md_tables checked in initial query
      a.svrid_fk      = nSvrId
    AND b.svrid_fk    = nSvrId
    And A.Dbid_Gen_Fk = B.Dbid_Gen_Fk
    and a.dbid_gen_fk=thedatabaseid;
BEGIN
  --SetStatus('Capturing Indexes');
  FOR r_c1 IN getIndex
  LOOP
    BEGIN
    --create index

    IF (r_c1.myisunique = 1) THEN
      vIdxType         :=vc_IndexUnique;

    ELSE
      vIdxType:=vc_IndexNonUnique;

    END IF;

    INSERT
    INTO MD_INDEXES
      (
        "ID",
        index_type,
        table_id_fk,
        index_name,
        comments
      )
      VALUES
      (
        r_c1.object_id_gen ,
        vIdxType,
        r_c1.mygentableid,
        r_c1.myindexname,
        r_c1.comments
      );

    detailCounter := 0;

    FOR r_c2 IN getDetails
    (
      r_c1.dbidgenfk,r_c1.mytableid, r_c1.myindexid
    )
    LOOP
      detailcounter := detailcounter + 1;
      --create index details

      INSERT
      INTO MD_INDEX_DETAILS
        (
          index_id_fk,
          column_id_fk,
          detail_order
        )
        VALUES
        (
          r_c1.object_id_gen,
          r_c2.colid_gen,
          detailCounter
        )
      RETURNING "ID"
      INTO nIdxDetailId;

      IF
        (
          r_c2.is_descending_key = 1
        )
        THEN

        INSERT
        INTO MD_ADDITIONAL_PROPERTIES
          (
            connection_id_fk,
            ref_id_fk,
            ref_type,
            property_order,
            prop_key,
            "VALUE"
          )
          VALUES
          (
            nSvrId,
            nIdxDetailId,
            'MD_INDEX_DETAIL',
            detailCounter,
            'IS_INDEXDETAIL_DESCENDING',
            'Y'
          );

      END IF;

    END LOOP;
    EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureIndexes Failed: Single index failure ['  || errMsg ||  '] nSvrId:myindexname = ' || nSvrId ||': '||r_c1.myindexname, NULL, NULL, nSvrId);          
    END;
  END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureIndexes Failed: Outer loop failure ['  || errMsg ||  '] nSvrId = ' || nSvrId , NULL, NULL, nSvrId);          
END CaptureIndexes;

PROCEDURE CaptureViews
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  SetStatus('Capturing Views');
  INSERT
  INTO MD_VIEWS
    (
      id,
      schema_id_fk,
      view_name,
      native_sql,
      "LANGUAGE",
      comments
    )
    (SELECT a.objid_gen,
        s.suid_gen,
        a."NAME",
        b.DEFINITION,
        'MSTSQL',
        p.value comments
      FROM STAGE_SS2K5_OBJECTS a,
        STAGE_SS2K5_SQL_MODULES b,
        stage_SS2K5_schemas s,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE a."TYPE"     ='V'
      AND a."OBJECT_ID"  = b."OBJECT_ID"
      AND a.is_ms_shipped=0
      AND s.schema_id    = a.schema_id
      AND EXISTS
        (SELECT 1 FROM md_schemas mds WHERE mds.id=s.suid_gen
        )
      AND a.svrid_fk       = nSvrId
      AND b.svrid_fk       = nSvrId
      AND s.svrid_fk       = nSvrId
      AND a.dbid_gen_fk    = b.dbid_gen_fk
      AND s.dbid_gen_fk    = b.dbid_gen_fk
      AND p.class(+)       = 1
      AND p.svrid_fk(+)    = nSvrId
      AND p.MAJOR_ID(+)    = a.object_id
      AND p.MINOR_ID(+)    = 0
      AND p.dbid_gen_fk(+) = a.dbid_gen_fk
    ) ;
EXCEPTION
    WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureViews Failed: ['  || errMsg ||  '] nSvrId = ' || nSvrId , NULL, NULL, nSvrId);
END CaptureViews;

PROCEDURE CaptureStoredPrograms
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  SetStatus('Capturing Stored Programs');
  INSERT
  INTO MD_STORED_PROGRAMS
    (
      id,
      schema_id_fk,
      programtype,
      name,
      native_sql,
      "LANGUAGE",
      comments
    )
    (SELECT a.objid_gen,
        s.suid_gen,
        CASE
          WHEN a.type = 'P'
          THEN 'PROCEDURE'
          ELSE 'FUNCTION'
        END,
        a."NAME",
        b.DEFINITION,
        'MSTSQL',
        p.value comments
      FROM STAGE_SS2K5_OBJECTS a,
        STAGE_SS2K5_SQL_MODULES b,
        stage_SS2K5_schemas s,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE ( a.type     = 'P'
      OR a.type          = 'FN'
      OR a.type          = 'TF'
      OR a.type          = 'IF')
      AND a."OBJECT_ID"  = b."OBJECT_ID"
      AND a.is_ms_shipped=0
      AND s.schema_id    = a.schema_id
      AND EXISTS
        (SELECT 1 FROM md_schemas mds WHERE mds.id=s.suid_gen
        )
      AND a.svrid_fk       = nSvrId
      AND b.svrid_fk       = nSvrId
      AND s.svrid_fk       = nSvrId
      AND a.dbid_gen_fk    = b.dbid_gen_fk
      AND s.dbid_gen_fk    = b.dbid_gen_fk
      AND p.class(+)       = 1
      AND p.svrid_fk(+)    = nSvrId
      AND p.MAJOR_ID(+)    = a.object_id
      AND p.MINOR_ID(+)    = 0
      AND p.dbid_gen_fk(+) = a.dbid_gen_fk
    ) ;

  INSERT
  INTO MD_ADDITIONAL_PROPERTIES
    (
      connection_id_fk,
      ref_id_fk,
      ref_type,
      property_order,
      prop_key,
      "VALUE"
    )
    (SELECT a.svrid_fk,
        a.objid_gen,
        'MD_STORED_PROGRAMS',
        1,
        'TYPE',
        CASE
          WHEN (a.type = 'FN')
          THEN 'SCALAR FUNCTION'
          WHEN (a.type = 'TF')
          THEN 'TABLE FUNCTION'
          ELSE
            /* IF */
            'INLINED T. FUNCTION'
        END
      FROM STAGE_SS2K5_OBJECTS a,
        stage_SS2K5_schemas s
      WHERE ( a.type     = 'FN'
      OR a.type          = 'TF'
      OR a.type          = 'IF')
      AND a.is_ms_shipped=0
      AND s.schema_id    = a.schema_id
      AND EXISTS
        (SELECT 1 FROM md_schemas mds WHERE mds.id=s.suid_gen
        )
      AND a.svrid_fk    = nSvrId
      AND s.svrid_fk    = nSvrId
      AND s.dbid_gen_fk = a.dbid_gen_fk
    ) ;
EXCEPTION
    WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureStoredPrograms Failed: ['  || errMsg ||  '] nSvrId = ' || nSvrId , NULL, NULL, nSvrId);
END CaptureStoredPrograms;

PROCEDURE CaptureTriggers
IS
      errMsg VARCHAR2(4000) := NULL;
BEGIN
  SetStatus('Capturing Triggers');
  INSERT
  INTO MD_TRIGGERS
    (
      "ID",
      table_or_view_id_fk,
      trigger_on_flag,
      trigger_name,
      native_sql,
      "LANGUAGE",
      comments
    )
    (SELECT a.objid_gen,
        (
        CASE
          WHEN (v.type = 'V')
          THEN v.objid_gen
          ELSE
            (SELECT t.objid_gen
            FROM stage_ss2k5_tables t
            WHERE t.object_id = a.parent_object_id
            AND t.svrid_fk    = nSvrId
            AND t.dbid_gen_fk = a.dbid_gen_fk
            )
        END),
        CASE
          WHEN (v.type = 'V')
          THEN 'V'
          ELSE 'T'
        END,
        a."NAME",
        b.DEFINITION,
        'MSTSQL',
        p.value comments
      FROM STAGE_SS2K5_OBJECTS a,
        STAGE_SS2K5_SQL_MODULES b,
        STAGE_SS2K5_objects v,
        STAGE_SS2K5_SYSPROPERTIES p
      WHERE a."TYPE"     ='TR'
      AND v.object_id    = a.parent_object_id
      AND a."OBJECT_ID"  = b."OBJECT_ID"
      AND a.is_ms_shipped=0
      AND ((EXISTS
        (SELECT 1 FROM md_views v WHERE v.id = v.objid_gen
        ))
      OR (EXISTS
        (SELECT 1
        FROM md_tables tt,
          stage_ss2k5_tables ts
        WHERE tt.id       = ts.objid_gen
        AND ts.object_id  = v.object_id
        AND a.dbid_gen_fk = ts.dbid_gen_fk
        AND ts.svrid_fk   = nSvrId
        AND ts.NAME NOT IN ('sysdiagrams')
        ) ) )
      AND a.svrid_fk       = nSvrId
      AND b.svrid_fk       = nSvrId
      AND v.svrid_fk       = nSvrId
      AND a.dbid_gen_fk    = b.dbid_gen_fk
      AND v.dbid_gen_fk    = b.dbid_gen_fk
      AND p.class(+)       = 1
      AND p.svrid_fk(+)    = nSvrId
      AND p.MAJOR_ID(+)    = a.object_id
      AND p.MINOR_ID(+)    = 0
      AND p.dbid_gen_fk(+) = a.dbid_gen_fk
    ) ;
EXCEPTION
    WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureTriggers Failed: ['  || errMsg ||  '] nSvrId = ' || nSvrId , NULL, NULL, nSvrId);
END CaptureTriggers;
--actually drill down to the base type in column creation
--need to get UDT name mapping for procedure translation.

FUNCTION printUDTDef
  (
    basename VARCHAR2,
    p        NUMBER,
    s        NUMBER,
    m        NUMBER
  )

  RETURN VARCHAR2
IS
  StringOut VARCHAR2
  (
    200 CHAR
  )
  ;
  myPRECISION NUMBER
  (
    38,0
  )
  ;
  myscale NUMBER
  (
    38,0
  )
  ;
BEGIN
  StringOut:=basename;
  myPRECISION:=

  CASE

  WHEN ( ( p = 0 ) OR ( p IS NULL ) ) THEN
    SS2K5AllPlatform.getPrecision
    (
      basename,m,s
    )

  ELSE
    SS2K5AllPlatform.getPrecision
    (
      basename,p,s
    )

  END;
  myscale:=SS2K5AllPlatform.getnewscale
  (
    basename,

    CASE

    WHEN ( (p = 0 ) OR ( p IS NULL ) ) THEN
      m

    ELSE
      p

    END,s
  )
  ;

  IF
    (
      myscale IS NOT NULL
    )
    THEN
    StringOut:=StringOut||'('||myprecision||','||myscale||')';

  ELSE

    IF
      (
        (myPRECISION IS NOT NULL) AND (myPRECISION != -1 )
      )
      THEN --decision display max_len as a known value
      StringOut:=StringOut||'('||myprecision||')';

    END IF;

  END IF;

  RETURN StringOut;

END;

PROCEDURE CaptureUDT
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  SetStatus(' UDT');
  INSERT
  INTO MD_USER_DEFINED_DATA_TYPES
    (
      SCHEMA_ID_FK,
      DATA_TYPE_NAME,
      DEFINITION,
      NATIVE_SQL,
      NATIVE_KEY,
      COMMENTS,
      SECURITY_GROUP_ID,
      CREATED_ON,
      CREATED_BY,
      LAST_UPDATED_ON,
      LAST_UPDATED_BY
    )
    (SELECT ss.id,
        b.name,
        SS2K5ALLPLATFORM.printUDTDef(a.name, b.precision, b.scale, b."MAX_LENGTH"),
        SS2K5ALLPLATFORM.printUDTDef(a.name, b.precision, b.scale, b."MAX_LENGTH"),
        '0',
        pp.value,
        0,
        SYSDATE,
        NULL,
        NULL,
        NULL
      FROM STAGE_SS2K5_types a,
        STAGE_SS2K5_types b,
        STAGE_SS2K5_SCHEMAS s,
        md_schemas ss,
        STAGE_SS2K5_SYSPROPERTIES pp
      WHERE a.user_type_id = b.system_type_id
      AND b.user_type_id  != b.system_type_id
      AND b.schema_id      = s.schema_id
      AND s.suid_gen       = ss.id
      AND a.svrid_fk       = nSvrId
      AND b.svrid_fk       = nSvrId
      AND s.svrid_fk       = nSvrId
      AND a.dbid_gen_fk    = b.dbid_gen_fk
      AND s.dbid_gen_fk    = b.dbid_gen_fk
      AND pp.class(+)       = 6
      AND pp.svrid_fk(+)    = nSvrId
      AND pp.MAJOR_ID(+)    = b.user_type_id
      AND pp.MINOR_ID(+)    = 0
      AND pp.dbid_gen_fk(+) = b.dbid_gen_fk
    );
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureUDT Failed: ['  || errMsg ||  '] nSvrId: ' || nSvrId, NULL, NULL, nSvrId); 
END CaptureUDT;

PROCEDURE CaptureEntireStage
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  CaptureConnections;
  COMMIT;
  CaptureDatabases;
  COMMIT;
  CaptureSchemas;
  COMMIT;
  CaptureTables;
  COMMIT;
  CaptureColumns;
  COMMIT;
  CaptureConstraints;
  COMMIT;
  CaptureIndexes;
  COMMIT;
  CaptureViews;
  COMMIT;
  CaptureStoredPrograms;
  COMMIT;
  CaptureTriggers;
  COMMIT;
  CaptureUDT;
  COMMIT;
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'CaptureEntireStage Failed: ['  || errMsg ||  '] nSvrId: ' || nSvrId, NULL, NULL, nSvrId); 
END CaptureEntireStage;

PROCEDURE FixSysDatabases
IS
BEGIN
  NULL;

END FixSysDatabases;

PROCEDURE FixSysUsers
IS
BEGIN
  NULL;

END FixSysUsers;

PROCEDURE FixTables
IS
  errMsg VARCHAR2(4000) := NULL; 
  CURSOR curDb
  IS

    SELECT schema_id,
      DBID_GEN_FK,
      suid_gen
    FROM stage_ss2k5_schemas
    WHERE svrid_fk = nSvrId ;
BEGIN

  FOR r_c1 IN curDb
  LOOP
    BEGIN
    -- assuming 1 to 1 correspondance between suid and uid within a database

    UPDATE stage_ss2k5_tables
    SET schema_id_fk  = r_c1.suid_gen
    WHERE dbid_gen_fk = r_c1.dbid_gen_fk
    AND svrid_fk      = nSvrId
    AND schema_id     = r_c1.schema_id;
    EXCEPTION
       WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'FixTables Failed: individual schema fail ['  || errMsg ||  '] nSvrId:schema_id_fk = ' || nSvrId || ': ' || r_c1.suid_gen, NULL, NULL, nSvrId);
    END;
  END LOOP; -- schemas loop

EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line('Exception in FixTables');
  errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
  LogInfo(NULL, sev_err, 'FixTables Failed: Outer Loop Fail ['  || errMsg ||  '] nSvrId = ' || nSvrId , NULL, NULL, nSvrId);
END FixTables;

PROCEDURE FixColumns
IS
  errMsg VARCHAR2(4000) := NULL;
  CURSOR curDb
  IS

    SELECT objid_gen,
      object_id,
      DBID_GEN_FK
    FROM stage_ss2k5_tables
    WHERE svrid_fk = nSvrId ;
BEGIN

  FOR r_c1 IN curDb
  LOOP
    BEGIN
    -- assuming 1 to 1 correspondance between suid and uid within a database

    UPDATE stage_ss2k5_columns
    SET id_gen_fk   = r_c1.objid_gen
    WHERE object_id = r_c1.object_id --object_id is parent object, column_id is
      -- this ibject
    AND dbid_gen_fk = r_c1.dbid_gen_fk
    AND svrid_fk    = nSvrId;
    EXCEPTION
       WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'FixColumns Failed: individual column fail ['  || errMsg ||  '] nSvrId:id_gen_fk = ' || nSvrId || ': ' || r_c1.objid_gen , NULL, NULL, nSvrId);
    END;
  END LOOP; -- tables loop

EXCEPTION

WHEN OTHERS THEN
  DBMS_OUTPUT.put_line('Exception in FixColumns');
  errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
  LogInfo(NULL, sev_err, 'FixColumns Failed: outside loop fail ['  || errMsg ||  '] nSvrId = ' || nSvrId, NULL, NULL, nSvrId);
END FixColumns;

PROCEDURE FixIndexes
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
NULL;
EXCEPTION

WHEN OTHERS THEN
  DBMS_OUTPUT.put_line('Exception in FixIndexes');
  errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
  LogInfo(NULL, sev_err, 'FixIndexes Failed: outside loop fail ['  || errMsg ||  '] nSvrId = ' || nSvrId, NULL, NULL, nSvrId);
END FixIndexes;

PROCEDURE UpdateScratchModel
IS

  CURSOR curDerived
  IS

    SELECT *
    FROM MD_DERIVATIVES
    WHERE DERIVED_TYPE      IN ('MD_VIEWS', 'MD_STORED_PROGRAMS', 'MD_TRIGGERS')
    AND ( derivative_reason IS NULL
    OR derivative_reason    <> 'SCRATCH' );

  v_TransSQL CLOB;
  v_SourceSQL CLOB;
BEGIN
  NULL;

END;

PROCEDURE FixStageKeyReferences
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  FixSysDatabases;
  FixSysUsers;
  FixTables;
  FixColumns;
  FixIndexes;
EXCEPTION
  WHEN OTHERS THEN
     errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
     LogInfo(NULL, sev_err, 'FixStageKeyReferences Failed: ['  || errMsg ||  '] nSvrId = ' || nSvrId , NULL, NULL, nSvrId);
END;

Procedure DoAndWriteError(execvarchar varchar2)
is
  errMsg VARCHAR2(4000) := NULL;
BEGIN
execute immediate execvarchar;
EXCEPTION

WHEN OTHERS THEN
  DBMS_OUTPUT.put_line('Exception in DoAndWriteError:'||execvarchar);
  errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
  LogInfo(NULL, sev_warn, 'DoAndWriteError Failed: ['  || errMsg ||  '] nSvrId:execvarchar = ' || nSvrId || ': '|| execvarchar , NULL, NULL, nSvrId);
END DoAndWriteError;

PROCEDURE RegisterSQLServerPlugin
IS
  errMsg VARCHAR2(4000) := NULL;
BEGIN

  INSERT
  INTO md_additional_properties
    (
      connection_id_fk,
      ref_id_fk,
      ref_type,
      property_order,
      prop_key,
      "VALUE"
    )
    VALUES
    (
      nSvrId,
      nSvrId,
      'MD_CONNECTIONS',
      0,
      'PLUGIN_ID',
      pluginClass -- could be 2005 or 2008 
    );
  COMMIT;
EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
        LogInfo(NULL, sev_err, 'RegisterSQLServerPlugin Failed: ['  || errMsg ||  '] nSvrId: ' || nSvrId, NULL, NULL, nSvrId); 
END;

FUNCTION StageCapture
  (
    projectId      NUMBER,
    pluginClassIn   varchar2,
    projExists BOOLEAN:=FALSE,
    p_scratchModel BOOLEAN := FALSE
  )

  RETURN VARCHAR2
IS
  ret_val NAME_AND_COUNT_ARRAY;
  scratchConnId         NUMBER :=0;
  connectionStatsResult NUMBER;
  errMsg VARCHAR2(4000) := NULL;
BEGIN
  nSvrId := NULL;
  pluginClass := pluginClassIn;--could be 2005 or 2008
  nProjectId := projectId;
  bProjectExists:=projExists;
  SELECT svrid INTO nSvrId FROM STAGE_SERVERDETAIL WHERE project_id = projectId;
  -- Initialize the log status table
  INSERT INTO migrlog(parent_log_id, log_date, severity, logtext, phase, ref_object_id, ref_object_type, connection_id_fk) 
  VALUES(NULL, systimestamp, 666, 'Capture Started', 'CAPTURE', NULL, NULL, projectId);
  COMMIT; 
  FixStageKeyReferences;
  CaptureEntireStage;
  RegisterSQLServerPlugin;
  connectionStatsResult:=MIGRATION.gatherConnectionStats(nSvrId, 'This is a capture model created using the enterprise estimation cmd tool');
  COMMIT;
  MIGRATION.POPULATE_DERIVATIVES_TABLE(nSvrId);
  COMMIT;

  IF p_scratchModel = TRUE THEN
    scratchConnId  := MIGRATION.copy_connection_cascade(p_connectionid => nSvrId, p_scratchModel => TRUE);
    ret_val        := migration.transform_all_identifiers(scratchConnId, '', TRUE);
    UpdateScratchModel;
    connectionStatsResult:=MIGRATION.gatherConnectionStats(scratchConnId, 'This is a scratch model used for analysis and estimation');
    COMMIT;

  END IF;
  DELETE migrlog WHERE phase='CAPTURE' AND severity = 666 AND connection_id_fk = projectId;
  COMMIT; 
  --IF exceptionOccurred = TRUE THEN
  --  RAISE CaptureNotClean;
  --END IF;
  RETURN ''|| nSvrId||'/'||scratchConnId;
EXCEPTION
  WHEN CaptureNotClean THEN
      RAISE CaptureNotClean;
  WHEN OTHERS THEN
      errMsg := LOCALSUBSTRB(LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_STACK) || ' ' || LOCALSUBSTRB(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE));
      LogInfo(NULL, sev_err, 'StageCapture Failed: ['  || errMsg ||  '] nSvrId: ' ||nSvrId, NULL, NULL, nSvrId);
      RAISE CaptureNotClean;
END StageCapture;

END SS2K5ALLPLATFORM;
/