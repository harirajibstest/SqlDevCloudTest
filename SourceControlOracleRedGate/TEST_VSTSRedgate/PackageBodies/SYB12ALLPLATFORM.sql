CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate".SYB12ALLPLATFORM AS   
  -- TYPE split_tbl_type IS TABLE OF VARCHAR2(32767);
   TYPE split_varray_type IS VARRAY(255) OF VARCHAR2(32767);
   TYPE ref_cur_type IS REF CURSOR;
   TYPE key_array is VARRAY(20) OF NUMBER;
   TYPE str_array_type IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
   nProjectId  NUMBER;
   sev_err CONSTANT NUMBER :=2;
   sev_warn CONSTANT NUMBER :=4;
   sev_others CONSTANT NUMBER :=8;
   projectExist BOOLEAN;
   exceptionOccurred BOOLEAN :=FALSE;
   nSvrId NUMBER; -- This is the captured connection id
   pluginClass varchar2(500) := null;
   progressStatus varchar2(1000) := null;
   CaptureNotClean EXCEPTION;

----------------------- bitwise operation util begin ---------

   BaseFmt constant char(12) := 'XXXXXXXXXXXX';
   RawToNumberFMT constant char(14) := 'XX' || BaseFmt;
   NumberToRawFMT constant char(14) := '0X' || BaseFmt;

FUNCTION LOCALSUBSTRB(
    vin  VARCHAR2)  RETURN VARCHAR2
AS
  v VARCHAR2(4000 CHAR):=SUBSTR(vin,1,4000);
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


PROCEDURE LogInfo( parent_log_id NUMBER,
                   severity NUMBER,
                   logtext VARCHAR2,
                   ref_obj_id NUMBER,
                   ref_obj_type VARCHAR2,
                   connection_id NUMBER)
 IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   errmsg  varchar2(4000) := null;
   fit_logtext varchar2(4000) := LOCALSUBSTRB(logtext);
 BEGIN
   exceptionOccurred :=TRUE;
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
                fit_logtext, 
                'Capture', 
                ref_obj_id, 
                ref_obj_type, 
                connection_id) ;
   COMMIT;
 EXCEPTION
 when others then
   errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
   DBMS_OUTPUT.put_line('Log Err: ['  || errMsg       || ']'
                                    || parent_log_id   || ':' 
                                    || severity     || ':'
                                    || logtext      || ':Capture:'
                                    || ref_obj_id   || ':'
                                    || ref_obj_type || ':'
                                    || connection_id);
 END LogInfo;


   FUNCTION ToRaw(p_Value NUMBER) RETURN RAW 
   IS
     errMsg VARCHAR2(4000) := NULL;
   BEGIN
   IF(P_VALUE < 0) THEN
    RETURN HexToRaw(LTRIM(To_Char(0, NumberToRawFMT)));
   END IF;
     RETURN HexToRaw(LTRIM(To_Char(p_Value, NumberToRawFMT)));
   EXCEPTION
     when others then
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 'ToRaw Failed: ['  || errMsg || '] ' || p_Value, NULL, NULL, nSvrId);
   END;

   FUNCTION BitOr(p_Value1 NUMBER, p_Value2 NUMBER) RETURN NUMBER
   IS
     errMsg VARCHAR2(4000) := NULL;
   BEGIN
     RETURN To_Number(UTL_RAW.bit_or(ToRaw(p_Value1), ToRaw(p_Value2)), RawToNumberFMT);
   EXCEPTION
     when others then
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 'BitOr Failed: ['  || errMsg || '] ' || p_Value1 || ': ' || p_Value2, NULL, NULL, nSvrId);     
   END;

   FUNCTION BitAnd(p_Value1 number, p_Value2 number) RETURN NUMBER
   IS
      errMsg VARCHAR2(4000) := NULL;
   BEGIN
     return To_Number(UTL_RAW.bit_and(ToRaw(p_Value1), ToRaw(p_Value2)), RawToNumberFMT);
   EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 'BitAnd Failed: ['  || errMsg ||  '] ' || p_Value1 || ': ' || p_Value2, NULL, NULL, nSvrId);          
   END;

----------------------- bitwise operation util end ---------
----------------------- n type convert util begin ----------------

   FUNCTION ConvertFromNType(nType VARCHAR2) RETURN VARCHAR2
   IS
     errMsg VARCHAR2(4000) := NULL;
   BEGIN
      IF 'INTN' = UPPER(nType) THEN
         RETURN 'int';
      ELSIF 'FLOATN' = UPPER(nType) THEN
         RETURN 'float';
      ELSIF 'DATETIMN' = UPPER(nType) THEN
         RETURN 'date'; 
      ELSIF 'MONEYN' = UPPER(nType) THEN         
         RETURN 'money';
      ELSIF 'DECIMALN' = UPPER(nType) THEN   
         RETURN 'decimal';
      ELSIF 'NUMERICN' = UPPER(nType) THEN   
         RETURN 'numeric';
      ELSIF 'DATEN' = UPPER(nType) THEN
         RETURN 'date';
      ELSIF 'TIMEEN' = UPPER(nType) THEN
         RETURN 'time';
      ELSIF 'UINTN' = UPPER(nType) THEN
         RETURN 'unit';
      END IF ;      
         RETURN nType;
   EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 'ConvertFromNType Failed: [' || errMsg || '] ' || nType, NULL, NULL, nSvrId);              
   END ConvertFromNType;

----------------------------- n type convert util end ---------------     

   FUNCTION GetDescription(basename VARCHAR2, precisionin NUMBER, scalein NUMBER, lengthin NUMBER) RETURN VARCHAR2 
   is
     basenameNoN VARCHAR2(200);
     errMsg VARCHAR2(4000) := NULL;
     precision NUMBER := null;
     scale NUMBER := null;
     retDef VARCHAR2(400);
   BEGIN
     basenameNoN := ConvertFromNType(LOWER(basename));
     --need to handle the 
     --precision scale types:numeric (p, s) decimal (p, s)
     --precision types:float (precision)
     --length types: char(n)varchar(n)binary(n)varbinary(n)
     --length /1 types (best estimate): nchar(n) nvarchar(n) might oversize nchar & nvarche - checked @@NCHARSIZE on our iso machines = 1
     IF ((basenameNoN = 'numeric') OR (basenameNoN = 'decimal')) THEN
       precision := precisionin;
       scale := scalein;
     ELSIF (basenameNoN = 'float') THEN
       precision := precisionin;
     ELSIF ((basenameNoN = 'char') OR (basenameNoN = 'varchar') OR (basenameNoN = 'binary') OR (basenameNoN = 'varbinary')) THEN
       precision := lengthin;
     ELSIF ((basenameNoN = 'nchar') OR (basenameNoN = 'nvarchar')) THEN
       IF (lengthin IS NOT NULL) THEN
         precision := lengthin;-- /2;
       END IF;
     END IF;
     retDef:=basename;
     IF (precision is not null) THEN 
       IF (scale is not null) THEN
         retDef := retDef || '(' || precision || ',' || scale || ')';
       ELSE
         retDef := retDef || '(' || precision || ')';
       END IF;
     END IF;
     RETURN retDef;
   EXCEPTION
     WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'GetDescription Failed: [' || errMsg || '] ' || basename || ':' || 
                precisionin || ':' || scalein || ':' || lengthin, 
                NULL, NULL, nSvrId);                   
   END GetDescription;

 PROCEDURE SetStatus(msg VARCHAR2)
 IS
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

/*
FUNCTION GetLogIdForObject(obj_id NUMBER) RETURN NUMBER
IS
  log_id NUMBER;
  errMsg VARCHAR2(4000);
BEGIN
   SELECT id INTO log_id FROM migrlog WHERE ref_object_id = obj_id;
   RETURN log_id;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL;
   WHEN OTHERS THEN
         errMsg := SQLERRM;
         DBMS_OUTPUT.put_line('Unable to GetLogIdForObject: ['  || errMsg       || ']'
                               || 'Object Id = ' || obj_id);         
END GetLogIdForObject;
*/

 FUNCTION GetStatus(iid INTEGER) RETURN varchar2
 IS
    status VARCHAR2(4000);
    errMsg VARCHAR2(2000);
 BEGIN
    SELECT logtext INTO status FROM migrlog WHERE severity = 666 AND phase = 'CAPTURE' AND connection_id_fk = iid;    
    RETURN status; 
EXCEPTION 
  when others then
     errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
     dbms_output.put_line('Status Message : ' || errMsg);
 END GetStatus;

   FUNCTION split_str2(srcStr VARCHAR2, delim CHAR := ',') RETURN split_varray_type
   IS
     nIdx    pls_integer;
     errMsg VARCHAR2(4000) := NULL;
     vlist    varchar2(32767) := srcStr;
     myvarray split_varray_type;
     cnt pls_integer := 1;
   BEGIN
      myvarray := split_varray_type();
      LOOP
      BEGIN
         IF  cnt < myvarray.limit 
         THEN
             myvarray.EXTEND;
         END IF;

         nIdx := INSTR(vlist,delim);
         IF nIdx > 0 THEN
            myvarray(myvarray.last) := SUBSTR(vlist,1,nIdx-1);
            vlist := SUBSTR(vlist,nIdx + LENGTH(delim));
         ELSE
            myvarray(myvarray.last) := vlist;
            EXIT;
         END IF;         
         cnt := cnt+1;
      EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'split_str2 Failed: [' || errMsg || '] '|| srcStr || ':' || 
                delim, 
                NULL, NULL, nSvrId); 
         cnt :=cnt + 1;         
      END;
      END LOOP;
      RETURN myvarray;
   END split_str2;

----------------------- split util begin -------------------
/*
   FUNCTION split_str(srcStr VARCHAR2, delim CHAR := ',') RETURN split_tbl_type PIPELINED
   IS
     nIdx    pls_integer;
     vlist    varchar2(32767) := srcStr;
   BEGIN
      LOOP      
         nIdx := INSTR(vlist,delim);
         IF nIdx > 0 THEN
            PIPE ROW (SUBSTR(vlist,1,nIdx-1));
            vlist := SUBSTR(vlist,nIdx + LENGTH(delim));
         ELSE
            PIPE ROW (vlist);
            EXIT;
         END IF;
      END LOOP;
   END split_str;
*/
----------------------- split util end ---------------------


----------------------------- EndsWith string util begin -------------

   FUNCTION EndsWithStr(srcStr CHAR, tgtStr CHAR) RETURN INTEGER
   IS
     errMsg VARCHAR2(4000);
     nPatPos INTEGER :=0; --Doesn't end with the str
     nSrcStrLen INTEGER := LENGTH(srcStr);
     nTgtStrLen INTEGER := LENGTH(tgtStr);
   BEGIN
      IF nSrcStrLen != 0 
         AND nTgtStrLen != 0 
         AND nSrcStrLen IS NOT NULL 
         AND nTgtStrLen IS NOT NULL THEN         
           nPatPos := InStr(srcStr, tgtStr, (nSrcStrLen - nTgtStrLen));
      END IF;
      RETURN nPatPos;
  EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'EndsWithStr Failed: [' || errMsg || '] ' || srcStr || ':' || 
                tgtStr, 
                NULL, NULL, nSvrId);          

   END;
----------------------------- EndsWith string util end ---------------


   FUNCTION GetColIdFromName(svrId NUMBER, dbId NUMBER, tblId NUMBER, colName VARCHAR2) RETURN INTEGER
   IS
      curColId ref_cur_type;
      nColId INTEGER;
      errMsg VARCHAR2(4000) := NULL;
      --upperName VARCHAR2(300);
   BEGIN
      --upperName := UPPER(colName);
      OPEN curColId FOR 'SELECT COLID_GEN FROM stage_syb12_syscolumns
             WHERE SVRID_FK = :1 
                AND DBID_GEN_FK = :2 
                AND ID_GEN_FK = :3
                AND LOWER(NAME) = LOWER(:4)' USING svrId, dbId, tblId, colName;
      FETCH curColId INTO nColId;
      CLOSE curColId;
      RETURN nColId;
  EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'GetColIdFromName Failed: [' || errMsg || '] ' || svrId || ':' || 
                dbId || ':' || tblId || ':' || colName, 
                NULL, NULL, nSvrId);          
   END GetColIdFromName;

   PROCEDURE CaptureConnections
   IS
      errMsg VARCHAR2(4000) := NULL;
   BEGIN
      -- create project

      if (projectExist = FALSE)
      THEN            
      INSERT INTO md_projects("ID", project_name, comments)
           (
              SELECT project_id, project_name, comments FROM
                 stage_serverdetail WHERE project_id = nProjectId
                 AND NOT EXISTS (SELECT 1 FROM md_projects WHERE "ID" = nProjectId)
           ) ; 
      END IF;
      --capture connections
      INSERT INTO md_connections("ID", project_id_fk, username, dburl, "NAME")
      (
         SELECT SVRID, nProjectId, username, dburl, db_name 
         FROM stage_serverdetail WHERE project_id = nProjectId
      ) ;
  EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'CaptureConnections Failed: [' || errMsg || '] ' || 'Project Id : ' || nProjectId, 
                NULL, NULL, nSvrId);                
   END CaptureConnections;

   PROCEDURE CaptureDatabases
   IS 
     errMsg VARCHAR2(4000) := NULL;
   BEGIN
      INSERT INTO md_catalogs("ID", connection_id_fk, catalog_name,
        dummy_flag)
      (
         SELECT dbid_gen, svrid_fk, "NAME", 'N' 
           FROM stage_syb12_sysdatabases
             WHERE svrid_fk = nSvrId
      );
  EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'CaptureDatabases Failed: [' || errMsg || '] ' || 'Server Id : ' || nSvrId, 
                NULL, NULL, nSvrId);        
   END CaptureDatabases;

   PROCEDURE CaptureSchemas
   IS
     errMsg VARCHAR2(4000) := NULL;
   BEGIN
      INSERT INTO md_schemas("ID", catalog_id_fk, "NAME")
          (
            -- Capture only those users who own atleast 1 object in the database
            -- Consciously ignoring users with on owned objects during schema capture
             SELECT A.suid_gen, A.dbid_gen_fk, A."NAME"
             FROM stage_syb12_sysusers A
             WHERE A.svrid_fk = nSvrId 
               AND A.suid>0 
               AND A.db_uid IN (SELECT DISTINCT db_uid FROM stage_syb12_sysobjects)             
          );
  EXCEPTION
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'CaptureSchemas Failed: [' || errMsg || '] ' || 'Server Id : ' || nSvrId, 
                NULL, NULL, nSvrId);           
   END;

   PROCEDURE CaptureTables
   IS 
         errMsg VARCHAR2(4000) := null;
   BEGIN
      --SetStatus('Capturing Tables');
      INSERT INTO md_tables("ID", schema_id_fk, table_name, qualified_native_name)
          (
             SELECT objid_gen, suid_gen_fk, A."NAME", C."NAME" || '.' || B."NAME" || '.' || A."NAME"
             FROM stage_syb12_sysobjects A, stage_syb12_sysusers B, stage_syb12_sysdatabases C
             WHERE A.db_type = 'U '
                 AND A.db_uid = B.db_uid
                 AND A.svrid_fk = B.svrid_fk
                 AND A.dbid_gen_fk = B.dbid_gen_fk
                 AND B.svrid_fk = C.svrid_fk
                 AND B.dbid_gen_fk = C.dbid_gen
                 AND B.suid>0 
                 AND A.svrid_fk = nSvrId
          );           	
    EXCEPTION 
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 
                'CaptureTables Failed: [' || errMsg || '] ' || 'Server Id : ' || nSvrId, 
                NULL, NULL, nSvrId);
   END CaptureTables;

   PROCEDURE CaptureColumns
   IS
     --curObjCols ref_cur_type;
     --objColSql VARCHAR2(4000) := '';
     CURSOR curObjCols IS SELECT B.svrid_fk, B.dbid_gen_fk, B.id_gen_fk, B.colid_gen,B."LENGTH",
           C."NAME" coltypename, B."NAME", B."PREC", B."SCALE",  B.status nullable, B.cdefault, B.status, B.db_type, B.usertype, B.colid
        FROM stage_syb12_sysobjects A, stage_syb12_syscolumns B, stage_syb12_systypes C, stage_syb12_sysusers D  
        WHERE A.objid_gen = B.id_gen_fk 
        AND A.dbid_gen_fk = B.dbid_gen_fk
        AND A.svrid_fk = B.svrid_fk
        AND A.dbid_gen_fk = C.dbid_gen_fk
        AND A.svrid_fk = C.svrid_fk
        AND B.usertype = C.usertype
        AND A.db_uid = D.db_uid
        AND A.svrid_fk = D.svrid_fk
        AND A.dbid_gen_fk = D.dbid_gen_fk
        AND D.suid>0         
        AND A.svrid_fk = nSvrId
        AND A.DB_TYPE = 'U '
        ORDER BY B.colid;

     --nColOrder INTEGER :=1; -- column index is 1 based.
     cNullable CHAR(1) := 'Y';
     vDefaultValue VARCHAR2(4000);
     vDefaultValPiece VARCHAR2(300);
     vColType VARCHAR2(4000);

     curDefaultVal ref_cur_type;
     defaultStart  pls_integer;
     defaultEnd pls_integer;

     errMsg VARCHAR2(4000);
   BEGIN
     -- Need to work the loop as there is procedural logic involved in using the length vs precision
     -- and generating the column order
         --SetStatus('Capturing Table columns');
      FOR r_c1 IN curObjCols 
      LOOP

          IF BitAnd(r_c1.nullable, 8) = 8 THEN
             cNullable := 'Y';
          ELSE
             cNullable := 'N';
          END IF;

          IF r_c1.usertype > 100 THEN  -- Handle user defined types
          BEGIN
                SELECT MAX("NAME") INTO vColType FROM STAGE_SYB12_SYSTYPES 
                 WHERE usertype < 100 -- SUSPECIOUS: condition reversed from above.  Check java code 
                     AND db_type = r_c1.db_type
                     AND "NAME" NOT IN ('longsysname', 'sysname', 'nchar', 'nvarchar', 'timestamp')
                     AND dbid_gen_fk = r_c1.dbid_gen_fk;      

         EXCEPTION
              WHEN OTHERS THEN
                 errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                 LogInfo(NULL, sev_err, 'CaptureColumns: Unable to Handle UDT: ['  || errMsg ||  '] db_type:dbid_gen_fk ' 
                                                               || r_c1.db_type || ': ' || r_c1.dbid_gen_fk , NULL, NULL, nSvrId);          
          END;               
          ELSE
             vColType := ConvertFromNType(r_c1.coltypename);
             -- TODO: Need to log conversion of type as a warning in the log table
          END IF;

          IF r_c1.cdefault != 0 THEN
           BEGIN --USE THE STAGE_TRANSLATED_SQL as it rollsup the text
              OPEN curDefaultVal FOR  SELECT text  
                  FROM stage_syb12_syscomments 
                     WHERE "ID" = r_c1.cdefault
                  AND dbid_gen_fk = r_c1.dbid_gen_fk   ORDER BY colid; -- delebrately using IS in the WHERE caluse as it is easy to work with syb generated id here
                  FETCH curDefaultVal INTO vDefaultValPiece;
              LOOP
                 EXIT WHEN curDefaultVal%NOTFOUND;
                 vDefaultValue := CONCAT(vDefaultValue, ' ');
                 vDefaultValue := CONCAT(vDefaultValue, vDefaultValPiece);
                 FETCH curDefaultVal INTO vDefaultValPiece;
              END LOOP;
              CLOSE curDefaultVal;
              defaultStart := INSTR(vDefaultValue,'"',1,1);
              defaultEnd := INSTR(vDefaultValue,'"',-1,1);
              IF defaultStart <= 0 THEN
              defaultStart := INSTR(vDefaultValue,'''',1,1);
              defaultEnd := INSTR(vDefaultValue,'''',-1,1);
              END IF;
              IF defaultStart <= 0 THEN
                vDefaultValue := TRIM(vDefaultValue);
                defaultStart := INSTR(vDefaultValue,' ',-1,1);  
                IF defaultStart > 0 THEN
                  vDefaultValue:= SUBSTR(vDefaultValue,defaultStart+1,LENGTH(vDefaultValue)-defaultStart);
                END IF;
              ELSE
                vDefaultValue := SUBSTR(vDefaultValue,defaultStart+1,defaultEnd -defaultStart -1);
              END IF;

              -- LENGTH('') Result: NULL :  defaultvalue is ''
              -- Bug 20353103 - EMPTY STRING NOT CONVERTED TO SINGLE SPACE DURING MIGRATION 
              IF length(vDefaultValue) is NULL THEN
                        vDefaultValue := CONCAT(vDefaultValue, ' ');
              END IF;

           EXCEPTION  
              WHEN NO_DATA_FOUND THEN
               NULL;  -- dont do anything
              when others then
                 errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                 LogInfo(NULL, sev_err, 'CaptureColumns: stage_syb12_syscomments cursor issue: ['  || errMsg ||  ']  r_c1.cdefault:r_c1.dbid_gen_fk:vDefaultValue: ' 
                                                         || r_c1.cdefault || ':' || r_c1.dbid_gen_fk || ':' || vDefaultValue, NULL, NULL, nSvrId);          
           END;
          END IF;

          BEGIN
            IF BitAnd(r_c1.status, 128) = 128 THEN -- Handle identity column capture
               INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                     ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                     VALUES(r_c1.svrid_fk, r_c1.colid_gen, 'MD_COLUMNS', r_c1.colid, 'SEEDVALUE', 1);
            END IF;
          EXCEPTION
             when others then
                 errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                 LogInfo(NULL, sev_err, 'CaptureColumns: Identity column issue: ['  || errMsg ||  ']  r_c1.svrid_fk:r_c1.colid_gen:r_c1.colid ' 
                                                                   || r_c1.svrid_fk || ':' || r_c1.colid_gen || ':' || r_c1.colid, NULL, NULL, nSvrId);          
          END;

          BEGIN
            IF r_c1."PREC" = 0 OR r_c1."PREC" IS NULL THEN -- use length
                INSERT INTO MD_COLUMNS("ID", table_id_fk, column_name, 
                       column_order, column_type, "PRECISION", "SCALE", nullable, default_value)
                       VALUES
                       ( r_c1.colid_gen, r_c1.id_gen_fk, r_c1."NAME", r_c1.colid, 
                           vColType, r_c1."LENGTH", r_c1."SCALE", cNullable, vDefaultValue
                       );
            ELSE -- use precision
                INSERT INTO MD_COLUMNS("ID", table_id_fk, column_name, 
                       column_order, column_type, "PRECISION", "SCALE", nullable, default_value)
                       VALUES
                       ( r_c1.colid_gen, r_c1.id_gen_fk, r_c1."NAME", r_c1.colid, 
                           vColType, r_c1."PREC", r_c1."SCALE", cNullable, vDefaultValue
                       );          
            END IF;
          EXCEPTION
             WHEN OTHERS THEN
                 errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                 LogInfo(NULL, sev_err, 'CaptureColumns: md_columns insert issue: ['  || errMsg ||  ']  r_c1."PREC":r_c1.colid_gen:r_c1.id_gen_fk:r_c1."NAME":r_c1.colid:vColType:r_c1."SCALE":cNullable:vDefaultValue:r_c1."LENGTH" ' 
                                                                   || r_c1."PREC" || ':' || r_c1.colid_gen || ':' || r_c1.id_gen_fk || ':' || r_c1."NAME" || ':' || r_c1.colid
                                                                   || ':' || vColType || ':' || r_c1."SCALE" || ':' || cNullable || ':' || vDefaultValue || ':' || r_c1."LENGTH", NULL, NULL, nSvrId);          
          END;
          vDefaultValue :=''; -- reset it for the next iteration.
          --nColOrder := nColOrder + 1;
      END LOOP;
    EXCEPTION 
              WHEN OTHERS THEN
                 errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                 LogInfo(NULL, sev_err, 'CaptureColumns Failed: Unable to Open master cursor: ['  || errMsg ||  ']  nSvrId: ' ||  nSvrId, NULL, NULL, nSvrId);          
   END CaptureColumns;

   /*
   PROCEDURE ProcessCheckConstraint(svrId NUMBER, 
               dbId NUMBER, tblId NUMBER, 
               constraint_name VARCHAR2, db_definition VARCHAR2)
   IS
      vConstText VARCHAR2(4000);
   BEGIN
            SetStatus('Capturing check constraints');
      vConstText := SUBSTR(db_definition, INSTR(db_definition, '(')+1,LENGTH(db_definition)-1);
      INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, "LANGUAGE", constraint_text)
      VALUES(constraint_name, 'CHECK', tblId, 'STSQL', vConstText);
   END ProcessCheckConstraint;

   PROCEDURE ProcessPkConstraint(svrId NUMBER, 
               dbId NUMBER, tblId NUMBER, 
               constraint_name VARCHAR2, db_definition VARCHAR2)
   IS
      curConsCols ref_cur_type;
      vConsId NUMBER;
      vConsCol VARCHAR2(300);
      nColId NUMBER;
      nColPos NUMBER :=1;
      consCols split_varray_type; 
   BEGIN
            SetStatus('Capturing Primary key constraint');
        INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, "LANGUAGE")
             VALUES(TRIM(constraint_name), 'PK' , tblId, 'STSQL') RETURNING "ID" INTO vConsId;
        --For each of the column shread the detail into the MD_CONSTRAINT_DETAILS
        --OPEN curConsCols FOR 'SELECT * FROM table(split_str(:1))' USING db_definition;
        --FETCH curConsCols INTO vConsCol;  
        consCols := split_str2(db_definition);
        LOOP
           EXIT WHEN nColPos > consCols.count;
           nColId := GetColIdFromName(svrId, dbId, tblId, TRIM(consCols(nColPos)));

           INSERT INTO MD_CONSTRAINT_DETAILS(constraint_id_fk, column_id_fk, detail_order) 
                 VALUES(vConsId, nColId, nColPos);
           nColPos := nColPos + 1;
        END LOOP;
        -- CLOSE curConsCols;
   END ProcessPkConstraint;

   PROCEDURE ProcessFkConstraint(svrId NUMBER, 
               dbId NUMBER, tblId NUMBER, 
               constraint_name VARCHAR2, db_definition VARCHAR2)
   IS
      nRefTblId NUMBER;
      nSchemaId NUMBER;
      nColId NUMBER;
      curConsCols ref_cur_type;
      vConsCol VARCHAR2(300);
      vRefTblName VARCHAR2(300);
      vTblName VARCHAR2(300);
      vConsDef_1 VARCHAR2(4000);
      vConsDef_2 VARCHAR2(4000);
      vRefColList VARCHAR2(4000);
      vColList VARCHAR2(4000);
      nPos NUMBER;
      nPos2 NUMBER;
      nConsId NUMBER;
      nColCnt NUMBER:=1;
      consCols split_varray_type;       
   BEGIN
            SetStatus('Capturing fk constraints');
      nPos := INSTR(db_definition, 'REFERENCES');

      IF nPos > 0 THEN
        vConsDef_1 := SUBSTR(db_definition, 1, nPos);       
        vConsDef_2 := SUBSTR(db_definition, nPos + LENGTH('REFERENCES'));

        nPos := INSTR(vConsDef_1, '(');
        nPos2 := INSTR(vConsDef_1, ')');
        vColList := SUBSTR(vConsDef_1, nPos +1, nPos2 - (nPos + 1)); 

        nPos := INSTR(vConsDef_2, '(');
        nPos2 := INSTR(vConsDef_2, ')');
        vRefTblName := TRIM(SUBSTR(vConsDef_2, 1, nPos));
        vRefColList := SUBSTR(vConsDef_2, nPos + 1, nPos2-(nPos + 1));

      ELSE
        RETURN; -- This should never happen
      END IF;

      SELECT suid_gen_fk INTO nSchemaId FROM stage_syb12_sysobjects A, 
                                             stage_syb12_sysconstraints B 
                            WHERE A.svrid_fk = B.svrid_fk 
                               AND B.svrid_fk = nSvrId 
                               AND A.dbid_gen_fk = B.dbid_gen_fk 
                               AND A."ID" = tblId;

      SELECT "NAME" INTO vTblName FROM stage_syb12_sysobjects A
                            WHERE A.svrid_fk = nSvrId
                               AND A.dbid_gen_fk = dbId
                               AND A."ID" = tblId;

      SELECT "ID" INTO nRefTblId FROM stage_syb12_sysobjects A
                            WHERE A.svrid_fk = nSvrid
                               AND A.dbid_gen_fk = dbId
                               AND A.SUID_GEN_FK = nSchemaId;

      -- Weed out self referencing foreign keys

      IF tblId = nRefTblId THEN
         RETURN;
      END IF;

      INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, reftable_id_fk,
                                   "LANGUAGE")                         
               VALUES (constraint_name, 'FOREIGN KEY', tblId, nRefTblId, 'STSQL')
                 RETURNING "ID" INTO nConsId;

      -- open the cursor for source columns          
      --OPEN curConsCols FOR 'SELECT * FROM table(split_str(:1))' USING vColList;               
      --FETCH curConsCols INTO vConsCol;
      consCols := split_str2(vColList); 
      -- source columns loop
      LOOP
        --EXIT WHEN curConsCols%NOTFOUND;
        EXIT WHEN nColCnt > consCols.count;
        nColId := GetColIdFromName(svrId, dbId, tblId, TRIM(consCols(nColCnt)));

        INSERT INTO MD_CONSTRAINT_DETAILS(constraint_id_fk, column_id_fk, detail_order) 
                VALUES ( nConsId, nColId, nColCnt);

        --FETCH curConsCols INTO vConsCol;
        nColCnt := nColCnt + 1;
      END LOOP;  
      -- CLOSE curConsCols;

      -- open the cursor for referenced columns
      --OPEN curConsCols FOR 'SELECT * FROM table(split_str(:1))' USING vRefColList;               
      --FETCH curConsCols INTO vConsCol;
      consCols := split_str2(vRefColList);
      nColCnt := 1; --re-initialize the counter for the ref columns loop
      LOOP
        --EXIT WHEN curConsCols%NOTFOUND;
       EXIT WHEN nColCnt > consCols.count;
        nColId := GetColIdFromName(svrId, dbId, tblId, TRIM(consCols(nColCnt)));

        INSERT INTO MD_CONSTRAINT_DETAILS(ref_flag, constraint_id_fk, column_id_fk, detail_order) 
                VALUES ('Y',  nConsId, nColId, nColCnt);

        --FETCH curConsCols INTO vConsCol;
        nColCnt := nColCnt + 1;
      END LOOP;  
      CLOSE curConsCols;                                    
   END ProcessFkConstraint;   

   PROCEDURE ProcessUkConstraint(svrId NUMBER, 
               dbId NUMBER, tblId NUMBER, 
               constraint_name VARCHAR2, db_definition VARCHAR2)
   IS
      curConsCols ref_cur_type;
      vConsId NUMBER;
      vConsCol VARCHAR2(300);
      nColId NUMBER;
      nColPos NUMBER :=1; 
      consCols split_varray_type;       
   BEGIN
            SetStatus('Capturing unique key constraint');
        INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, "LANGUAGE")
             VALUES(TRIM(constraint_name), 'UNIQUE' , tblId, 'STSQL') RETURNING "ID" INTO vConsId;
        --For each of the column shread the detail into the MD_CONSTRAINT_DETAILS
        --OPEN curConsCols FOR 'SELECT * FROM table(split_str(:1))' USING db_definition;
        --FETCH curConsCols INTO vConsCol;  
        consCols := split_str2(db_definition);
        LOOP
           EXIT WHEN nColPos > consCols.count;
           nColId := GetColIdFromName(svrId, dbId, tblId, TRIM(consCols(nColPos)));

           INSERT INTO MD_CONSTRAINT_DETAILS(constraint_id_fk, column_id_fk, detail_order) 
                 VALUES(vConsId, nColId, nColPos);
           nColPos := nColPos + 1;
        END LOOP;
        CLOSE curConsCols;
   END ProcessUkConstraint;   
   */

   PROCEDURE ProcessCheckConstraints(svrid NUMBER, db_id NUMBER, objid NUMBER)
   IS
      vConstText VARCHAR2(4000) := '';
      vIndex NUMBER(10) := 0;
      TYPE ConstraintRec IS RECORD
                        (
                            constraint_id NUMBER,
                            constraint_name varchar2(300)
                        );
      v_constRow ConstraintRec;
      v_commentRow stage_syb12_syscomments%ROWTYPE;
      CURSOR curConst(svrid NUMBER, db_id NUMBER, o_id NUMBER) IS SELECT a.constraint_gen constriant_id, b.name constraint_name 
                                    FROM stage_syb12_sysconstraints a, stage_syb12_sysobjects b
                                             WHERE a.table_id_gen_fk = o_id
                                                   AND a.svrid_fk = svrid
                                                   AND a.dbid_gen_fk = db_id
                                                   AND a.constraint_gen = b.objid_gen
                                                   AND BitAnd(b.sysstat, 15) = 7; -- last condition is some internal stuff copied from offline capture

      CURSOR curComment(svrid NUMBER, db_id NUMBER, constr_id NUMBER) IS SELECT * FROM stage_syb12_syscomments 
                                             WHERE id_gen_fk = constr_id
                                                   AND svrid_fk = svrid
                                                   AND dbid_gen_fk = db_id;

      errMsg VARCHAR2(4000);                                                   
   BEGIN
            --SetStatus('Capturing check constraint');
      OPEN curConst(svrid, db_id, objid);

      LOOP  -- Provision for multiple check constraints on a given table
        BEGIN
         FETCH curConst INTO v_constRow;
         EXIT WHEN curConst%NOTFOUND;

         --fetch all the constraint text and build the constraint
         OPEN curComment(svrid, db_id, v_constRow.constraint_id);

         LOOP
         BEGIN
            FETCH curComment INTO v_commentRow;
            EXIT WHEN curComment%NOTFOUND;
            vConstText := vConstText || v_commentRow.text || ' ';
         EXCEPTION
            WHEN OTHERS THEN
            errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
            LogInfo(NULL, sev_err, 'ProcessCheckConstraints: constraint text processing issue: ['  || errMsg ||  ']  svrid:db_id:objid:vConstText: ' ||  svrid || ':' || db_id || ':' || objid || ':' || vConstText, NULL, NULL, nSvrId);          
         END;
         END LOOP; --comment loop
         CLOSE curComment;
         vConstText := TRIM(vConstText);
         vIndex :=INSTR(vConstText, '(');
         IF vIndex >0 THEN
         	vConstText := SUBSTR(vConstText,vIndex+1,LENGTH(vConstText)-vIndex -1);
         END IF;
         INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, "LANGUAGE", constraint_text)
              VALUES(v_constRow.constraint_name, 'CHECK', objid, 'STSQL', vConstText);         

         vConstText := ''; -- reset the const text for next iteration.
        EXCEPTION
          WHEN OTHERS THEN
            errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
            LogInfo(NULL, sev_err, 'ProcessCheckConstraints: Individual constraint processing issue: ['  || errMsg ||  ']  svrid:db_id:objid:v_constRow.constraint_id: ' ||  svrid || ':' || db_id || ':' || objid || ':' || vConstText || ':' || v_constRow.constraint_id, NULL, NULL, nSvrId);
            vConstText := '';                                
        END;
      END LOOP; -- constraint loop
      CLOSE curConst;
    EXCEPTION 
      WHEN OTHERS THEN
         errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
         LogInfo(NULL, sev_err, 'ProcessCheckConstraints Failed: Unable to Open master cursor: ['  || errMsg ||  ']  svrid:db_id:objid: ' ||  svrid || ':' || db_id || ':' || objid, NULL, NULL, nSvrId);          
   END ProcessCheckConstraints;

   PROCEDURE ProcessPkUkConstraints(svrid NUMBER, db_id NUMBER, objid NUMBER)
   IS
        TYPE IndexRec IS RECORD
                (
                   keycnt  NUMBER, 
                   indid  NUMBER, 
                   status NUMBER, 
                   status2 NUMBER,
                   index_keys VARCHAR2(1000),
                   index_name VARCHAR2(300)
                );
        amIClustered BOOLEAN := FALSE;        
        idxRec IndexRec;
        v_constName VARCHAR2(300);

        v_consType VARCHAR2(300);

        v_constCols split_varray_type;

        vConsId  NUMBER;

        nColId  NUMBER;

        nColPos NUMBER;

        prop_cnt   pls_integer;
        CURSOR curIndex(svrid NUMBER, db_id NUMBER, objid NUMBER) IS SELECT keycnt, indid, status, status2, index_keys, index_name
            FROM stage_syb12_sysindexes
              WHERE  id_gen_fk = objid 
                  AND svrid_fk = svrid
                  AND dbid_gen_fk = db_id 
	                AND indid > 0  -- indicates that this is an index and not a table entry
	                 AND BitAnd(status2, 2) = 2 ;  -- Index supports primary key/unique declarative constraint

       errMsg VARCHAR2(4000);   
   BEGIN
      OPEN curIndex(svrid, db_id, objid);   
      LOOP
         BEGIN
           FETCH curIndex INTO idxRec;
           EXIT WHEN curIndex%NOTFOUND;
           IF ((idxRec.indid = 1) OR ((idxRec.indid > 1) AND (BitAnd(idxRec.status2, 512)=512)))
           THEN
             amIClustered := TRUE;
           ELSE
             amIClustered := FALSE;
           END IF;
           v_constName := idxRec.index_name;
           v_constCols := split_str2(idxRec.index_keys);

           IF BitAnd(idxRec.status, 2048) = 2048 -- Index on primary key
           THEN
              v_consType :='PK';
           ELSE
              v_consType := 'UNIQUE';
           END IF;
           --insert into constraints table
           INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, "LANGUAGE")
                VALUES(TRIM(v_constName), v_consType, objid, 'STSQL') RETURNING "ID" INTO vConsId; 
           IF (amIClustered = TRUE) --might want to use this to write out a comment
           THEN
                INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                    ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                    VALUES(svrid, vConsId, 'MD_CONSTRAINTS', 1, 'IS_CLUSTERED_INDEX', 'Y');
           END IF;
           if (amIClustered = TRUE)-- AND (v_consType = 'UNIQUE')) also want to mark primary keysto say --was clustered 
           THEN --mark table as IndexOrganisedTable
                select count(*) into prop_cnt from MD_ADDITIONAL_PROPERTIES
                where connection_id_fk = svrid and ref_id_fk =  objid 
                and prop_key = 'IS_INDEX_ORGANIZED_TABLE';
                IF (prop_cnt = 0) 
                THEN
                INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                    ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                    VALUES(svrid, objid , 'MD_TABLES', 1, 'IS_INDEX_ORGANIZED_TABLE', 'Y');
                END IF;
           END IF;
           --insert into constraints detail table
           nColPos := 1;
           LOOP
              BEGIN
                EXIT WHEN nColPos > v_constCols.count;
                nColId := GetColIdFromName(svrid, db_id, objid, TRIM(v_constCols(nColPos)));

                INSERT INTO MD_CONSTRAINT_DETAILS(constraint_id_fk, column_id_fk, detail_order) 
                     VALUES(vConsId, nColId, nColPos);
                nColPos := nColPos + 1;           
              EXCEPTION
                WHEN OTHERS THEN
                  errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                  LogInfo(NULL, sev_err, 'ProcessPkUkConstraints: Constraint detail capture issue: ['  || errMsg ||  ']  svrid:db_id:objid:vConsId:nColPos ' ||  svrid 
                                                                    || ':' || db_id || ':' || objid || ':' || vConsId || ':' || nColPos, NULL, NULL, nSvrId);
                  nColPos := nColPos + 1;                                                                                        
              END;
           END LOOP;  
         EXCEPTION
         WHEN OTHERS THEN
         errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
         LogInfo(NULL, sev_err, 'ProcessCheckConstraints: idxRec ['  || errMsg ||  '] idxRec.indid:idxRec.status:idxRec.status2:idxRec.index_keys:idxRec.index_name:vConsId' ||  idxRec.keycnt
                                                    || ':' || idxRec.indid
                                                    || ':' || idxRec.status
                                                    || ':' || idxRec.status2
                                                    || ':' || idxRec.index_keys
                                                    || ':' || idxRec.index_name
                                                    || ':' || vConsId, NULL, NULL, nSvrId);  
         END;   
      END LOOP;
      CLOSE curIndex;
    EXCEPTION 
          WHEN OTHERS THEN
            errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
            LogInfo(NULL, sev_err, 'ProcessPkUkConstraints: Master cursor open issue: ['  || errMsg ||  ']  svrid:db_id:objid: ' ||  svrid || ':' || db_id || ':' || objid, NULL, NULL, nSvrId);                    
   END ProcessPkUkConstraints;   

   FUNCTION GetGenIdForColumnId(svrid NUMBER, dbid NUMBER, tblid NUMBER, col_id NUMBER) RETURN NUMBER
   IS
      v_genColId NUMBER;
      errMsg VARCHAR2(4000);      
   BEGIN
      SELECT colid_gen INTO v_genColId FROM STAGE_SYB12_SYSCOLUMNS 
          WHERE svrid_fk = svrid 
             AND dbid_gen_fk = dbid
             AND id_gen_fk = tblid
             AND colid = col_id;

      RETURN v_genColId;
    EXCEPTION 
      WHEN OTHERS THEN
            errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
            LogInfo(NULL, sev_err, 'GetGenIdForColumnId: ['  || errMsg ||  ']  svrid:dbid:tblid:col_id ' ||  svrid || ':' || dbid 
                                                                                 || ':' || tblid || ':' || col_id, NULL, NULL, nSvrId);                    
   END GetGenIdForColumnId;

   -- fk -- true returns referencing keys
   -- fk -- false returns referenced keys
   FUNCTION GetKeysFromRecord(refRow STAGE_SYB12_SYSREFERENCES%ROWTYPE, fk BOOLEAN) RETURN key_array
   IS
      v_keys key_array;
      errMsg VARCHAR2(4000);      
   BEGIN
      v_keys := key_array();      
      IF fk = TRUE
      THEN
         IF refRow.fokey1 IS NOT NULL AND refRow.fokey1 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey1;
         END IF;

         IF refRow.fokey2 IS NOT NULL AND refRow.fokey2 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey2;
         END IF;

         IF refRow.fokey3 IS NOT NULL AND refRow.fokey3 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey3;
         END IF;

         IF refRow.fokey4 IS NOT NULL AND refRow.fokey4 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey4;
         END IF;

         IF refRow.fokey5 IS NOT NULL AND refRow.fokey5 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey5;
         END IF;

         IF refRow.fokey6 IS NOT NULL AND refRow.fokey6 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey6;
         END IF;

         IF refRow.fokey7 IS NOT NULL AND refRow.fokey7 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey7;
         END IF;

         IF refRow.fokey8 IS NOT NULL AND refRow.fokey8 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey8;
         END IF;

         IF refRow.fokey9 IS NOT NULL AND refRow.fokey9 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey9;
         END IF;

         IF refRow.fokey10 IS NOT NULL AND refRow.fokey10 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey10;
         END IF;

         IF refRow.fokey11 IS NOT NULL AND refRow.fokey11 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey11;
         END IF;

         IF refRow.fokey12 IS NOT NULL AND refRow.fokey12 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey12;
         END IF;

         IF refRow.fokey13 IS NOT NULL AND refRow.fokey13 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey13;
         END IF;

         IF refRow.fokey14 IS NOT NULL AND refRow.fokey14 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey14;
         END IF;

         IF refRow.fokey15 IS NOT NULL AND refRow.fokey15 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey15;
         END IF;

         IF refRow.fokey16 IS NOT NULL AND refRow.fokey16 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey16;
         END IF;

      ELSE
         IF refRow.refkey1 IS NOT NULL AND refRow.refkey1 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey1;
         END IF;

         IF refRow.refkey2 IS NOT NULL AND refRow.refkey2 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey2;
         END IF;

         IF refRow.refkey3 IS NOT NULL AND refRow.refkey3 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey3;
         END IF;

         IF refRow.refkey4 IS NOT NULL AND refRow.refkey4 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey4;
         END IF;

         IF refRow.refkey5 IS NOT NULL AND refRow.refkey5 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey5;
         END IF;

         IF refRow.refkey6 IS NOT NULL AND refRow.refkey6 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey6;
         END IF;

         IF refRow.refkey7 IS NOT NULL AND refRow.refkey7 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey7;
         END IF;

         IF refRow.fokey8 IS NOT NULL AND refRow.refkey8 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.foKey8;
         END IF;

         IF refRow.refkey9 IS NOT NULL AND refRow.refkey9 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey9;
         END IF;

         IF refRow.refkey10 IS NOT NULL AND refRow.refkey10 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey10;
         END IF;

         IF refRow.refkey11 IS NOT NULL AND refRow.refkey11 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey11;
         END IF;

         IF refRow.refkey12 IS NOT NULL AND refRow.refkey12 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey12;
         END IF;

         IF refRow.refkey13 IS NOT NULL AND refRow.refkey13 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey13;
         END IF;

         IF refRow.refkey14 IS NOT NULL AND refRow.refkey14 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey14;
         END IF;

         IF refRow.refkey15 IS NOT NULL AND refRow.refkey15 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey15;
         END IF;

         IF refRow.refkey16 IS NOT NULL AND refRow.refkey16 >0
         THEN
            v_keys.EXTEND;
            v_keys(v_keys.count) := refRow.refKey16;
         END IF;
      END IF;
      RETURN v_keys;
    EXCEPTION 
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        IF fk = TRUE
        THEN
            LogInfo(NULL, sev_err, 'GetKeysFromRecord: ['  || errMsg ||  ']  refRow:fk ' ||  refRow.foKey1 || ':' || refRow.foKey2 ||
                                                                                  ':' || refRow.foKey3 || ':' || refRow.foKey4
                                                                                 || ':' || refRow.foKey5 || ':' || refRow.foKey6
                                                                                 || ':' || refRow.foKey7 || ':' || refRow.foKey8
                                                                                 || ':' || refRow.foKey9 || ':' || refRow.foKey10
                                                                                 || ':' || refRow.foKey11 || ':' || refRow.foKey12
                                                                                 || ':' || refRow.foKey13 || ':' || refRow.foKey14
                                                                                 || ':' || refRow.foKey15 || ':' || refRow.foKey16
                                                                                 || ':' || 'TRUE', NULL, NULL, nSvrId);  
        ELSE
            LogInfo(NULL, sev_err, 'GetKeysFromRecord: ['  || errMsg ||  ']  refRow:fk ' ||  refRow.refKey1 || ':' || refRow.refKey2 ||
                                                                                  ':' || refRow.refKey3 || ':' || refRow.refKey4
                                                                                 || ':' || refRow.refKey5 || ':' || refRow.refKey6
                                                                                 || ':' || refRow.refKey7 || ':' || refRow.refKey8
                                                                                 || ':' || refRow.refKey9 || ':' || refRow.refKey10
                                                                                 || ':' || refRow.refKey11 || ':' || refRow.refKey12
                                                                                 || ':' || refRow.refKey13 || ':' || refRow.refKey14
                                                                                 || ':' || refRow.refKey15 || ':' || refRow.refKey16
                                                                                 || ':' || 'FALSE', NULL, NULL, nSvrId);            
        END IF;
   END;

   PROCEDURE ProcessFkConstraints(svrid NUMBER, dbid NUMBER, objid NUMBER)
   IS
       CURSOR curReferences(svrid NUMBER, dbid NUMBER, objid NUMBER) IS SELECT * 
                                   FROM stage_syb12_sysreferences 
                                      WHERE svrid_fk = svrid
                                         AND dbid_gen_fk = dbid
                                         AND table_id_gen_fk = objid;

       v_refRow STAGE_SYB12_SYSREFERENCES%ROWTYPE;
       v_constName VARCHAR2(300):=null;
       v_colOrder NUMBER;
       nConsId NUMBER;
       v_keys key_array;
       nColId NUMBER;
       errMsg VARCHAR2(4000);       
   BEGIN
      OPEN curReferences(svrid, dbid, objid);

      LOOP
        BEGIN
         FETCH curReferences INTO v_refRow;
         EXIT WHEN curReferences%NOTFOUND;

         BEGIN
            SELECT "NAME" INTO v_constName 
                    FROM stage_syb12_sysobjects 
                      WHERE objid_gen = v_refRow.constraint_gen_fk;
         EXCEPTION WHEN OTHERS THEN
            errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
            LogInfo(NULL, sev_err, 'ProcessFkConstraints: Unable to get constraint name ['  || errMsg ||  ']  svrid:dbid:objid:v_refRow.constraint_gen_fk ' ||  svrid || ':' || dbid 
                                                                                 || ':' || objid || ':' || v_refRow.constraint_gen_fk, NULL, NULL, nSvrId);             
           v_constName := 'UNKNOWN'	;
         END;      
          -- TODO: Cross database references for tableid and reftableid needs to be handled
          -- should we add this information into MD_ADDITIONAL properties?

         INSERT INTO MD_CONSTRAINTS("NAME", constraint_type, table_id_fk, reftable_id_fk,
                                   "LANGUAGE")                         
                  VALUES (v_constName, 'FOREIGN KEY', v_refRow.table_id_gen_fk, 
                               v_refRow.ref_table_id_gen_fk, 'STSQL')
                     RETURNING "ID" INTO nConsId;

        v_keys := GetKeysFromRecord(v_refRow, TRUE);
        v_colOrder :=1;

               LOOP
                 BEGIN
                   EXIT WHEN v_colOrder > v_keys.count;
                   -- insert the referencing constraint detail here ...
                   --nColId := v_keys(v_colOrder);

                   SELECT colid_gen INTO nColId FROM stage_syb12_syscolumns 
                                    WHERE svrid_fk = svrid
                                       AND dbid_gen_fk = dbid
                                       AND id_gen_fk = v_refRow.table_id_gen_fk
                                       AND colid = v_keys(v_colOrder);

                   INSERT INTO MD_CONSTRAINT_DETAILS(constraint_id_fk, column_id_fk, detail_order) 
                      VALUES ( nConsId, nColId, v_colOrder);
                   v_colOrder := v_colOrder + 1;
                 EXCEPTION
                   WHEN OTHERS THEN
                     errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                     LogInfo(NULL, sev_err, 'ProcessFkConstraints: Unable process referencing constraint details ['  
                                                || errMsg ||  ']  svrid:dbid:objid:v_refRow.table_id_gen_fk:v_colOrder:v_keys(v_colOrder): ' 
                                                ||  svrid || ':' || dbid 
                                                || ':' || objid || ':' || v_refRow.table_id_gen_fk
                                                || ':' || v_colOrder || ':' || v_keys(v_colOrder), NULL, NULL, nSvrId); 
                    v_colOrder := v_colOrder + 1;                       
                 END;
              END LOOP; -- end of fk keys loop

              v_keys := GetKeysFromRecord(v_refRow, FALSE);
              v_colOrder :=1;
              LOOP
                EXIT WHEN v_colOrder > v_keys.count;
                --insert the referenced constraint detail here ...
                --nColId := v_keys(v_colOrder);
                BEGIN
                    SELECT colid_gen INTO nColId FROM stage_syb12_syscolumns 
                                        WHERE svrid_fk = svrid
                                           AND dbid_gen_fk = dbid
                                           AND id_gen_fk = v_refRow.ref_table_id_gen_fk
                                           AND colid = v_keys(v_colOrder);          

                    INSERT INTO MD_CONSTRAINT_DETAILS(ref_flag, constraint_id_fk, column_id_fk, detail_order) 
                          VALUES ('Y',  nConsId, nColId, v_colOrder);      
                    v_colOrder := v_colOrder + 1;
                EXCEPTION WHEN OTHERS THEN
                  errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                  LogInfo(NULL, sev_err, 'ProcessFkConstraints: Unable process referenced constraint details ['  
                                                || errMsg ||  ']  svrid:dbid:objid:v_refRow.ref_table_id_gen_fk:v_colOrder:v_keys(v_colOrder): ' 
                                                ||  svrid || ':' || dbid 
                                                || ':' || objid || ':' || v_refRow.ref_table_id_gen_fk
                                                || ':' || v_colOrder || ':' || v_keys(v_colOrder), NULL, NULL, nSvrId);  
                   v_colOrder := v_colOrder + 1;                      
                END;            
              END LOOP; -- end of ref keys loop 
        EXCEPTION 
           WHEN OTHERS THEN
                  errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                  LogInfo(NULL, sev_err, 'ProcessFkConstraints: sysreferences loop issue ['  
                                                || errMsg ||  ']  svrid:dbid:objid:v_refRow.table_id_gen_fk:v_refRow.ref_table_id_gen_fk: ' 
                                                ||  svrid || ':' || dbid 
                                                || ':' || objid
                                                || ':' || v_refRow.table_id_gen_fk
                                                || ':' || v_refRow.ref_table_id_gen_fk, NULL, NULL, nSvrId);                                   
        END;
      END LOOP; -- end of sysreferences loop
      CLOSE curReferences;
    EXCEPTION 
      WHEN OTHERS THEN
            errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
            LogInfo(NULL, sev_err, 'ProcessFkConstraints: ['  || errMsg ||  ']  svrid:dbid:objid ' ||  svrid || ':' || dbid 
                                                                                 || ':' || objid, NULL, NULL, nSvrId);    
   END ProcessFkConstraints;

   PROCEDURE CaptureConstraints
   IS
      CURSOR curObjs IS SELECT A.* FROM stage_syb12_sysobjects A, stage_syb12_sysusers B  
                 WHERE A.db_type = 'U ' 
                 AND A.db_uid = B.db_uid 
                 AND A.svrid_fk = B.svrid_fk 
                 AND A.dbid_gen_fk = B.dbid_gen_fk 
                 AND B.suid>0;   
      v_tblcolcnt NUMBER :=0; 
      v_no_const_cols NUMBER :=0;
      v_clust  NUMBER :=0; -- flag for clustered index
      v_nonclust NUMBER :=0; -- flag for non clustered index
      v_constrid NUMBER :=0; -- flag for table check constraint
      v_keycnt NUMBER :=0;  -- more than one check constraint
      v_pmytabid NUMBER :=0; -- flag for fk constraint
      v_reftabid NUMBER :=0; -- flag for ref table constraint      
      errMsg VARCHAR2(4000);      
   BEGIN
       FOR r_c1 IN curObjs
       LOOP

          v_clust := BitAnd(r_c1.sysstat, 16);
          v_nonclust := BitAnd(r_c1.sysstat, 32);
          v_constrid := r_c1.ckfirst;  -- table check constraint
          v_keycnt := BitAnd(r_c1.sysstat2, 4);
          v_pmytabid := BitAnd(r_c1.sysstat2, 2);
          v_reftabid := BitAnd(r_c1.sysstat2, 1);

          IF v_constrid != 0
          THEN
             NULL;
             --Process check constraint here
             ProcessCheckConstraints(r_c1.svrid_fk, r_c1.dbid_gen_fk, r_c1.objid_gen);
          END IF;

          IF v_clust > 0 OR v_nonclust > 0
          THEN
             -- Process Unique and Primary constraints
             ProcessPkUkConstraints(r_c1.svrid_fk, r_c1.dbid_gen_fk, r_c1.objid_gen);
          END IF;

          IF v_pmytabid > 0 OR v_reftabid > 0
          THEN
             -- Process FK constraints
             ProcessFkConstraints(r_c1.svrid_fk, r_c1.dbid_gen_fk, r_c1.objid_gen);
             NULL;
          END IF;
       END LOOP;
    EXCEPTION 
      WHEN OTHERS THEN
        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
        LogInfo(NULL, sev_err, 'CaptureConstraints Failed [' || errMsg ||  '] ', NULL, NULL, nSvrId);                        
   END;
   /*
     CURSOR curConstr IS SELECT svrid_fk, dbid_gen_fk, table_id_gen_fk,
                           constraint_name,db_definition FROM stage_syb12_sysconstraints;
     vDbDef VARCHAR2(4000);     
   BEGIN
      FOR r_c1 IN curConstr 
      LOOP
         vDbDef := r_c1.db_definition;
         IF INSTR(vDbDef, ' CHECK ') != 0 THEN  -- Insert a row into MD_Constraints
            ProcessCheckConstraint(r_c1.svrid_fk, r_c1.dbid_gen_fk, 
                   r_c1.table_id_gen_fk, r_c1.constraint_name, r_c1.db_definition);
         ELSIF INSTR(vDbDef, 'PRIMARY KEY ') != 0 THEN
            ProcessPkConstraint(r_c1.svrid_fk, r_c1.dbid_gen_fk, 
                   r_c1.table_id_gen_fk, r_c1.constraint_name, r_c1.db_definition);
         ELSIF INSTR(vDbDef, 'UNIQUE ') != 0 THEN
            ProcessUkConstraint(r_c1.svrid_fk, r_c1.dbid_gen_fk, 
                   r_c1.table_id_gen_fk, r_c1.constraint_name, r_c1.db_definition);
         ELSIF INSTR(vDbDef, ' FOREIGN KEY ') !=0 THEN
            ProcessFkConstraint(r_c1.svrid_fk, r_c1.dbid_gen_fk, 
                   r_c1.table_id_gen_fk, r_c1.constraint_name, r_c1.db_definition);
         END IF;
      END LOOP;
   END CaptureConstraints;
   */
   PROCEDURE CaptureIndexes
   IS 
     vIdxName VARCHAR2(255);
     vIdxKeys VARCHAR2(4000);
     vIdxDesc VARCHAR2(4000);
     vIdxType VARCHAR2(100);
     curIdxCols ref_cur_type;
     nIdxColId INTEGER;
     vIdxCol VARCHAR2(300);
     vc_Unique CONSTANT VARCHAR2(100) := 'unique';
     vc_IndexUnique CONSTANT VARCHAR2(100) := 'UNIQUE';
     vc_IndexNonUnique CONSTANT VARCHAR2(100) := 'NON_UNIQUE';

     inString  INTEGER;
     nDetailOrder NUMBER :=1;
     vlcColName VARCHAR2(300);
     bDescIdx BOOLEAN;
     nIdxDetailId NUMBER;
     nsuid NUMBER;
     idxKeyCols split_varray_type; 
     len pls_integer;
     CURSOR curIndexes IS SELECT A.svrid_fk, A.dbid_gen_fk, A.indid_gen, A.id_gen_fk,
                                    A.index_name, A."INDEX_DESC", A.index_keys, A.indid, A.status2,  B.sysstat 
                                    FROM stage_syb12_sysindexes A, stage_syb12_sysobjects B, stage_syb12_sysusers C  
                              WHERE A.dbid_gen_fk = B.dbid_gen_fk
                                  AND A.svrid_fk = B.svrid_fk
                                --  AND A.suid_gen_fk = B.suid_gen_fk
                                  AND A.id_gen_fk = B.OBJID_GEN
                                  AND A.svrid_fk = nSvrId
                                  AND C.db_uid = B.db_uid 
                                  AND C.svrid_fk = B.svrid_fk 
                                  AND C.dbid_gen_fk = B.dbid_gen_fk 
                                  AND C.suid>0                                       
                                  AND A.KEYCNT >0;--Have to filter this as we capture constraint info into stage_syb12_sysindexes as well

      errMsg VARCHAR2(4000); 
      v_clust NUMBER := 0;
      amIClustered BOOLEAN := TRUE;
      prop_cnt   pls_integer;

   BEGIN
     --SetStatus('Capturing Indexes');
     FOR r_c1 IN curIndexes 
     LOOP
        BEGIN
        v_clust := BitAnd(r_c1.sysstat, 16);
        vIdxName := r_c1.index_name;
        vIdxKeys := TRIM(r_c1.index_keys);
        vIdxDesc := r_c1."INDEX_DESC";
        --nsuid := r_c1.suid_gen_fk;

        inString := InStr(vIdxDesc, vc_Unique);

        IF inString = 0 THEN -- Unique Index
           vIdxType := vc_IndexNonUnique;
        ELSE  -- Non-unique Index
           vIdxType := vc_IndexUnique;
        END IF;        

        --For each of the column shread the detail into the MD_INDEX_DETAILS and MD_ADDITIONAL_PROPERTIES
        --OPEN curIdxCols FOR 'SELECT * FROM table(split_str(:1))' USING vIdxKeys;
        --FETCH curIdxCols INTO vIdxCol;
        IF vIdxKeys IS NOT NULL THEN
             nDetailOrder :=1; -- set it each time before you commence the loop.
            idxKeyCols := split_str2(vIdxKeys);
            len := idxKeyCols.count;

            -- insert index core attributes in md_indexes
            INSERT INTO MD_INDEXES("ID", index_type, table_id_fk, index_name) 
                 VALUES(r_c1.indid_gen, vIdxType, r_c1.id_gen_fk, vIdxName);
             IF ((r_c1.indid = 1) OR ((r_c1.indid > 1) AND (BitAnd(r_c1.status2, 512)=512)))
            THEN
              amIClustered := TRUE;
              INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                  ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                  VALUES(r_c1.svrid_fk,r_c1.indid_gen , 'MD_INDEXES', 1, 'IS_CLUSTERED_INDEX', 'Y');
            ELSE 
              amIClustered := FALSE;
            END IF;
            if (amIClustered = TRUE) -- AND (vIdxType = vc_IndexUnique)) want to mark all indexes cluster to say 'was clustered' 
            THEN --mark table as IndexOrganisedTable
              select count(*) into prop_cnt from MD_ADDITIONAL_PROPERTIES
              where connection_id_fk = r_c1.svrid_fk and ref_id_fk =  r_c1.id_gen_fk 
              and prop_key = 'IS_INDEX_ORGANIZED_TABLE';
              IF (prop_cnt = 0) 
              THEN
                INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                  ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                  VALUES(r_c1.svrid_fk, r_c1.id_gen_fk , 'MD_TABLES', 1, 'IS_INDEX_ORGANIZED_TABLE', 'Y');
              END IF;
            END IF;

            LOOP
               BEGIN
                 EXIT WHEN nDetailOrder > len;
                 vIdxCol := idxKeyCols(nDetailOrder);

                 --EXIT WHEN curIdxCols%NOTFOUND;
                 vlcColName := LOWER(TRIM(vIdxCol));
                 vIdxCol := TRIM(vIdxCol);
                 IF EndsWithStr(vlcColName, ' desc') != 0 THEN
                    vIdxCol := SUBSTR(vlcColName, 1, INSTR(vlcColName, ' desc'));  -- not sure if lower casing will affect the ensuing query
                    bDescIdx := TRUE;
                 ELSE
                    bDescIdx := FALSE;
                 END IF;

                 nIdxColId := GetColIdFromName(r_c1.svrid_fk, r_c1.dbid_gen_fk, r_c1.id_gen_fk, TRIM(vIdxCol));           

                 INSERT INTO MD_INDEX_DETAILS(index_id_fk, column_id_fk, detail_order) 
                        VALUES(r_c1.indid_gen, nIdxColId, nDetailOrder) RETURNING "ID" INTO nIdxDetailId;

                 IF bDescIdx THEN
                      INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                         ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                         VALUES(r_c1.svrid_fk, nIdxDetailId, 'MD_INDEX_DETAIL', nDetailOrder, 'IS_INDEXDETAIL_DESCENDING', 'Y');
                 END IF;

                 --FETCH curIdxCols INTO vIdxCol;
                 nDetailOrder := nDetailOrder + 1;
               EXCEPTION
                  WHEN OTHERS THEN
                  errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                  LogInfo(NULL, sev_err, 'CaptureIndexes: Index detail capture loop issue [' || errMsg ||  '] v_clust:vIdxName:vIdxKeys:vIdxDesc:r_c1.indid_gen:nIdxColId:nDetailOrder: '
                                                               || v_clust || ':'
                                                               || vIdxKeys || ':'
                                                               || vIdxDesc || ':'
                                                               || r_c1.indid_gen || ':'
                                                               || nIdxColId || ':'
                                                               || nDetailOrder, NULL, NULL, nSvrId);
                  IF bDescIdx THEN
                    LogInfo(NULL, sev_err, 'CaptureIndexes: Index detail capture loop issue(DESC) [' || errMsg ||  '] v_clust:vIdxName:vIdxKeys:vIdxDesc:r_c1.svrid_fk:nIdxDetailId:nDetailOrder: '
                                                                 || v_clust || ':'
                                                                 || vIdxKeys || ':'
                                                                 || vIdxDesc || ':'
                                                                 || r_c1.svrid_fk || ':'
                                                                 || nIdxDetailId || ':'
                                                                 || nDetailOrder, NULL, NULL, nSvrId);                                      
                  END IF;
                  nDetailOrder := nDetailOrder + 1;
               END;
            END LOOP;
          END IF; -- vIdxKeys IS NOT NULL
--        CLOSE curIdxCols;
        EXCEPTION 
           WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureIndexes: Master cursor loop issue [' || errMsg ||  '] v_clust:vIdxName:vIdxKeys:vIdxDesc: '
                                                           || v_clust || ':'
                                                           || vIdxKeys || ':'
                                                           || vIdxDesc, NULL, NULL, nSvrId);                
        END;    
     END LOOP;
    EXCEPTION 
      WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureIndexes Failed [' || errMsg ||  '] ', NULL, NULL, nSvrId);                        
   END CaptureIndexes;

   PROCEDURE CaptureViews
   IS
      CURSOR curViews IS SELECT DISTINCT A.objid_gen, A."NAME", a.suid_gen_fk, a.dbid_gen_fk 
                            FROM stage_syb12_sysobjects A, stage_syb12_sysusers B 
                            WHERE A.db_type='V '
                                  AND A.db_uid = B.db_uid 
                                  AND A.svrid_fk = B.svrid_fk 
                                  AND A.dbid_gen_fk = B.dbid_gen_fk 
                                  AND B.suid>0                                                                  
                                 AND A.svrid_fk = nSvrId AND A.name <> 'sysquerymetrics';  -- process every view object pulled from this server

      curViewSql ref_cur_type;
      clbNativeSql CLOB := TO_CLOB(' ');
      vNativeSqlPiece VARCHAR2(4000);
      errMsg VARCHAR2(4000);      
   BEGIN
            --SetStatus('Capturing Views');
      FOR r_c1 IN curViews
      LOOP
          BEGIN
             OPEN curViewSql FOR 'SELECT B."TEXT" FROM stage_syb12_sysobjects A, stage_syb12_syscomments B         
                     WHERE A."OBJID_GEN" = B."ID_GEN_FK" 
                       AND A."OBJID_GEN"=:1 
                       AND A.dbid_gen_fk = B.dbid_gen_fk
                       AND B.dbid_gen_fk = :2
                       AND A.svrid_fk = B.svrid_fk
                       AND A.svrid_fk = :3
                       ORDER BY colid' USING r_c1."OBJID_GEN", r_c1.dbid_gen_fk, nSvrId;
             FETCH curViewSql INTO vNativeSqlPiece;
             LOOP
                EXIT WHEN curViewSql%NOTFOUND;
                IF vNativeSqlPiece IS NULL
                THEN
                   vNativeSqlPiece := ' ';
                END IF;
                DBMS_LOB.writeappend(clbNativeSql, LENGTH(vNativeSqlPiece), vNativeSqlPiece);            
                FETCH curViewSql INTO vNativeSqlPiece;
             END LOOP; -- inner ref cursor loop
             CLOSE curViewSql;
             INSERT INTO MD_VIEWS("ID", schema_id_fk, view_name, native_sql, "LANGUAGE") 
                      VALUES(r_c1.objid_gen, r_c1.suid_gen_fk, r_c1."NAME", clbNativeSql, 'STSQL');
             clbNativeSql  := TO_CLOB(' ');    -- reset clob              
          EXCEPTION
             WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureViews: Issue opening sql text cursor [' || errMsg ||  '] r_c1."OBJID_GEN":r_c1.dbid_gen_fk:nSvrId: ' ||
                                                                               r_c1."OBJID_GEN" || ':' 
                                                                            || r_c1.dbid_gen_fk || ':'
                                                                            || nSvrId, NULL, NULL, nSvrId);  
              clbNativeSql := TO_CLOB(' '); --reset clob                      
          END;
      END LOOP;
    EXCEPTION 
      WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureViews Failed [' || errMsg ||  '] ', NULL, NULL, nSvrId);                        
   END CaptureViews;

   PROCEDURE CaptureStoredPrograms
   IS
      -- In Sybase Grouped Procedures C.db_number can have values >= 1.
      CURSOR curSP IS SELECT DISTINCT A.svrid_fk, A.dbid_gen_fk, A.objid_gen, A.db_type, A."NAME", a.suid_gen_fk, C.db_number
                            FROM stage_syb12_sysobjects A, stage_syb12_sysusers B, stage_syb12_syscomments C
                            WHERE ( A.db_type='P ' 
                                 OR A.db_type = 'SF' 
                                 OR A.db_type = 'FN' 
                                 OR A.db_type = 'TF' 
                                 OR A.db_type = 'IF' )
                                  AND A.db_uid = B.db_uid 
                                  AND A.svrid_fk = B.svrid_fk 
                                  AND C.svrid_fk = A.svrid_fk
                                  AND A.dbid_gen_fk = B.dbid_gen_fk 
                                  AND C.dbid_gen_fk = A.dbid_gen_fk
                                  AND C.id = A.id 
                                  AND B.suid>0                                                                       
                                  AND A.svrid_fk = nSvrId;  -- process every SP object pulled from this server

      curSPSql ref_cur_type;
      vType VARCHAR2(100);
      vSPType VARCHAR2(100);
      vAdditionalProp VARCHAR2 (200) :=NULL;
      clbNativeSql CLOB := TO_CLOB(' ');
      vNativeSqlPiece VARCHAR2(4000);
      errMsg VARCHAR2(4000);      
   BEGIN
            --SetStatus('Capturing Stored Programs');
      FOR r_c1 IN curSP
      LOOP
      BEGIN
         --TODO: Handle Encryped SQL case where we may get an exception.
         OPEN curSPSql FOR 'SELECT B."TEXT" FROM stage_syb12_sysobjects A, stage_syb12_syscomments B        
 		             WHERE A."OBJID_GEN" = B."ID_GEN_FK" 
                 AND B."ID_GEN_FK"=:1 
                 AND A.dbid_gen_fk = B.dbid_gen_fk
                 AND A.dbid_gen_fk = :2
                 AND A.svrid_fk = B.svrid_fk
                 AND A.svrid_fk = :3
                 AND B.db_number = :4
                 ORDER BY colid' USING r_c1."OBJID_GEN", r_c1.dbid_gen_fk, nSvrId, r_c1.db_number;

         FETCH curSPSql INTO vNativeSqlPiece;
         LOOP
         BEGIN
            EXIT WHEN curSPSql%NOTFOUND;
            IF vNativeSqlPiece IS NULL
            THEN
               vNativeSqlPiece := ' ';
            END IF;
            DBMS_LOB.writeappend(clbNativeSql, LENGTH(vNativeSqlPiece), vNativeSqlPiece);            
            FETCH curSPSql INTO vNativeSqlPiece;
         EXCEPTION 
            WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureStoredPrograms : Issue building the sp text lob [' || errMsg ||  '] r_c1."OBJID_GEN":r_c1.dbid_gen_fk:nSvrId: '
                                                                || r_c1."OBJID_GEN" || ':'
                                                                || r_c1.dbid_gen_fk || ':'
                                                                || nSvrId, NULL, NULL, nSvrId);                        
         END;         
         END LOOP; -- inner ref cursor loop
         CLOSE curSPSql;

         vType := TRIM(r_c1.db_type);

         IF vType = 'FN'  THEN
           vSPType := 'FUNCTION';
           vAdditionalProp := 'SCALAR FUNCTION';
         ELSIF vType = 'SF'  THEN
           vSPType := 'FUNCTION';
           vAdditionalProp := 'FUNCTION';  
         ELSIF  vType = 'IF' THEN
           vSPType := 'FUNCTION'; 
           vAdditionalProp := 'INLINED T. FUNCTION';
         ELSIF vType = 'TF' THEN
           vSPType := 'FUNCTION';
           vAdditionalProp := 'TABLE FUNCTION';
         ELSE
           vSPType := 'PROCEDURE';
         END IF;

         IF r_c1.db_number > 1 THEN -- for grouped procedures db_number will be > 1.
           INSERT INTO md_stored_programs(schema_id_fk, programtype, 
                                         "NAME", native_sql, "LANGUAGE") 
                VALUES(r_c1.suid_gen_fk, vSPType, r_c1."NAME", clbNativeSql, 'STSQL');
         ELSE       
           INSERT INTO md_stored_programs("ID", 
                                         schema_id_fk, programtype, 
                                         "NAME", native_sql, "LANGUAGE") 
                VALUES(r_c1.objid_gen, r_c1.suid_gen_fk, vSPType, r_c1."NAME", clbNativeSql, 'STSQL');
         END IF;

         IF vAdditionalProp IS NOT NULL THEN
            INSERT INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, 
                                                 ref_id_fk, 
                                                 ref_type,
                                                 property_order,
                                                 prop_key,
                                                 "VALUE")
                   VALUES(r_c1.svrid_fk, r_c1.objid_gen, 'MD_STORED_PROGRAMS', 1,'TYPE', vAdditionalProp);
         END IF;
         clbNativeSql := TO_CLOB(' ');        -- reset clob
         EXCEPTION
            WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureStoredPrograms : Issue opening master cursor or capturing sp list [' || errMsg ||  '] r_c1."OBJID_GEN":r_c1.dbid_gen_fk:nSvrId: '
                                                                || r_c1."OBJID_GEN" || ':'
                                                                || r_c1.dbid_gen_fk || ':'
                                                                || nSvrId, NULL, NULL, nSvrId);                        
         END;
      END LOOP;
    EXCEPTION 
      WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureStoredPrograms Failed [' || errMsg ||  '] ', NULL, NULL, nSvrId);                        
   END CaptureStoredPrograms;      

   PROCEDURE CaptureTriggers
   IS
      CURSOR curObjTrig IS SELECT A.svrid_fk, A.dbid_gen_fk, A.objid_gen, A.deltrig triggerID, A.db_type 
                               FROM stage_syb12_sysobjects A, stage_syb12_sysusers B 
                               WHERE (A.db_type = 'U ' OR A.db_type = 'V ') 
                                  AND   (A.DELTRIG IS NOT NULL AND A.DELTRIG>0) --DELETE triggers
                                  AND A.db_uid = B.db_uid 
                                  AND A.svrid_fk = B.svrid_fk 
                                  AND A.dbid_gen_fk = B.dbid_gen_fk 
                                  AND B.suid>0
                                  AND A.svrid_fk = nSvrId 
UNION
SELECT A.svrid_fk, A.dbid_gen_fk, A.objid_gen,A.updtrig triggerID, A.db_type 
                               FROM stage_syb12_sysobjects A, stage_syb12_sysusers B 
                               WHERE (A.db_type = 'U ' OR A.db_type = 'V ') 
                                AND   (A.UPDTRIG IS NOT NULL AND A.UPDTRIG >0) --UPDATE TRIGGERS    
                                  AND A.db_uid = B.db_uid 
                                  AND A.svrid_fk = B.svrid_fk 
                                  AND A.dbid_gen_fk = B.dbid_gen_fk 
                                  AND B.suid>0
     							  AND A.svrid_fk = nSvrId	 	                              
UNION
SELECT A.svrid_fk, A.dbid_gen_fk, A.objid_gen, A.instrig triggerID, A.db_type 
                               FROM stage_syb12_sysobjects A, stage_syb12_sysusers B 
                               WHERE (A.db_type = 'U ' OR A.db_type = 'V ') 
                                AND   (A.INSTRIG IS NOT NULL AND A.INSTRIG>0) --INSERT TRIGGERS
                                  AND A.db_uid = B.db_uid 
                                  AND A.svrid_fk = B.svrid_fk 
                                  AND A.dbid_gen_fk = B.dbid_gen_fk 
                                  AND B.suid>0                                                                   
                                  AND A.svrid_fk = nSvrId;


      curTrigSql ref_cur_type;
      curTrigText ref_cur_type;
      clbNativeSql CLOB := TO_CLOB(' ');
      vNativeSqlPiece VARCHAR2(4000);   
      nTrigSvrId NUMBER;
      nTrigDbId NUMBER;
      nTrigId NUMBER;
      vTrigName VARCHAR2(300);
      vTriggerOn VARCHAR2(300);
      nTableOrViewId NUMBER;
      errMsg VARCHAR2(4000);
   BEGIN
            --SetStatus('Capturing Triggers');
      FOR r_c1 IN curObjTrig
      LOOP
        BEGIN
           OPEN curTrigSql FOR 'SELECT A.svrid_fk, A.dbid_gen_fk, A.objid_gen, A."NAME"
                                         FROM stage_syb12_sysobjects A, stage_syb12_sysusers B 
                                         WHERE A."ID" = :1
                                           AND A.dbid_gen_fk = :2
                                           AND A.svrid_fk = :3
                                           AND A.db_uid = B.db_uid 
                                           AND A.svrid_fk = B.svrid_fk 
                                           AND A.dbid_gen_fk = B.dbid_gen_fk 
                                           AND B.suid>0'                                                                                                                 
                                           USING r_c1.triggerID, 
                                                 r_c1.dbid_gen_fk,
                                                 r_c1.svrid_fk;
           FETCH curTrigSql INTO nTrigSvrId, nTrigDbId, nTrigId, vTrigName;

           LOOP
             BEGIN
                EXIT WHEN curTrigSql%NOTFOUND;            
                OPEN curTrigText FOR 'SELECT B."TEXT" FROM stage_syb12_sysobjects A, stage_syb12_syscomments B        
                     WHERE A.svrid_fk = B.svrid_fk
                          AND A.svrid_fk = :1
                          AND A.dbid_gen_fk = B.dbid_gen_fk
                          AND A.dbid_gen_fk = :2
                          AND A."OBJID_GEN" = B."ID_GEN_FK"
                          AND B."ID_GEN_FK" = :3
                     ORDER BY colid'  USING nTrigSvrId, nTrigDbId, nTrigId;
                FETCH curTrigText INTO vNativeSqlPiece;
                --TODO: Handle Encryped trigger text case where we may get an exception.
                LOOP
                  BEGIN
                     EXIT WHEN curTrigText%NOTFOUND;
                     IF vNativeSqlPiece IS NULL
                     THEN
                        vNativeSqlPiece := ' ';
                     END IF;
                     DBMS_LOB.writeappend(clbNativeSql, LENGTH(vNativeSqlPiece), vNativeSqlPiece);               
                     FETCH curTrigText INTO vNativeSqlPiece; 
                  EXCEPTION
                     WHEN OTHERS THEN
                        errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                        LogInfo(NULL, sev_err, 'CaptureTriggers : Issue building trigger text blob [' || errMsg ||  '] nTrigSvrId:nTrigDbId:nTrigId: '
                                                                          || nTrigSvrId || ':'
                                                                          || nTrigDbId || ':'
                                                                          || nTrigId, NULL, NULL, nSvrId); 
                       FETCH curTrigText INTO vNativeSqlPiece; 
                  END;
                END LOOP; -- end of trig text loop

                IF r_c1.db_type = 'U ' THEN
                   vTriggerOn :='T';
                ELSIF r_c1.db_type = 'V ' THEN
                   vTriggerOn :='V';
                END IF;

                nTableOrViewId := r_c1.objid_gen; --id of view or table object

                INSERT INTO MD_TRIGGERS("ID", 
                                        table_or_view_id_fk, 
                                        trigger_on_flag,
                                        trigger_name,
                                        native_sql,
                                        "LANGUAGE")
                                 VALUES(nTrigId, 
                                        nTableOrViewId,
                                        vTriggerOn,
                                        vTrigName,
                                        clbNativeSql,
                                        'STSQL');

                FETCH curTrigSql INTO nTrigSvrId, nTrigDbId, nTrigId, vTrigName;
                clbNativeSql := TO_CLOB(' ');
             EXCEPTION
                WHEN OTHERS THEN
                  errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                  LogInfo(NULL, sev_err, 'CaptureTriggers : Issue capturing trigger detail [' || errMsg ||  '] nTrigSvrId:nTrigDbId:nTrigId: '
                                                                    || nTrigSvrId || ':'
                                                                    || nTrigDbId || ':'
                                                                    || nTrigId, NULL, NULL, nSvrId); 
                  clbNativeSql := TO_CLOB(' '); 
             END;
           END LOOP; -- end of trigger selection loop
           CLOSE curTrigSql;
        EXCEPTION
           WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureTriggers : Issue opening master cursor or capturing trigger list [' || errMsg ||  '] r_c1.triggerID:r_c1.dbid_gen_fk:r_c1.svrid_fk: '
                                                                || r_c1.triggerID || ':'
                                                                || r_c1.dbid_gen_fk || ':'
                                                                || r_c1.svrid_fk, NULL, NULL, nSvrId);  
        END;
      END LOOP; -- end of trigger base object selection loop
    EXCEPTION 
      WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureTriggers Failed [' || errMsg ||  '] ', NULL, NULL, nSvrId);                        
   END;

   PROCEDURE CaptureUDT
   IS
         errMsg VARCHAR2(4000);   
   BEGIN
           -- SetStatus('Capturing UDT');
	   INSERT INTO MD_USER_DEFINED_DATA_TYPES (
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
		LAST_UPDATED_BY)
		WITH lowestType AS ( SELECT DISTINCT db_type ,MIN(usertype) usertypex FROM stage_syb12_systypes x GROUP BY db_type ),
		     lowestSchema AS ( SELECT min(A.suid_gen) MIN_SUID_GEN FROM stage_syb12_sysusers A WHERE A.svrid_fk = nSvrId AND A.suid>0 AND A.db_uid IN (SELECT DISTINCT db_uid FROM stage_syb12_sysobjects)    )
		SELECT DISTINCT
		(SELECT MIN_SUID_GEN FROM lowestSchema), 
		y.NAME UDTNAME,
                SYB12ALLPLATFORM.GetDescription(x.NAME, y.prec, y.scale, y.length) definition,
	        SYB12ALLPLATFORM.GetDescription(x.NAME, y.prec, y.scale, y.length),
		'0',
		NULL,
		0,
		SYSDATE,
		NULL,
		NULL,
		NULL
		FROM stage_syb12_systypes y, stage_syb12_systypes x, lowestType l
		WHERE y.db_type = l.db_type
		AND x.usertype = l.usertypex
		AND y.usertype > 100;
    EXCEPTION 
      WHEN OTHERS THEN
              errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
              LogInfo(NULL, sev_err, 'CaptureUDT Failed [' || errMsg ||  '] ', NULL, NULL, nSvrId);  
    END CaptureUDT;

   PROCEDURE CaptureEntireStage
   IS
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
   END CaptureEntireStage;

   PROCEDURE FixSysDatabases  -- nothing to do for databases
   IS
   BEGIN
      NULL;
   END FixSysDatabases;

   PROCEDURE FixSysUsers  -- nothing to do for schemas
   IS
   BEGIN
      NULL;
   END FixSysUsers;

   PROCEDURE FixSysObjects
   IS
     curObjs ref_cur_type;
     nSuid NUMBER;
     nDbuid NUMBER;
     objSql VARCHAR2(4000) := 'SELECT distinct db_uid FROM stage_syb12_sysobjects
          WHERE svrid_fk = :1 and dbid_gen_fk=:2';

     CURSOR curDb IS SELECT dbid_gen FROM stage_syb12_sysdatabases WHERE svrid_fk = nSvrId;
     errMsg VARCHAR2(4000);
   BEGIN

      FOR r_c1 IN curDb
      LOOP
      BEGIN
         OPEN curObjs FOR objSql USING nsvrid, r_c1.dbid_gen;
         FETCH curObjs INTO nDbuid;
         LOOP  -- loop through sysobjects for each of the distinct uid & fix the generated suid
         BEGIN
             EXIT WHEN curObjs%NOTFOUND;

             -- assuming 1 to 1 correspondance between suid and uid within a database
             SELECT suid_gen INTO nSuid 
               FROM stage_syb12_sysusers 
               WHERE db_uid = nDbuid
               AND dbid_gen_fk = r_c1.dbid_gen;

             UPDATE stage_syb12_sysobjects
               SET suid_gen_fk = nSuid 
                 WHERE db_uid = nDbuid 
                 AND dbid_gen_fk = r_c1.dbid_gen
                 and svrid_fk = nSvrId;

             FETCH curObjs INTO nDbuid;
        EXCEPTION 
          WHEN OTHERS THEN
                  errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                  LogInfo(NULL, sev_err, 'FixSysObjects Inner cursor issue [' || errMsg ||  '] nsvrid:r_c1.dbid_gen:nDbuid:nSuid: ' || nsvrid || ':' 
                                               || r_c1.dbid_gen || ':' || nDbuid || ':' || nSuid, NULL, NULL, nSvrId); 
                  FETCH curObjs INTO nDbuid;                                
         END;    
         END LOOP; -- sysobjects loop
         CLOSE curObjs;
      EXCEPTION 
        WHEN OTHERS THEN
                errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                LogInfo(NULL, sev_err, 'FixSysObjects Master cursor issue [' || errMsg ||  '] nsvrid:r_c1.dbid_gen: ' || nsvrid || ':' || r_c1.dbid_gen, NULL, NULL, nSvrId);                    
      END;
      END LOOP; -- sysdatabases loop      
   END FixSysObjects;

   PROCEDURE FixSysIndexes
   IS
     CURSOR curIndexRec IS SELECT distinct B."TABLE_ID", A.objid_gen, A.svrid_fk, A.dbid_gen_fk
                  FROM STAGE_SYB12_SYSOBJECTS A, STAGE_SYB12_SYSINDEXES B
                  WHERE A.dbid_gen_fk = B.dbid_gen_fk
                    AND A.svrid_fk = B.svrid_fk
                    AND B.svrid_fk = nSvrId
                    AND A."ID" = B."TABLE_ID";
    errMsg VARCHAR2(4000) := NULL;
   BEGIN
      FOR r_c1 IN curIndexRec
      LOOP
      BEGIN
         UPDATE STAGE_SYB12_SYSINDEXES SET id_gen_fk = r_c1.objid_gen WHERE "TABLE_ID" = r_c1."TABLE_ID" AND svrid_fk = r_c1.svrid_fk AND dbid_gen_fk = r_c1.dbid_gen_fk;
      EXCEPTION 
        WHEN OTHERS THEN
                errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                LogInfo(NULL, sev_err, 'FixSysIndexes Master cursor issue [' || errMsg ||  '] r_c1."TABLE_ID":r_c1.svrid_fk:r_c1.dbid_gen_fk: ' || r_c1."TABLE_ID" || ':' || r_c1.svrid_fk || ':'
                                                                               || r_c1.dbid_gen_fk, NULL, NULL, nSvrId);                             
      END;
      END LOOP;
   END FixSysIndexes;

   PROCEDURE FixSysColumns
   IS
     CURSOR curColRec IS SELECT A.svrid_fk svrid_fk,A.dbid_gen_fk,  B."ID", A.objid_gen 
                  FROM STAGE_SYB12_SYSOBJECTS A, STAGE_SYB12_SYSCOLUMNS B
                  WHERE A.dbid_gen_fk = B.dbid_gen_fk
                    AND A.svrid_fk = B.svrid_fk
                    AND B.svrid_fk = nSvrId
                    AND A."ID" = B."ID";  
      errMsg VARCHAR2(4000) := NULL;
   BEGIN
      FOR r_c1 IN curColRec
      LOOP
      BEGIN
         UPDATE STAGE_SYB12_SYSCOLUMNS SET id_gen_fk = r_c1.objid_gen WHERE "ID" = r_c1."ID" AND svrid_fk = r_c1.svrid_fk AND dbid_gen_fk = r_c1.dbid_gen_fk;
      EXCEPTION
        WHEN OTHERS THEN
                errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                LogInfo(NULL, sev_err, 'FixSysColumns Master cursor issue [' || errMsg ||  '] r_c1."ID":r_c1.svrid_fk:r_c1.dbid_gen_fk: ' || r_c1."ID" || ':' || r_c1.svrid_fk || ':'
                                                                               || r_c1.dbid_gen_fk, NULL, NULL, nSvrId);                                   
      END;
      END LOOP;
   END FixSysColumns;

   PROCEDURE FixSysComments
   IS
     CURSOR curCommentsRec IS SELECT distinct B."ID", A.objid_gen, A.dbid_gen_fk, A.svrid_fk  
                  FROM STAGE_SYB12_SYSOBJECTS A, STAGE_SYB12_SYSCOMMENTS B
                  WHERE A.dbid_gen_fk = B.dbid_gen_fk
                    AND A.svrid_fk = B.svrid_fk
                    AND B.svrid_fk = nSvrId
                    AND A."ID" = B."ID";      
     errMsg VARCHAR2(4000) := NULL;
   BEGIN
      FOR r_c1 IN curCommentsRec
      LOOP
      BEGIN
         UPDATE STAGE_SYB12_SYSCOMMENTS SET id_gen_fk = r_c1.objid_gen WHERE "ID" = r_c1."ID" AND svrid_fk = r_c1.svrid_fk AND dbid_gen_fk = r_c1.dbid_gen_fk;
      EXCEPTION 
        WHEN OTHERS THEN
                errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                LogInfo(NULL, sev_err, 'FixSysComments Master cursor issue [' || errMsg ||  '] r_c1."ID":r_c1.svrid_fk:r_c1.dbid_gen_fk: ' || r_c1."ID" || ':' || r_c1.svrid_fk || ':'
                                                                               || r_c1.dbid_gen_fk, NULL, NULL, nSvrId);                                            
      END;
      END LOOP;
   END FixSysComments;

   PROCEDURE FixSysConstraints
   IS
      CURSOR curObjs IS SELECT * FROM stage_syb12_sysobjects;
      CURSOR curDB IS SELECT * FROM stage_syb12_sysdatabases;
   BEGIN
       --FixSysConstraints & FixSysReferences
       FOR r_c1 IN curDB
       LOOP
          BEGIN
             UPDATE stage_syb12_sysreferences
                SET frgn_dbid_gen_fk = r_c1.dbid_gen
                WHERE svrid_fk = r_c1.svrid_fk
                AND frgndbid = r_c1.dbid;

             UPDATE stage_syb12_sysreferences
                SET pmry_dbid_gen_fk = r_c1.dbid_gen
                WHERE svrid_fk = r_c1.svrid_fk
                AND pmrydbid = r_c1.dbid; 

          EXCEPTION WHEN NO_DATA_FOUND THEN
                 NULL;
          END;                    
       END LOOP;

       FOR r_c1 IN curObjs
       LOOP
          BEGIN
             UPDATE stage_syb12_sysconstraints
                 SET table_id_gen_fk = r_c1.objid_gen
                 WHERE svrid_fk = r_c1.svrid_fk
                     AND dbid_gen_fk = r_c1.dbid_gen_fk
                     AND tableid = r_c1."ID";  

             UPDATE stage_syb12_sysconstraints
                 SET constraint_gen = r_c1.objid_gen
                 WHERE svrid_fk = r_c1.svrid_fk
                     AND dbid_gen_fk = r_c1.dbid_gen_fk
                     AND constrid = r_c1."ID";  

             UPDATE STAGE_SYB12_SYSREFERENCES
                 SET constraint_gen_fk = r_c1.objid_gen
                 WHERE svrid_fk = r_c1.svrid_fk
                     AND dbid_gen_fk = r_c1.dbid_gen_fk
                     AND constrid = r_c1."ID";  

             UPDATE STAGE_SYB12_SYSREFERENCES
                 SET table_id_gen_fk = r_c1.objid_gen
                 WHERE svrid_fk = r_c1.svrid_fk
                     AND dbid_gen_fk = r_c1.dbid_gen_fk
                     AND tableid = r_c1."ID";  

             UPDATE STAGE_SYB12_SYSREFERENCES
                 SET ref_table_id_gen_fk = r_c1.objid_gen
                 WHERE svrid_fk = r_c1.svrid_fk
                     AND dbid_gen_fk = r_c1.dbid_gen_fk
                     AND reftabid = r_c1."ID";  

          EXCEPTION WHEN NO_DATA_FOUND THEN
                 NULL;
          END;          
       END LOOP;
       NULL;
   END;
   /*
     CURSOR curConstraintRec IS SELECT distinct B."TABLE_ID", A.objid_gen, A.dbid_gen_fk, A.svrid_fk   
                  FROM STAGE_SYB12_SYSOBJECTS A, STAGE_SYB12_SYSCONSTRAINTS B
                  WHERE A.dbid_gen_fk = B.dbid_gen_fk
                    AND A.svrid_fk = B.svrid_fk
                    AND B.svrid_fk = nSvrId
                    AND A."ID" = B."TABLE_ID";         
   BEGIN
      FOR r_c1 IN curConstraintRec
      LOOP
         UPDATE STAGE_SYB12_SYSCONSTRAINTS SET table_id_gen_fk = r_c1.objid_gen WHERE "TABLE_ID" = r_c1."TABLE_ID" AND svrid_fk = r_c1.svrid_fk AND dbid_gen_fk = r_c1.dbid_gen_fk;
      END LOOP;
   END FixSysConstraints;
   */
   PROCEDURE FixSysTypes
   IS
   BEGIN
      NULL;
   END FixSysTypes;

   PROCEDURE FixTranslatedSQL
   IS
      CURSOR curObjs IS SELECT * FROM STAGE_SYB12_SYSOBJECTS;
      errMsg VARCHAR2(4000) := NULL;
   BEGIN
      FOR r_c1 IN curObjs
      LOOP
      BEGIN
         UPDATE STAGE_TRANSLATEDSQL 
            SET OBJ_ID_FK = r_c1.OBJID_GEN
            WHERE SERVER_ID_FK = r_c1.SVRID_FK
               AND DB_ID_FK = r_c1.DBID_GEN_FK
               --AND SCHEMA_ID_FK = r_c1.DB_UID
               AND OBJ_ID_FK = r_c1.ID;
      EXCEPTION
        WHEN OTHERS THEN
                errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                LogInfo(NULL, sev_err, 'FixTranslatedSQL Master cursor issue [' || errMsg ||  '] r_c1.OBJID_GEN:r_c1.svrid_fk:r_c1.dbid_gen_fk: ' || r_c1.OBJID_GEN || ':' || r_c1.svrid_fk || ':'
                                                                               || r_c1.dbid_gen_fk, NULL, NULL, nSvrId);                                                  
      END;
      END LOOP;
      COMMIT;
   END FixTranslatedSQL;

   PROCEDURE UpdateScratchModel
   IS
      CURSOR curDerived IS SELECT * FROM MD_DERIVATIVES WHERE DERIVED_TYPE IN ('MD_VIEWS', 
                                                   'MD_STORED_PROGRAMS', 'MD_TRIGGERS') AND (derivative_reason IS NULL OR derivative_reason <> 'SCRATCH');
      v_TransSQL CLOB;
      v_SourceSQL CLOB;
      errMsg VARCHAR2(4000);
   BEGIN
      FOR r_c1 IN curDerived
      LOOP
         BEGIN
           SELECT trans_sql,native_sql INTO v_TransSQL,v_SourceSQL 
                             FROM STAGE_TRANSLATEDSQL
                             WHERE OBJ_ID_FK = r_c1.SRC_ID;
           IF v_TransSQL IS NOT NULL 
           THEN  
             IF r_c1.DERIVED_TYPE = 'MD_VIEWS'
             THEN
                UPDATE MD_VIEWS 
                   SET NATIVE_SQL = v_TransSQL, "LANGUAGE" = 'OracleSQL'
                      WHERE ID = r_c1.DERIVED_ID;
             ELSIF r_c1.DERIVED_TYPE = 'MD_STORED_PROGRAMS' THEN
                UPDATE MD_STORED_PROGRAMS 
                   SET NATIVE_SQL = v_TransSQL, "LANGUAGE" = 'OracleSQL'
                      WHERE ID = r_c1.DERIVED_ID;
             ELSIF r_c1.DERIVED_TYPE = 'MD_TRIGGERS' THEN
                UPDATE MD_TRIGGERS 
                   SET NATIVE_SQL = v_TransSQL, "LANGUAGE" = 'OracleSQL'
                      WHERE ID = r_c1.DERIVED_ID;
             END IF;
          ELSE   
              IF r_c1.DERIVED_TYPE = 'MD_VIEWS'
             THEN
                UPDATE MD_VIEWS 
                   SET NATIVE_SQL = v_sourceSQL
                      WHERE ID = r_c1.DERIVED_ID;
             ELSIF r_c1.DERIVED_TYPE = 'MD_STORED_PROGRAMS' THEN
                UPDATE MD_STORED_PROGRAMS 
                   SET NATIVE_SQL = v_sourceSQL
                      WHERE ID = r_c1.DERIVED_ID;
             ELSIF r_c1.DERIVED_TYPE = 'MD_TRIGGERS' THEN
                UPDATE MD_TRIGGERS 
                   SET NATIVE_SQL = v_sourceSQL
                      WHERE ID = r_c1.DERIVED_ID;
             END IF;
          END IF;   
         EXCEPTION 
            WHEN NO_DATA_FOUND THEN
               NULL;
            WHEN OTHERS THEN
                errMsg := LOCALSUBSTRB(dbms_utility.format_error_stack || ' : ' || dbms_utility.format_error_backtrace);
                LogInfo(NULL, sev_err, 'UpdateScratchModel Master cursor issue [' || errMsg ||  '] r_c1.SRC_ID:r_c1.DERIVED_ID:r_c1.DERIVED_TYPE: ' || r_c1.SRC_ID || ':' || r_c1.DERIVED_ID || ':'
                                                                               || r_c1.DERIVED_TYPE, NULL, NULL, nSvrId);                                                              
         END;
      END LOOP;

   END;

   PROCEDURE FixStageKeyReferences
   IS
   BEGIN
       FixSysDatabases;
       FixSysUsers;
       FixSysObjects;
       FixTranslatedSQL;
       FixSysColumns;       
       FixSysComments;       
       FixSysConstraints;       
       FixSysIndexes;
       FixSysTypes;
   END;

   PROCEDURE RegisterSybasePlugin
   IS
   BEGIN
      INSERT INTO md_additional_properties(
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
                                             pluginClass -- might be 12 or 15
                                          );
      COMMIT;                                          
   END;


 FUNCTION StageCapture(projectId NUMBER, pluginClassIn varchar2, pjExists BOOLEAN := FALSE, p_scratchModel BOOLEAN := FALSE) RETURN VARCHAR2
   IS
     ret_val NAME_AND_COUNT_ARRAY;
     scratchConnId NUMBER :=0;
     connectionStatsResult NUMBER;
     n number:=0;
   BEGIN
      -- What should be done when the project with this id is already captured??
      exceptionOccurred :=FALSE;
      nProjectId := projectId;
      projectExist := pjExists;
      pluginClass := pluginClassIn;

      -- NOTE that nSvrId is the capture connection id (with a really bad name)
      SELECT svrid into nSvrId FROM STAGE_SERVERDETAIL
          WHERE project_id = projectId;

      -- Initialize the log status table
       INSERT INTO migrlog(parent_log_id, log_date, severity, logtext, phase, ref_object_id, ref_object_type, connection_id_fk) 
             VALUES(NULL, systimestamp, 666, 'Capture Started', 'CAPTURE', NULL, NULL, projectId);

       COMMIT;          
      --SetStatus('Capture processing started');          
      FixStageKeyReferences;      
      CaptureEntireStage;
      RegisterSybasePlugin;  -- pre-requisite for conversion to work correctly. e.g data type mapping.

      connectionStatsResult:=MIGRATION.gatherConnectionStats(nSvrId,'This is a capture model created using the enterprise estimation cmd tool');
      COMMIT;
      MIGRATION.POPULATE_DERIVATIVES_TABLE(nSvrId); --new identifier mapping setup
      COMMIT;      
      IF p_scratchModel = TRUE
      THEN
	      scratchConnId := MIGRATION.copy_connection_cascade(p_connectionid =>  nSvrId, p_scratchModel =>  TRUE);            
	      ret_val := migration.transform_all_identifiers(scratchConnId, '',  TRUE);
	      UpdateScratchModel;
        connectionStatsResult:=MIGRATION.gatherConnectionStats(scratchConnId,'This is a scratch model used for analysis and estimation');
        COMMIT;
      END IF;
      DELETE migrlog WHERE phase='CAPTURE' AND severity = 666 AND connection_id_fk = projectId;
      COMMIT; 

      --IF exceptionOccurred = TRUE THEN
      --   RAISE CaptureNotClean;
      --END IF;

      RETURN ''|| nSvrId||'/'||scratchConnId;
      EXCEPTION
      WHEN OTHERS THEN
        RAISE;
   END StageCapture;

END SYB12ALLPLATFORM;
/