CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate".TDALLPLATFORM AS   

    TYPE IDMAP is table of number index by varchar2(512);
    TYPE CHECKIDMAP is table of number index by varchar2(4000);
    TYPE UDTMAP is table of varchar2(4000) index by varchar2(512);
    TYPE NAMEMAP is table of varchar2(512) index by varchar2(512);


    DATABASEIDS IDMAP;
    TABLEIDS IDMAP;
    VIEWIDS IDMAP;
    COLUMNIDS IDMAP;
    CONSTRAINTIDS IDMAP;
    PKEYIDS IDMAP;
    CHECKIDS CHECKIDMAP;
    UDTNAMEMAP UDTMAP;
    PKEYNAMEMAP NAMEMAP;

    logLine NUMBER := 1;
    uniqueId NUMBER := 1;
    nProjectId  NUMBER;
    projectExist BOOLEAN;
    nSvrId NUMBER; -- This is the captured connection id
    nDummyCatalogId NUMBER;  --  Teradata does not have catalogs so insert a dummy one
    pluginClass varchar2(500) := null;

    PROCEDURE SetStatus(msg VARCHAR2, sev NUMBER := 666);

--    PROCEDURE DisableRepositoryTriggers IS
--    BEGIN
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_projects_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_catalogs_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_schemas_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_tables_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_views_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_indexes_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_stored_programs_trg DISABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_triggers_trg DISABLE';
--        --EXECUTE IMMEDIATE 'ALTER TRIGGER md_constraints_trg DISABLE';      
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_columns_trg DISABLE';      
--    END DisableRepositoryTriggers;

--    PROCEDURE EnableRepositoryTriggers IS
--    BEGIN
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_projects_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_catalogs_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_schemas_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_tables_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_views_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_indexes_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_stored_programs_trg ENABLE';
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_triggers_trg ENABLE';
--        --EXECUTE IMMEDIATE 'ALTER TRIGGER md_constraints_trg ENABLE';      
--        EXECUTE IMMEDIATE 'ALTER TRIGGER md_columns_trg ENABLE';      
--    END EnableRepositoryTriggers;

    FUNCTION getTypeLenCode(type VARCHAR2, COLUMNLENGTH NUMBER, DECIMALTOTALDIGITS NUMBER, DECIMALFRACTIONALDIGITS NUMBER) RETURN NUMBER IS
    BEGIN
        if (type IS NULL) THEN
            return 0;
        END IF;
        RETURN CASE TRIM(type)
                   WHEN 'AT' THEN  26 -- ANSITIME
                   WHEN 'BF' THEN  COLUMNLENGTH -- BYTEFIXED
                   WHEN 'BO' THEN -8 -- BYTELARGEOBJECT
                   WHEN 'BS' THEN  0 -- BINARYSTRING
                   WHEN 'BV' THEN -2 -- BYTEVARYING
                   WHEN 'CF' THEN  COLUMNLENGTH -- CHARFIXEDLATIN
                   WHEN 'CO' THEN -8 -- CHARLARGEOBJECT
                   WHEN 'CS' THEN  0 -- CHARSTRING
                   WHEN 'CV' THEN  0 -- CHARVARYINGLATIN
                   WHEN 'D ' THEN  4 -- DECIMAL
                   WHEN 'D'  THEN  4 -- DECIMAL
                   WHEN 'DA' THEN 10 -- DATE
                   WHEN 'DH' THEN  DECIMALTOTALDIGITS + 10 -- DAYHOUR
                   WHEN 'DI' THEN  0 -- DAYINTERVAL
                   WHEN 'DM' THEN  DECIMALTOTALDIGITS + 10 -- DAYMINUTE
                   WHEN 'DS' THEN  CASE DECIMALFRACTIONALDIGITS > 0
                                       WHEN TRUE THEN DECIMALTOTALDIGITS + 10
                                       ELSE DECIMALTOTALDIGITS + DECIMALFRACTIONALDIGITS + 11
                                   END -- DAYSECOND
                   WHEN 'DT' THEN  0 -- DATETAG
                   WHEN 'DY' THEN  DECIMALTOTALDIGITS + 10 -- DAY
                   WHEN 'F ' THEN  0 -- REAL
                   WHEN 'F'  THEN  0 -- REAL
                   WHEN 'HM' THEN  CASE DECIMALTOTALDIGITS
                                       WHEN 4 THEN 10 + 3
                                       WHEN 3 THEN 10 + 2
                                       ELSE 10 + 1
                                   END -- HOURMINUTE
                   WHEN 'HR' THEN  CASE DECIMALTOTALDIGITS
                                       WHEN 4 THEN 10 + 3
                                       WHEN 3 THEN 10 + 2
                                       ELSE 10 + 1
                                   END -- HOUR
                   WHEN 'HS' THEN  CASE DECIMALTOTALDIGITS
                                       WHEN 4 THEN CASE DECIMALFRACTIONALDIGITS > 0
                                                       WHEN TRUE THEN 11 + 3
                                                       ELSE 10 + 3
                                                   END
                                       WHEN 3 THEN CASE DECIMALFRACTIONALDIGITS > 0
                                                       WHEN TRUE THEN 11 + 2
                                                       ELSE 10 + 2
                                                   END
                                       ELSE CASE DECIMALFRACTIONALDIGITS > 0
                                                WHEN TRUE THEN 11 + 1
                                                ELSE 10 + 1
                                            END
                                   END -- HOURSECOND
                   WHEN 'I ' THEN  4 -- INTEGER
                   WHEN 'I'  THEN  4 -- INTEGER
                   WHEN 'I1' THEN  1 -- BYTEINT
                   WHEN 'I2' THEN  2 -- SMALLINT
                   WHEN 'I8' THEN  8 -- BIGINTEGER
                   WHEN 'LF' THEN  0 -- CHARFIXEDLOCALE
                   WHEN 'LV' THEN  0 -- CHARVARYINGLOCALE
                   WHEN 'MI' THEN  11 -- MINUTE
                   WHEN 'MO' THEN  CASE DECIMALTOTALDIGITS
                                       WHEN 4 THEN 3 + 4
                                       WHEN 3 THEN 2 + 4
                                       ELSE 1 + 4
                                   END -- MONTH
                   WHEN 'MS' THEN  CASE DECIMALFRACTIONALDIGITS > 0
                                       WHEN TRUE THEN 12 + DECIMALFRACTIONALDIGITS
                                       ELSE 11
                                   END -- MINUTETOSECOND
                   WHEN 'NM' THEN  0 -- NUMBERTAG
                   WHEN 'PD' THEN  28 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_DATE_LENGTH
                   WHEN 'PM' THEN  72 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIMESTAMP_WITH_TZ_LENGTH
                   WHEN 'PS' THEN  60 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIMESTAMP_LENGTH
                   WHEN 'PT' THEN  38 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIME_LENGTH
                   WHEN 'PZ' THEN  50 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIME_WITH_TZ_LENGTH
                   WHEN 'SC' THEN  CASE DECIMALFRACTIONALDIGITS > 0
                                       WHEN TRUE THEN 12 + DECIMALFRACTIONALDIGITS
                                       ELSE 11
                                   END -- SECOND
                   WHEN 'SZ' THEN 31 -- TIMESTAMPWITHTIMEZONE
                   WHEN 'TM' THEN  0 -- TIMETAG
                   WHEN 'TS' THEN 26 -- TIMESTAMPWITHOUTTIMEZONE
                   WHEN 'TZ' THEN 21 -- ANSITIMEWITHTIMEZONE
                   WHEN 'UF' THEN  0 -- CHARFIXEDUNICODE
                   WHEN 'UT' THEN  0 -- USERDEFINEDTYPE
                   WHEN 'UV' THEN  0 -- CHARVARYINGUNICODE
                   WHEN 'YI' THEN  0 -- YEARINTERVAL
                   WHEN 'YM' THEN  DECIMALTOTALDIGITS + 4 -- YEARMONTH
                   WHEN 'YR' THEN  DECIMALTOTALDIGITS + 4 -- YEAR
                   ELSE 0
               END;
    END getTypeLenCode;

    FUNCTION getTypeLenCode(type VARCHAR2) RETURN NUMBER IS
    BEGIN
        if (type IS NULL) THEN
            return 0;
        END IF;
        RETURN CASE TRIM(type)
                   WHEN 'AT' THEN  0 -- ANSITIME
                   WHEN 'BF' THEN  0 -- BYTEFIXED
                   WHEN 'BO' THEN -8 -- BYTELARGEOBJECT
                   WHEN 'BS' THEN  0 -- BINARYSTRING
                   WHEN 'BV' THEN -2 -- BYTEVARYING
                   WHEN 'CF' THEN  0 -- CHARFIXEDLATIN
                   WHEN 'CO' THEN -8 -- CHARLARGEOBJECT
                   WHEN 'CS' THEN  0 -- CHARSTRING
                   WHEN 'CV' THEN  0 -- CHARVARYINGLATIN
                   WHEN 'D ' THEN  4 -- DECIMAL
                   WHEN 'D'  THEN  4 -- DECIMAL
                   WHEN 'DA' THEN  0 -- DATE
                   WHEN 'DH' THEN  0 -- DAYHOUR
                   WHEN 'DI' THEN  0 -- DAYINTERVAL
                   WHEN 'DM' THEN  0 -- DAYMINUTE
                   WHEN 'DS' THEN  0 -- DAYSECOND
                   WHEN 'DT' THEN  0 -- DATETAG
                   WHEN 'DY' THEN  0 -- DAY
                   WHEN 'F ' THEN  0 -- REAL
                   WHEN 'F'  THEN  0 -- REAL
                   WHEN 'HM' THEN  0 -- HOURMINUTE
                   WHEN 'HR' THEN  0 -- HOUR
                   WHEN 'HS' THEN  0 -- HOURSECOND
                   WHEN 'I ' THEN  4 -- INTEGER
                   WHEN 'I'  THEN  4 -- INTEGER
                   WHEN 'I1' THEN  1 -- BYTEINT
                   WHEN 'I2' THEN  2 -- SMALLINT
                   WHEN 'I8' THEN  8 -- BIGINTEGER
                   WHEN 'LF' THEN  0 -- CHARFIXEDLOCALE
                   WHEN 'LV' THEN  0 -- CHARVARYINGLOCALE
                   WHEN 'MI' THEN  0 -- MINUTE
                   WHEN 'MO' THEN  0 -- MONTH
                   WHEN 'MS' THEN  0 -- MINUTETOSECOND
                   WHEN 'NM' THEN  0 -- NUMBERTAG
                   WHEN 'PD' THEN  28 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_DATE_LENGTH
                   WHEN 'PM' THEN  72 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIMESTAMP_WITH_TZ_LENGTH
                   WHEN 'PS' THEN  60 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIMESTAMP_LENGTH
                   WHEN 'PT' THEN  38 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIME_LENGTH
                   WHEN 'PZ' THEN  50 -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIME_WITH_TZ_LENGTH
                   WHEN 'SC' THEN  0 -- SECOND
                   WHEN 'SZ' THEN  0 -- TIMESTAMPWITHTIMEZONE
                   WHEN 'TM' THEN  0 -- TIMETAG
                   WHEN 'TS' THEN  0 -- TIMESTAMPWITHOUTTIMEZONE
                   WHEN 'TZ' THEN  0 -- ANSITIMEWITHTIMEZONE
                   WHEN 'UF' THEN  0 -- CHARFIXEDUNICODE
                   WHEN 'UT' THEN  0 -- USERDEFINEDTYPE
                   WHEN 'UV' THEN  0 -- CHARVARYINGUNICODE
                   WHEN 'YI' THEN  0 -- YEARINTERVAL
                   WHEN 'YM' THEN  0 -- YEARMONTH
                   WHEN 'YR' THEN  0 -- YEAR
                   ELSE 0
               END;
    END getTypeLenCode;

    FUNCTION getTypeName(type VARCHAR2, charType NUMBER, udtName VARCHAR2) RETURN VARCHAR2;

    PROCEDURE registerUDTS IS
        moreToDo BOOLEAN := TRUE;
        countUDTs NUMBER := 0;
    BEGIN
        UDTNAMEMAP('ST_GEOMETRY') := 'ST_GEOMETRY';
        UDTNAMEMAP('MBR') := 'MBR';
        WHILE (moreToDo) LOOP
            countUDTs := UDTNAMEMAP.COUNT;
            FOR field IN
            (
                SELECT
                    "MDID",
                    "TYPEKIND",
                    "TYPENAME",
                    "FIELDNAME",
                    "FIELDID",
                    "FIELDTYPE",
                    "UDTNAME",
                    "CHARTYPE",
                    "MAXLENGTH",
                    "DECIMALTOTALDIGITS",
                    "DECIMALFRACTIONALDIGITS",
                    "INSTANTIABLE",
                    "FINAL"
                FROM
                    STAGE_TERADATA_UDTS
                ORDER BY
                    TYPENAME,
                    FIELDID
            )
            LOOP
                IF (field.TYPEKIND = 'D') THEN
                    IF NOT (UDTNAMEMAP.EXISTS(field.TYPENAME)) THEN
                        IF (field.FIELDTYPE = 'UT') THEN
                            IF (UDTNAMEMAP.EXISTS(field.UDTNAME)) THEN
                                -- copy definition to this one
                                UDTNAMEMAP(field.TYPENAME) := UDTNAMEMAP(field.UDTNAME);
                            END IF;
                        ELSE
                            UDTNAMEMAP(field.TYPENAME) := getTypeName(field.FIELDTYPE, field.CHARTYPE, field.UDTNAME);
                        END IF;
                    END IF;
                END IF;
            END LOOP;
            moreToDo := countUDTS <> UDTNAMEMAP.COUNT;
        END LOOP;
    END registerUDTs;

    FUNCTION getTypeName(type VARCHAR2, charType NUMBER, udtName VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        SetStatus('getTypeName: ' || type || ', ' || udtName);
        IF (type IS NULL) THEN
            RETURN NULL;
        END IF;
--        IF (type = 'UT' AND udtName = 'ST_GEOMETRY') THEN
--            RETURN 'ST_GEOMETRY';
--        END IF;
        RETURN CASE TRIM(type)
                   WHEN 'AT' THEN 'ANSITIME'
                   WHEN 'BF' THEN 'BYTEFIXED'
                   WHEN 'BO' THEN 'BYTELARGEOBJECT'
                   WHEN 'BS' THEN 'BINARYSTRING'
                   WHEN 'BV' THEN 'BYTEVARYING'
                   WHEN 'CF' THEN 'CHARFIXED' || ( CASE charType WHEN 1 THEN 'LATIN' WHEN 2 THEN 'UNICODE' WHEN 3 THEN 'KANJISJIS' WHEN 4 THEN 'GRAPHIC' WHEN 5 THEN 'KANJI1' ELSE 'LATIN' END)
                   WHEN 'CO' THEN 'CHARLARGEOBJECT' || ( CASE charType WHEN 1 THEN 'LATIN' WHEN 2 THEN 'UNICODE' WHEN 3 THEN 'KANJISJIS' WHEN 4 THEN 'GRAPHIC' WHEN 5 THEN 'KANJI1' ELSE 'LATIN' END)
                   WHEN 'CS' THEN 'CHARSTRING'
                   WHEN 'CV' THEN 'CHARVARYING' || ( CASE charType WHEN 1 THEN 'LATIN' WHEN 2 THEN 'UNICODE' WHEN 3 THEN 'KANJISJIS' WHEN 4 THEN 'GRAPHIC' WHEN 5 THEN 'KANJI1' ELSE 'LATIN' END)
                   WHEN 'D'  THEN 'DECIMAL'
                   WHEN 'DA' THEN 'DATE'
                   WHEN 'DH' THEN 'DAYHOUR'
                   WHEN 'DI' THEN 'DAYINTERVAL'
                   WHEN 'DM' THEN 'DAYMINUTE'
                   WHEN 'DS' THEN 'DAYSECOND'
                   WHEN 'DT' THEN 'DATETAG'
                   WHEN 'DY' THEN 'DAY'
                   WHEN 'F'  THEN 'REAL'
                   WHEN 'HM' THEN 'HOURMINUTE'
                   WHEN 'HR' THEN 'HOUR'
                   WHEN 'HS' THEN 'HOURSECOND'
                   WHEN 'I'  THEN 'INTEGER'
                   WHEN 'I1' THEN 'BYTEINT'
                   WHEN 'I2' THEN 'SMALLINT'
                   WHEN 'I8' THEN 'BIGINTEGER'
                   WHEN 'LF' THEN 'CHARFIXEDLOCALE'
                   WHEN 'LV' THEN 'CHARVARYINGLOCALE'
                   WHEN 'MI' THEN 'MINUTE'
                   WHEN 'MO' THEN 'MONTH'
                   WHEN 'MS' THEN 'MINUTETOSECOND'
                   WHEN 'NM' THEN 'NUMBERTAG'
                   WHEN 'PD' THEN 'PERIODDATE'
                   WHEN 'PM' THEN 'PERIODTIMESTAMPWITHTIMEZONE'
                   WHEN 'PS' THEN 'PERIODTIMESTAMP'
                   WHEN 'PT' THEN 'PERIODTIME'
                   WHEN 'PZ' THEN 'PERIODTIMEWITHTIMEZONE'
                   WHEN 'SC' THEN 'SECOND'
                   WHEN 'SZ' THEN 'TIMESTAMPWITHTIMEZONE'
                   WHEN 'TM' THEN 'TIMETAG'
                   WHEN 'TS' THEN 'TIMESTAMPWITHOUTTIMEZONE'
                   WHEN 'TZ' THEN 'ANSITIMEWITHTIMEZONE'
                   WHEN 'UF' THEN 'CHARFIXEDUNICODE'
                   WHEN 'UT' THEN ( case UDTNAMEMAP.EXISTS(udtName) WHEN TRUE THEN UDTNAMEMAP(udtName) WHEN FALSE THEN NULL END )
                   WHEN 'UV' THEN 'CHARVARYINGUNICODE'
                   WHEN 'YI' THEN 'YEARINTERVAL'
                   WHEN 'YM' THEN 'YEARMONTH'
                   WHEN 'YR' THEN 'YEAR'
                   else TRIM(type)
               END;
    END getTypeName;

    FUNCTION getProcFunc(prgType VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        return CASE 
                   WHEN prgType in ('F', 'A', 'B', 'R', 'S') THEN 'FUNCTION'
                   WHEN prgType in ('P', 'E') THEN 'PROCEDURE'
                   ELSE 'NONE'
               END;
    END getProcFunc;

    PROCEDURE CaptureConnections IS
    BEGIN
        -- create project
        SetStatus('CaptureConnections');
        IF (projectExist = FALSE) THEN            
            INSERT INTO md_projects("ID", project_name, comments)
            (
                SELECT
                    project_id, project_name, comments
                FROM
                    stage_serverdetail WHERE project_id = nProjectId
                    AND NOT EXISTS (SELECT 1 FROM md_projects WHERE "ID" = nProjectId)
            ); 
        END IF;
        -- capture connections
        INSERT INTO md_connections("ID", project_id_fk, username, dburl, "NAME")
        (
            SELECT SVRID, nProjectId, username, dburl, db_name 
            FROM stage_serverdetail WHERE project_id = nProjectId
        );
    END CaptureConnections;

    PROCEDURE CaptureDatabases IS
    BEGIN
        SetStatus('CaptureDatabases');
        nDummyCatalogId := MD_META.get_next_id;
        INSERT INTO md_catalogs("ID", connection_id_fk, catalog_name, dummy_flag)
        VALUES ( nDummyCatalogId, nSvrId, 'Teradata', 'Y' );
    END CaptureDatabases;

    PROCEDURE CaptureSchemas IS
    BEGIN
        SetStatus('CaptureSchemas');
        FOR db IN
        (
            SELECT
                SVRID,
                MDID,
                DATABASENAME,
                COMMENTSTRING,
                OWNERNAME
            FROM STAGE_TERADATA_DATABASES
        )
        LOOP
            --DBMS_OUTPUT.PUT_LINE('Name = ' || db.DATABASENAME || ', ID = ' || db.MDID);
            INSERT
                INTO md_schemas("ID", "CATALOG_ID_FK", "NAME")
                VALUES ( db.MDID, nDummyCatalogId, db.DATABASENAME );
            DATABASEIDS(TRIM(db.databasename)) := db.mdid;
        END LOOP;
    END;

    PROCEDURE CaptureTablesAndViews IS 
        errMsg VARCHAR2(4000);
        clbNativeSql CLOB := TO_CLOB(' ');
    BEGIN
        SetStatus('CaptureTablesAndViews');
        FOR tab IN
        (
            SELECT
                MDID,
                DATABASENAME,
                TABLENAME,
                TABLEKIND,
                CREATORNAME,
                REQUESTTEXT,
                COMMENTSTRING,
                COMMITOPT
            FROM STAGE_TERADATA_TABLES
        )
        LOOP
            --DBMS_OUTPUT.put_line('TABLE:' || tab.DATABASENAME || '.' || tab.TABLENAME);
            IF (tab.TABLEKIND = 'T') THEN
                INSERT
                    INTO md_tables("ID", schema_id_fk, table_name, qualified_native_name)
                    VALUES (tab.MDID, DATABASEIDS(TRIM(tab.DATABASENAME)), tab.TABLENAME, tab.DATABASENAME || '.' || tab.TABLENAME);
                TABLEIDS(TRIM(tab.DATABASENAME) || '.' || TRIM(tab.TABLENAME)) := tab.mdid;
                --SetStatus('CaptureTables: ' || TRIM(tab.DATABASENAME) || '.' || TRIM(tab.TABLENAME) || ' - ' || TABLEIDS(TRIM(tab.DATABASENAME) || '.' || TRIM(tab.TABLENAME)));

            END IF;
            IF (tab.TABLEKIND = 'V') THEN
                clbNativeSql  := TO_CLOB(tab.REQUESTTEXT);
                INSERT
                    INTO md_views("ID", schema_id_fk, view_name, "LANGUAGE", native_sql, comments)
                    VALUES (tab.MDID, DATABASEIDS(TRIM(tab.DATABASENAME)), tab.TABLENAME, 'Teradata', clbNativeSql, tab.COMMENTSTRING);
                VIEWIDS(TRIM(tab.DATABASENAME) || '.' || TRIM(tab.TABLENAME)) := tab.mdid;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception:' || errMsg);
            RAISE;
    END CaptureTablesAndViews;

    PROCEDURE CaptureColumns IS
        errMsg VARCHAR2(4000);
        typeName VARCHAR2(64);
        id NUMBER;
        dumpLenCode NUMBER;
        prec NUMBER;
    BEGIN
        SetStatus('CaptureColumns');
        FOR col IN
        (
            SELECT
                MDID,
                DATABASENAME,
                TABLENAME,
                COLUMNNAME,
                COLUMNFORMAT,
                COLUMNTITLE,
                COLUMNTYPE,
                COLUMNUDTNAME,
                COLUMNLENGTH,
                DEFAULTVALUE,
                NULLABLE,
                COMMENTSTRING,
                DECIMALTOTALDIGITS,
                DECIMALFRACTIONALDIGITS,
                COLUMNID,
                UPPERCASEFLAG,
                COLUMNCONSTRAINT,
                CONSTRAINTCOUNT,
                CREATORNAME,
                CHARTYPE,
                IDCOLTYPE
            FROM STAGE_TERADATA_COLUMNS
        )
        LOOP
            IF (TABLEIDS.EXISTS(TRIM(col.DATABASENAME) || '.' || TRIM(col.TABLENAME))) THEN
                id := TABLEIDS(TRIM(col.DATABASENAME) || '.' || TRIM(col.TABLENAME));
                prec := CASE
                            WHEN ((col.DECIMALTOTALDIGITS IS NOT NULL)/*OR(col.DECIMALFRACTIONALDIGITS IS NOT NULL) */) then (col.DECIMALTOTALDIGITS)
                            ELSE (col.COLUMNLENGTH) 
                        END;

                --DBMS_OUTPUT.put_line('COLUMN:' || col.DATABASENAME || '.' || col.TABLENAME || '.' || col.COLUMNNAME || ' ID: ' || id);
                --insert into STAGE_TERADATA_LOG (LINE, LOGSTRING) VALUES (logLine, 'ROB-COLUMN:' || col.DATABASENAME || '.' || col.TABLENAME || '.' || col.COLUMNNAME || ' ID: ' || id);
                --logLine := logLine + 1;

                typeName := getTypeName(col.COLUMNTYPE, col.CHARTYPE, col.COLUMNUDTNAME);
                IF (col.COLUMNTYPE IS NOT NULL) THEN
                    IF (col.COLUMNTYPE = 'PD') THEN
                        prec := 28;-- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_DATE_LENGTH
                    END IF;
                    IF (col.COLUMNTYPE = 'PM') THEN
                        prec := 72; -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIMESTAMP_WITH_TZ_LENGTH
                    END IF;
                    IF (col.COLUMNTYPE = 'PS') THEN
                        prec := 60; -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIMESTAMP_LENGTH
                    END IF;
                    IF (col.COLUMNTYPE = 'PT') THEN
                        prec := 38; -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIME_LENGTH
                    END IF;
                    IF (col.COLUMNTYPE = 'PZ') THEN
                        prec := 50; -- must match oracle.dbtools.migration.workbench.plugin.Teradata13Plugin.PERIOD_TIME_WITH_TZ_LENGTH
                    END IF;
                END IF;
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
                        col.MDID,
                        id,
                        col.COLUMNNAME,
                        col.COLUMNID,
                        typeName,
                        prec,
                        col.DECIMALFRACTIONALDIGITS,
                        col.NULLABLE,
                        CASE 
                            WHEN col.COLUMNTYPE in ('BV', 'BF', 'BO', 'BS') THEN  NULL
                            ELSE col.DEFAULTVALUE
                        END,
                        col.COMMENTSTRING
                    );
                IF (col.COLUMNTYPE IS NOT NULL) THEN
                    dumpLenCode := getTypeLenCode(col.COLUMNTYPE, col.COLUMNLENGTH, col.DECIMALTOTALDIGITS, col.DECIMALFRACTIONALDIGITS);
                    IF (col.COLUMNTYPE = 'PD') THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_PERIODDATE_COLUMN', 'needconverting');
                    END IF;
                    IF (col.COLUMNTYPE = 'PM') THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_PERIODTIMESTAMPWITHTIMEZONE_COLUMN', 'needconverting');
                    END IF;
                    IF (col.COLUMNTYPE = 'PS') THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_PERIODTIMESTAMP_COLUMN', 'needconverting');
                    END IF;
                    IF (col.COLUMNTYPE = 'PT') THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_PERIODTIME_COLUMN', 'needconverting');
                    END IF;
                    IF (col.COLUMNTYPE = 'PZ') THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_PERIODTIMEWITHTIMEZONE_COLUMN', 'needconverting');
                    END IF;
                    IF ((col.COLUMNTYPE = 'UT') AND (col.COLUMNUDTNAME = 'ST_GEOMETRY')) THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_ST_GEOMETRY_COLUMN', 'needconverting');
                        dumpLenCode := -2;
                    END IF;
                    IF ((col.COLUMNTYPE = 'UT') AND (col.COLUMNUDTNAME = 'MBR')) THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_MBR_COLUMN', 'needconverting');
                    END IF;
                    IF (dumpLenCode = 0) THEN
                        dumpLenCode := prec;
                    END IF;
                    INSERT
                        INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                        VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_DUMPLENDECODE', TO_CHAR(dumpLenCode));
                END IF;
                IF (col.COLUMNFORMAT IS NOT NULL) THEN
                    INSERT
                        INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                        VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_COLUMNFORMAT', col.COLUMNFORMAT);
                END IF;
                IF (col.COLUMNFORMAT IS NOT NULL) THEN
                    INSERT
                        INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                        VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_MAXLENGTH', col.COLUMNLENGTH);
                END IF;
                IF (col.DEFAULTVALUE IS NOT NULL) THEN
                    IF ((typeName = 'ANSITIME') OR (typeName = 'ANSITIMEWITHTIMEZONE')) THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_CHECK_TIME_DEFAULT', col.DEFAULTVALUE);
                    END IF;
                    IF ((typeName = 'TIMESTAMPWITHTIMEZONE') OR (typeName = 'TIMESTAMPWITHOUTTIMEZONE')) THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_CHECK_TIMESTAMP_DEFAULT', col.DEFAULTVALUE);
                    END IF;
                    IF (typeName = 'DATE') THEN
                        INSERT
                            INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                            VALUES(nSvrId, col.MDID, 'MD_COLUMNS', col.COLUMNID, 'TERADATA_CHECK_DATE_DEFAULT', col.DEFAULTVALUE);
                    END IF;
                END IF;
            END IF;
            COLUMNIDS(TRIM(col.DATABASENAME) || '.' || TRIM(col.TABLENAME) || '.' || TRIM(col.COLUMNNAME)) := col.mdid;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception:' || errMsg);
            RAISE;
    END CaptureColumns;

    PROCEDURE CaptureIndexes IS
        errMsg VARCHAR2(4000);
        indexId NUMBER;
        indexType VARCHAR(16);
        indexShortName VARCHAR2(128 CHAR);
        indexFullName VARCHAR2(270 CHAR); -- DATABASENAME || '.' || TABLENAME || '.' || INDEXNUMBER
        nextIndexName VARCHAR2(270 CHAR); -- DATABASENAME || '.' || TABLENAME || '.' || INDEXNUMBER
        columnId NUMBER;
        tableId NUMBER;
    BEGIN
        SetStatus('CaptureIndexes');
        indexId := NULL;
        FOR indexCol IN
        (
            SELECT
                MDID,
                DATABASENAME,
                TABLENAME,
                INDEXNUMBER,
                INDEXTYPE,
                UNIQUEFLAG,
                INDEXNAME,
                COLUMNNAME,
                COLUMNPOSITION,
                CREATORNAME,
                INDEXMODE
            FROM
                STAGE_TERADATA_INDICES
            WHERE
                INDEXTYPE = 'S' -- IN ('S', 'P', 'Q') -- includes partitioned/non partitioned primary indexes
            ORDER BY
                DATABASENAME,
                TABLENAME,
                INDEXNUMBER,
                COLUMNPOSITION
        )
        LOOP
            IF TABLEIDS.EXISTS(TRIM(indexCol.DATABASENAME) || '.' || TRIM(indexCol.TABLENAME)) THEN
                tableId := TABLEIDS(TRIM(indexCol.DATABASENAME) || '.' || TRIM(indexCol.TABLENAME));
                nextIndexName := indexCol.DATABASENAME || '.' || indexCol.TABLENAME || '.' || indexCol.INDEXNUMBER;
                IF (indexFullName IS NULL) OR (nextIndexName != indexFullName) THEN
                    IF (indexCol.UNIQUEFLAG = 'Y') THEN
                        indexType := 'UNIQUE';
                    ELSE
                        indexType := 'NON_UNIQUE';
                    END IF;
                    indexId := MD_META.get_next_id;
                    indexFullName := nextIndexName;
                    IF (indexCol.INDEXNAME IS NULL) THEN
                        indexShortName := indexCol.TABLENAME || indexCol.INDEXTYPE || indexCol.INDEXNUMBER; -- can't have a NULL index name
                    ELSE
                        indexShortName := indexCol.INDEXNAME;
                    END IF;
                    INSERT
                        INTO MD_INDEXES(id, table_id_fk, index_name, index_type)
                        VALUES(indexId, tableId, indexShortName, indexType);
                END IF;
                IF COLUMNIDS.EXISTS(TRIM(indexCol.DATABASENAME) || '.' || TRIM(indexCol.TABLENAME) || '.' || TRIM(indexCol.COLUMNNAME)) THEN
                    columnId := COLUMNIDS(TRIM(indexCol.DATABASENAME) || '.' || TRIM(indexCol.TABLENAME) || '.' || TRIM(indexCol.COLUMNNAME));
                    INSERT
                        INTO MD_INDEX_DETAILS(id, index_id_fk, column_id_fk, detail_order)
                        VALUES(indexCol.MDID, indexId, columnId, indexCol.COLUMNPOSITION);
                END IF;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception(CaptureIndexes):' || errMsg);
            RAISE;
    END CaptureIndexes;

    PROCEDURE CapturePrimaryKeys IS
        errMsg VARCHAR2(4000);
        pKeyId NUMBER;
        pKeyType VARCHAR(16);
        pKeyName VARCHAR2(270 CHAR);
        tableName VARCHAR2(270 CHAR);
        nextPKeyName VARCHAR2(270 CHAR);
        nextTableName VARCHAR2(270 CHAR);
        shortConstraintName VARCHAR2(270 CHAR);
        columnId NUMBER;
        tableId NUMBER;
    BEGIN
        SetStatus('CapturePrimaryKeys');
        pKeyId := NULL;
        pKeyName := NULL;
        FOR pKeyCol IN
        (
            SELECT
                COALESCE(INDEXNAME, TRIM(TABLENAME) || '_' || TRIM(INDEXTYPE) || TRIM(INDEXNUMBER)) CONSTRAINTNAME,
                MDID,
                DATABASENAME,
                TABLENAME,
                INDEXNUMBER,
                INDEXTYPE,
                UNIQUEFLAG,
                INDEXNAME,
                COLUMNNAME,
                COLUMNPOSITION,
                CREATORNAME,
                INDEXMODE
            FROM
                STAGE_TERADATA_INDICES
            WHERE
                IndexType in ('K', 'P', 'Q', 'U')
            ORDER BY DATABASENAME, TABLENAME, CONSTRAINTNAME, INDEXNUMBER, COLUMNPOSITION
        )
        LOOP
            SetStatus('CapturePrimaryKeys: ** ' || TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME) || '.' || TRIM(pKeyCol.CONSTRAINTNAME));
            IF TABLEIDS.EXISTS(TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME)) THEN
                tableId := TABLEIDS(TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME));
                IF (PKEYNAMEMAP.EXISTS(TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME) || '.' || TRIM(pKeyCol.CONSTRAINTNAME))) THEN
                    shortConstraintName := PKEYNAMEMAP(TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME) || '.' || TRIM(pKeyCol.CONSTRAINTNAME));
                ELSE
                    shortConstraintName := TRIM(pKeyCol.CONSTRAINTNAME);
                END IF;
                SetStatus('CapturePrimaryKeys: ++ ' || shortConstraintName || '<==>' || TRIM(pKeyCol.CONSTRAINTNAME));
                nextPKeyName := TRIM(pkeyCol.DATABASENAME) || '.' || shortConstraintName;
                nextTableName := TRIM(pkeyCol.TABLENAME);
                IF (pKeyName IS NULL) OR (nextPKeyName != pKeyName) OR
                   (tableName IS NULL) OR (nextTableName != tableName) THEN
                    -- new Primary Key
                    pKeyId := MD_META.get_next_id;
                    IF (trim(pKeyCol.INDEXTYPE) = 'K') THEN
                        pKeyType := 'PK';
                    ELSE
                        IF (trim(pKeyCol.INDEXTYPE) = 'U') THEN
                            pKeyType := 'UNIQUE';
                        ELSE
                            IF (((trim(pKeyCol.INDEXTYPE) = 'Q') OR (trim(pKeyCol.INDEXTYPE) = 'P')) AND
                                ((pKeyCol.UNIQUEFLAG IS NOT NULL) AND (TRIM(pKeyCol.UNIQUEFLAG) = 'Y'))) THEN
                                pKeyType := 'UNIQUE';
                            ELSE
                                pKeyName := NULL; -- ignore and continue around loop
                                pKeyType := NULL;
                            END IF;
                        END IF;
                    END IF;
                    SetStatus('CapturePrimaryKeys: ## ' || TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME) || '.' || TRIM(pKeyCol.CONSTRAINTNAME) || ' - ' || pKeyType || '-' || pKeyName || '-' || TRIM(pKeyCol.INDEXTYPE) || '-' || nextPKeyName);
                    IF (pKeyType IS NOT NULL) THEN
                        SetStatus('CapturePrimaryKeys: -- ' || TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME) || '.' || TRIM(pKeyCol.CONSTRAINTNAME));
                        WHILE (PKEYIDS.EXISTS(nextPKeyName)) LOOP -- ensure unique
                            shortConstraintName := TRIM(pKeyCol.CONSTRAINTNAME) || uniqueId;
                            nextPKeyName := TRIM(pkeyCol.DATABASENAME) || '.' || shortConstraintName;
                            uniqueId := uniqueId + 1;
                        END LOOP;
                        SetStatus('CapturePrimaryKeys: == ' || nextPKeyName || ', ' || shortConstraintName || ', ' || pKeyType);
                        PKEYIDS(nextPKeyName) := pKeyId;
                        pKeyName := nextPKeyName;
                        tableName := nextTableName;
                        PKEYNAMEMAP(TRIM(pkeyCol.DATABASENAME) || '.' || TRIM(pkeyCol.TABLENAME) || '.' || TRIM(pKeyCol.CONSTRAINTNAME)) := shortConstraintName;
                        INSERT
                            INTO MD_CONSTRAINTS (ID, NAME, CONSTRAINT_TYPE, TABLE_ID_FK, "LANGUAGE")
                            VALUES (pKeyId, shortConstraintName, pKeyType, tableId, 'TERADATALANG');
                            CONSTRAINTIDS(UPPER(pKeyName)) := pKeyId;
                    END IF;
                END IF;
                IF (pKeyName IS NOT NULL) THEN
                    IF COLUMNIDS.EXISTS(TRIM(pKeyCol.DATABASENAME) || '.' || TRIM(pKeyCol.TABLENAME) || '.' || TRIM(pKeyCol.COLUMNNAME)) THEN
                        columnId := COLUMNIDS(TRIM(pKeyCol.DATABASENAME) || '.' || TRIM(pKeyCol.TABLENAME) || '.' || TRIM(pKeyCol.COLUMNNAME));
                        INSERT
                            INTO MD_CONSTRAINT_DETAILS(id, constraint_id_fk, column_id_fk, detail_order)
                            VALUES(MD_META.get_next_id, pKeyId, columnId, pKeyCol.COLUMNPOSITION);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception(CapturePrimaryKeys):' || errMsg);
            RAISE;
    END CapturePrimaryKeys;

    PROCEDURE CaptureForeignKeys IS
        errMsg VARCHAR2(4000);
        fKeyId NUMBER;
        fKeyType VARCHAR(16);
        fKeyName VARCHAR2(270 CHAR);
        currentReferenceIdx NUMBER;
        currentTableId NUMBER;
        columnId NUMBER;
        refColumnId NUMBER;
        tableId NUMBER;
        refTableId NUMBER;
        seq NUMBER;
    BEGIN
        SetStatus('CaptureForeignKeys');
        fKeyId := NULL;
        fKeyName := NULL;
        currentReferenceIdx := NULL;
        currentTableId := NULL;
        FOR fKeyCol IN
        (
            SELECT DISTINCT
                "MDID1",
                "MDID2",
                "TABLESCHEMA",
                "TABLENAME",
                "REFTABLESCHEMA",
                "REFTABLENAME",
                "CONSTRAINTNAME",
                "COLUMNNAME",
                "REFCOLUMNNAME",
                "REFKEYNAME",
                "COLUMNSEQ",
                "REFERENCEIDX",
                "FKEYID",
                "PARENTKEYID"
            FROM
                STAGE_TERADATA_FKEYS
            order by "TABLESCHEMA", "TABLENAME", "REFERENCEIDX", "COLUMNSEQ"
        )
        LOOP
--            SetStatus('CaptureForeignKeys: Row Read');
--            IF (TABLEIDS.EXISTS(TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME))) THEN
--                SetStatus('CaptureForeignKeys: ' || TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME) || ' - EXISTS');
--            ELSE
--                SetStatus('CaptureForeignKeys: ' || TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME) || ' - DOES NOT EXIST');
--            END IF;
--            IF (TABLEIDS.EXISTS(TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME))) THEN
--                SetStatus('CaptureForeignKeys: ' || TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME) || ' - EXISTS');
--            ELSE
--                SetStatus('CaptureForeignKeys: ' || TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME) || ' - DOES NOT EXIST');
--            END IF;
            IF TABLEIDS.EXISTS(TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME)) AND
               TABLEIDS.EXISTS(TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME)) THEN
                tableId := TABLEIDS(TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME));
                refTableId := TABLEIDS(TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME));
--                SetStatus('CaptureForeignKeys: SRC/TGT Tables - ' || tableId || ', ' || refTableId);
                fKeyName := fKeyCol.CONSTRAINTNAME;
                IF ((currentTableId IS NULL) OR (currentTableId != tableId)) THEN
                    -- new table
--                    SetStatus('CaptureForeignKeys: New Table');
                    currentTableId := tableId;
                    currentReferenceIdx := NULL;
                END IF;
                IF ((currentReferenceIdx IS NULL) OR (currentReferenceIdx != fKeyCol.REFERENCEIDX)) THEN
                    -- new Foreign Key
--                    SetStatus('CaptureForeignKeys: New FKey');

                    fKeyId := MD_META.get_next_id;
                    currentReferenceIdx := fKeyCol.REFERENCEIDX;
                    IF (fKeyName IS NULL) THEN
                        fKeyName := TRIM(fKeyCol.TABLENAME) || 'FK' || uniqueId;
                        uniqueId := uniqueId + 1;
                    END IF;
                    INSERT
                        INTO MD_CONSTRAINTS (ID, NAME, CONSTRAINT_TYPE, TABLE_ID_FK, REFTABLE_ID_FK, "LANGUAGE")
                        VALUES (fKeyId, fKeyName , 'FOREIGN KEY', tableId, refTableId, 'TERADATALANG');
                        CONSTRAINTIDS(UPPER(fKeyName)) := fKeyId;
                END IF;
                seq := ((fKeyCol.COLUMNSEQ - 1) * 2) + 1;
                IF COLUMNIDS.EXISTS(TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME) || '.' || TRIM(fKeyCol.COLUMNNAME)) THEN
                    columnId := COLUMNIDS(TRIM(fKeyCol.TABLESCHEMA) || '.' || TRIM(fKeyCol.TABLENAME) || '.' || TRIM(fKeyCol.COLUMNNAME));
--                    SetStatus('CaptureForeignKeys: SEQ - ' || seq);
                    INSERT
                        INTO MD_CONSTRAINT_DETAILS(id, constraint_id_fk, column_id_fk, detail_order)
                        VALUES(fKeyCol.MDID1, fKeyId, columnId, seq);
                END IF;
                seq := seq + 1;
                IF COLUMNIDS.EXISTS(TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME) || '.' || TRIM(fKeyCol.REFCOLUMNNAME)) THEN
                    refColumnId := COLUMNIDS(TRIM(fKeyCol.REFTABLESCHEMA) || '.' || TRIM(fKeyCol.REFTABLENAME) || '.' || TRIM(fKeyCol.REFCOLUMNNAME));
--                    SetStatus('CaptureForeignKeys: SEQ - ' || seq);
                    INSERT
                        INTO MD_CONSTRAINT_DETAILS(id, constraint_id_fk, column_id_fk, detail_order, ref_flag)
                        VALUES(fKeyCol.MDID2, fKeyId, refColumnId, seq, 'Y');
                END IF;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception(CaptureForeignKeys):' || errMsg);
            RAISE;
    END CaptureForeignKeys;

    PROCEDURE CaptureChecks IS 
        errMsg VARCHAR2(4000);
        clbNativeSql CLOB := TO_CLOB(' ');
        tableId NUMBER;
        columnId NUMBER;
        chkUniqueId NUMBER;
        chkName VARCHAR2(512);
    BEGIN
        SetStatus('CaptureChecks');
        FOR chk IN
        (
            SELECT
                MDID,
                DATABASENAME,
                TABLENAME,
                CHECKNAME,
                CHECKTYPE,
                TABLECHECK,
                COLUMNNAME,
                CREATORNAME
            FROM
                STAGE_TERADATA_SHOWTBLCHECKS
        )
        LOOP
--            SetStatus('CaptureChecks: 1:');
            IF chk.COLUMNNAME IS NOT NULL THEN
                IF (TABLEIDS.EXISTS(TRIM(chk.DATABASENAME) || '.' || TRIM(chk.TABLENAME))) THEN
                    tableId := TABLEIDS(TRIM(chk.DATABASENAME) || '.' || TRIM(chk.TABLENAME));
                    columnId := COLUMNIDS(TRIM(chk.DATABASENAME) || '.' || TRIM(chk.TABLENAME) || '.' || TRIM(chk.COLUMNNAME));
                    IF (chk.CHECKNAME IS NULL) THEN
                        IF (CHECKIDS.EXISTS(chk.TABLECHECK)) THEN
                            chkUniqueId := CHECKIDS(chk.TABLECHECK);
                        ELSE
                            chkUniqueId := uniqueId;
                            uniqueId := uniqueId + 1;
                            CHECKIDS(chk.TABLECHECK) := chkUniqueId;
                        END IF;
                        chkName := chk.TABLENAME || '_C' || chkUniqueId;
                    ELSE
                        chkName := chk.CHECKNAME;
                    END IF;
                    INSERT
                        INTO MD_CONSTRAINTS (ID, NAME, CONSTRAINT_TYPE, TABLE_ID_FK, "LANGUAGE")
                        VALUES (chk.MDID, chkName, 'CHECK', tableId, 'TERADATALANG');
                    CONSTRAINTIDS(TRIM(chk.DATABASENAME) || '.' || TRIM(chk.TABLENAME) || '.' || TRIM(chkName)) := chk.MDID;
                    INSERT
                        INTO MD_ADDITIONAL_PROPERTIES(connection_id_fk, ref_id_fk, ref_type, property_order, prop_key, "VALUE")
                        VALUES(nSvrId, chk.MDID, 'MD_CONSTRAINTS', 1, 'TERADATA_CHECKCONSTRAINT', 'needconverting');
                    INSERT
                        INTO MD_CONSTRAINT_DETAILS(id, constraint_id_fk, column_id_fk, detail_order, constraint_text)
                        VALUES(MD_META.get_next_id, chk.mdid, columnId, 1, TO_CLOB(REGEXP_SUBSTR(chk.TABLECHECK, '\((.)*\)', 1, 1, 'i')));
                        -- SetStatus('CaptureChecks: ' || TRIM(chk.DATABASENAME) || '.' || TRIM(chk.TABLENAME) || '.' || TRIM(chkName) || ' - ' || CONSTRAINTIDS(TRIM(chk.DATABASENAME) || '.' || TRIM(chk.TABLENAME) || '.' || TRIM(chkName)));
                END IF;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception:' || errMsg);
            RAISE;
    END CaptureChecks;

    PROCEDURE CaptureConstraints IS
    BEGIN
        CapturePrimaryKeys;
        CaptureForeignKeys;
        CaptureChecks;
    END CaptureConstraints;

    PROCEDURE CaptureStoredPrograms IS
        errMsg VARCHAR2(4000);
        clbNativeSql CLOB := TO_CLOB(' ');
    BEGIN
        SetStatus('CaptureStoredPrograms');
        FOR proc IN
        (
            SELECT
                MDID,
                DATABASENAME,
                PROCNAME,
                PROCTYPE,
                REQUESTTEXT,
                COMMENTSTRING
            FROM STAGE_TERADATA_PROCEDURES
        )
        LOOP
            SetStatus('STORED PROGRAM:' || proc.DATABASENAME || '.' || proc.PROCNAME);
            IF (proc.PROCTYPE = 'E') THEN
                NULL;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception:' || errMsg);
            RAISE;
    END CaptureStoredPrograms;

    PROCEDURE CaptureTriggers IS
        errMsg VARCHAR2(4000);
        tableOrViewId NUMBER;
        tableOrView CHAR(1);
    BEGIN
        SetStatus('CaptureTriggers');
        FOR trig IN
        (
            SELECT
                MDID,
                DATABASENAME,
                SUBJECTTABLEDATABASENAME,
                TABLENAME,
                TRIGGERNAME,
                ENABLEDFLAG,
                EVENT,
                KIND,
                ORDERNUMBER,
                TRIGGERCOMMENT,
                REQUESTTEXT,
                CREATORNAME
            FROM
                STAGE_TERADATA_TRIGGERS
            ORDER BY
                SUBJECTTABLEDATABASENAME,
                TABLENAME,
                TRIGGERNAME
        )
        LOOP
            tableOrViewId := NULL;
            IF TABLEIDS.EXISTS(TRIM(trig.SUBJECTTABLEDATABASENAME) || '.' || TRIM(trig.TABLENAME)) THEN
                tableOrViewId := TABLEIDS(TRIM(trig.SUBJECTTABLEDATABASENAME) || '.' || TRIM(trig.TABLENAME));
                tableOrView := 'T';
            ELSE
                IF VIEWIDS.EXISTS(TRIM(trig.SUBJECTTABLEDATABASENAME) || '.' || TRIM(trig.TABLENAME)) THEN
                    tableOrViewId := VIEWIDS(TRIM(trig.SUBJECTTABLEDATABASENAME) || '.' || TRIM(trig.TABLENAME));
                    tableOrView := 'V';
                END IF;
            END IF;
            IF tableOrViewId IS NOT NULL THEN
                INSERT
                    INTO MD_TRIGGERS(id, table_or_view_id_fk, trigger_on_flag, trigger_name, comments, native_sql, "LANGUAGE")
                    VALUES(trig.MDID, tableOrViewId, tableOrView, trig.TRIGGERNAME, trig.TRIGGERCOMMENT, TO_CLOB(trig.REQUESTTEXT), 'TERADATALANG');
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception(CaptureTriggers):' || errMsg);
            RAISE;
    END CaptureTriggers;

    PROCEDURE CaptureUDT IS
        errMsg VARCHAR2(4000);
        typeId NUMBER;
        sysUDTLibId NUMBER;
        typeName VARCHAR2(270 CHAR);
        nativeSql CLOB := NULL;
        nativeSqlPiece VARCHAR2(4000);
        fieldCount NUMBER := 0;
    BEGIN
        SetStatus('CaptureUDT');
        typeId := NULL;
        typeName := NULL;
        IF NOT DATABASEIDS.EXISTS('SYSUDTLIB') THEN
            sysUDTLibId := MD_META.get_next_id;
            INSERT
                INTO md_schemas("ID", "CATALOG_ID_FK", "NAME")
                VALUES ( sysUDTLibId, nDummyCatalogId, 'SYSUDTLIB' );
            DATABASEIDS('SYSUDTLIB') := sysUDTLibId;
        ELSE
            sysUDTLibId := DATABASEIDS('SYSUDTLIB');
        END IF;
        FOR field IN
        (
            SELECT
                "MDID",
                "TYPEKIND",
                "TYPENAME",
                "FIELDNAME",
                "FIELDID",
                "FIELDTYPE",
                "UDTNAME",
                "CHARTYPE",
                "MAXLENGTH",
                "DECIMALTOTALDIGITS",
                "DECIMALFRACTIONALDIGITS",
                "INSTANTIABLE",
                "FINAL"
            FROM
                STAGE_TERADATA_UDTS
            ORDER BY
                TYPENAME,
                FIELDID
        )
        LOOP
            IF (typeName IS NULL OR typeName <> field.TYPENAME) THEN
                if (typeName IS NOT NULL) THEN
                    -- write out TYPE
                    DBMS_LOB.writeappend(nativeSql, 2, ') ');
                    IF (field.INSTANTIABLE = 'Y') THEN
                        DBMS_LOB.writeappend(nativeSql, 13, 'INSTANTIABLE ');
                    END IF;
                    IF (field.FINAL <> 'Y') THEN
                        DBMS_LOB.writeappend(nativeSql, 4, 'NOT ');
                    END IF;
                    DBMS_LOB.writeappend(nativeSql, 5, 'FINAL');
                    INSERT INTO MD_USER_DEFINED_DATA_TYPES
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
                    VALUES
                    (
                        sysUDTLibId,
                        typeName,
                        ' <UDT> ',
                        nativeSql,
                        '0',
                        NULL,
                        0,
                        SYSDATE,
                        NULL,
                        NULL,
                        NULL
                    );
                END IF;
                fieldCount := 0;
                typeName := field.TYPENAME;
                nativeSql := TO_CLOB('CREATE TYPE ' || typeName || ' AS ');
                typeId := field.MDID;
                IF (field.TYPEKIND = 'S') THEN
                    DBMS_LOB.writeappend(nativeSql, 2, '( ');
                END IF;
            END IF;
            fieldCount := fieldCount + 1;
            IF (field.TYPEKIND = 'D') THEN
                nativeSqlPiece := getTypeName(field.FIELDTYPE, field.CHARTYPE, field.UDTNAME) || ' ';
            END IF;
            IF (field.TYPEKIND = 'S') THEN
                nativeSqlPiece := field.FIELDNAME || ' ' || getTypeName(field.FIELDTYPE, field.CHARTYPE, field.UDTNAME) || ' ';
                IF (fieldCount > 1) THEN
                    nativeSqlPiece := ', ' || nativeSqlPiece;
                END IF;
            END IF;
            DBMS_LOB.writeappend(nativeSql, LENGTH(nativeSqlPiece), nativeSqlPiece);
            IF (field.TYPEKIND = 'D') THEN
                IF (field.INSTANTIABLE = 'Y') THEN
                    DBMS_LOB.writeappend(nativeSql, 13, 'INSTANTIABLE ');
                END IF;
                IF (field.FINAL <> 'Y') THEN
                    DBMS_LOB.writeappend(nativeSql, 4, 'NOT ');
                END IF;
                DBMS_LOB.writeappend(nativeSql, 5, 'FINAL');
                INSERT INTO MD_USER_DEFINED_DATA_TYPES
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
                VALUES
                (
                    sysUDTLibId,
                    typeName,
                    ' ',
                    nativeSql,
                    '0',
                    NULL,
                    0,
                    SYSDATE,
                    NULL,
                    NULL,
                    NULL
                );
                typeName := NULL;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            DBMS_OUTPUT.put_line('Exception(CaptureUDT):' || errMsg);
            RAISE;
    END CaptureUDT;

    PROCEDURE CapturePartitionInfo IS
        errMsg VARCHAR2(4000);
        tableId NUMBER;
    BEGIN
        SetStatus('CapturePartitionInfo');
        FOR partExp IN
        (
            SELECT
                MDID,
                DATABASENAME,
                TABLENAME,
                IndexName,
                IndexNumber,
                CONSTRAINTTYPE,
                CONSTRAINTTEXT
            FROM
                STAGE_TERADATA_IDXCONSTRAINTS
        )
        LOOP
            IF (partExp.CONSTRAINTTYPE = 'Q') THEN
                IF TABLEIDS.EXISTS(TRIM(partExp.DATABASENAME) || '.' || TRIM(partExp.TABLENAME)) THEN
                    tableId := TABLEIDS(TRIM(partExp.DATABASENAME) || '.' || TRIM(partExp.TABLENAME));
                    INSERT
                        INTO md_partitions
                        (
                            id,
                            table_id_fk,
                            native_sql
                        )
                        VALUES
                        (
                            partExp.MDID,
                            tableId,
                            partExp.CONSTRAINTTEXT
                        );
                END IF;
            END IF;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --DBMS_OUTPUT.put_line('Exception:' || errMsg);
            RAISE;
    END CapturePartitionInfo;

   PROCEDURE CaptureEntireStage IS
    BEGIN
        CaptureConnections;
        COMMIT;
        CaptureDatabases;
        COMMIT;
        CaptureSchemas;
        COMMIT;
        CaptureTablesAndViews;
        COMMIT;
        CaptureColumns;
        COMMIT;
        CaptureConstraints;
        COMMIT;
        CaptureIndexes;
        COMMIT;
        CaptureStoredPrograms;
        COMMIT;
        CaptureTriggers;
        COMMIT;
        CaptureUDT;
        COMMIT;
        CapturePartitionInfo;
        COMMIT;
    END CaptureEntireStage;

    PROCEDURE RegisterPlugin IS
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
            pluginClass
        );
        COMMIT;
    END;

    PROCEDURE initialise IS
    BEGIN
        DATABASEIDS.DELETE;
        TABLEIDS.DELETE;
        VIEWIDS.DELETE;
        COLUMNIDS.DELETE;
        CONSTRAINTIDS.DELETE;
        PKEYIDS.DELETE;
        CHECKIDS.DELETE;
        UDTNAMEMAP.DELETE;
        PKEYNAMEMAP.DELETE;
        logLine := 1;
        uniqueId := 1;
        registerUDTs;
    END INITIALISE;

    FUNCTION StageCapture(p_projectId NUMBER,
                          p_pluginClassIn varchar2,
                          p_jExists BOOLEAN := FALSE,
                          p_scratchModel BOOLEAN := FALSE) RETURN VARCHAR2 IS
        ret_val NAME_AND_COUNT_ARRAY;
        scratchConnId NUMBER :=0;
        connectionStatsResult NUMBER;
        errmsg VARCHAR(4000);
    BEGIN
        delete from STAGE_TERADATA_LOG;
        -- initialise globals
        initialise;
        -- save parameters
        nProjectId := p_projectId;
        projectExist := p_jExists;
        pluginClass := p_pluginClassIn;
        -- NOTE that nSvrId is the capture connection id (with a really bad name)
        SELECT svrid into nSvrId FROM STAGE_SERVERDETAIL WHERE project_id = nProjectId;

        -- Initialize the log status table
        INSERT INTO
            migrlog(parent_log_id, log_date, severity, logtext, phase, ref_object_id, ref_object_type, connection_id_fk) 
            VALUES (NULL, systimestamp, 666, 'Capture Started', 'CAPTURE', NULL, NULL, p_projectId);
        COMMIT;          

        SetStatus('Capture processing started');          

        --DisableRepositoryTriggers;      
        SetStatus('Disabled Triggers');
        CaptureEntireStage;
        SetStatus('CapturedEntireStage completed');
        COMMIT;
        RegisterPlugin;
        --EnableRepositoryTriggers;
        MIGRATION.POPULATE_DERIVATIVES_TABLE(nSvrId); --new identifier mapping setup
        COMMIT;      
        SetStatus('Finished');          

        RETURN '' || nSvrId || '/' || scratchConnId;
    EXCEPTION
        WHEN OTHERS THEN
            errMsg := SQLERRM;
            --DBMS_OUTPUT.put_line('Exception:' || errMsg);
            SetStatus('Ex:' || errMsg);          
            --EnableRepositoryTriggers;
            RAISE;
    END StageCapture;

    PROCEDURE SetStatus(msg VARCHAR2, sev NUMBER := 666) IS
    BEGIN
        --dbms_output.put_line(msg);
        --commit;
        --progressStatus := msg;
        --dbms_lock.sleep(2);
        --insert into STAGE_TERADATA_LOG (LINE, LOGSTRING) VALUES (logLine, msg);
        logLine := logLine + 1;
        UPDATE migrlog SET logtext = msg,
            log_date = systimestamp
        WHERE
            severity = 666 
            AND phase = 'CAPTURE'
            AND connection_id_fk = nProjectId;                   
        COMMIT;
    END SetStatus;  

    FUNCTION GetStatus(iid INTEGER) RETURN varchar2 IS
        status VARCHAR2(4000);
        errMsg VARCHAR2(2000);
    BEGIN
        SELECT logtext INTO status FROM migrlog WHERE severity = 666 AND phase = 'CAPTURE' AND connection_id_fk = iid;    
        RETURN status; 
    EXCEPTION 
        WHEN OTHERS THEN
            errMsg := SQLERRM;  
            --dbms_output.put_line('Status Message : ' || errMsg);
    END GetStatus;
END TDALLPLATFORM;
/