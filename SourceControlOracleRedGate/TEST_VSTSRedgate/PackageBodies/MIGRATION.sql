CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."MIGRATION" AS
/**
 * The migration package contains all of the PL/SQL Procedures and functions required by the migration
 * system.
 * @author Barry McGillin
 * @author Dermot Daly.
 */
--a.id schema_id, A.name schema_name, b.id catalog_id, B.CATALOG_NAME, 
--B.DUMMY_FLAG, A.type, A.character_set, A.version_tag 
TYPE DERIVATIVE_REC IS RECORD (
     schema_id          NUMBER,
     schema_name        VARCHAR2(4000 BYTE),
     catalog_id         NUMBER,
     catalog_name       VARCHAR2(4000 BYTE),
     dummy_flag         CHAR(1 BYTE),
     cap_type           CHAR(1 BYTE),    
     character_set      VARCHAR2(4000 BYTE),
     version_tag        VARCHAR2(40 BYTE)
     ); 

TYPE DERIVATIVE_REC2 IS RECORD (
     schemaid  NUMBER, 
     newid     NUMBER
);     

v_prefixName VARCHAR2(4) :=''; --text to prefix objects with ,set using transform_all_identifiers
-- Constants that are used throughout the package body.
C_CONNECTIONTYPE_CONVERTED   CONSTANT MD_CONNECTIONS.TYPE%TYPE := 'CONVERTED';
C_CONNECTIONTYPE_SCRATCH   CONSTANT MD_CONNECTIONS.TYPE%TYPE := 'SCRATCH'; -- enterprise capture/convert
-- Supported object types.
C_OBJECTTYPE_CONNECTIONS     CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_CONNECTIONS';
C_OBJECTTYPE_CATALOGS        CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_CATALOGS';
C_OBJECTTYPE_SCHEMAS         CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_SCHEMAS';
C_OBJECTTYPE_TABLES          CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_TABLES';
C_OBJECTTYPE_COLUMNS         CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_COLUMNS';
C_OBJECTTYPE_CNSTRNT_DETAILS CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_CONSTRAINT_DETAILS';
C_OBJECTTYPE_CONSTRAINTS     CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_CONSTRAINTS';
C_OBJECTTYPE_INDEX_DETAILS   CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_INDEX_DETAILS';
C_OBJECTTYPE_INDEXES         CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_INDEXES';
C_OBJECTTYPE_TRIGGERS        CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_TRIGGERS';
C_OBJECTTYPE_VIEWS           CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_VIEWS';
C_OBJECTTYPE_USERS           CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_USERS';
C_OBJECTTYPE_GROUP_MEMBERS   CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_GROUPMEMBERS';
C_OBJECTTYPE_GROUPS          CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_GROUPS';
C_OBJECTTYPE_OTHER_OBJECTS   CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_OTHER_OBJECTS';
C_OBJECTTYPE_TABLESPACES     CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_TABLESPACES';
C_OBJECTTYPE_UDDT            CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_USER_DEFINED_DATA_TYPES';
C_OBJECTTYPE_STORED_PROGRAMS CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_STORED_PROGRAMS';
C_OBJECTTYPE_PACKAGES        CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_PACKAGES';
C_OBJECTTYPE_SYNONYMS        CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_SYNONYMS';
C_OBJECTTYPE_SEQUENCES       CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_SEQUENCES';
C_OBJECTTYPE_PRIVILEGES      CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_PRIVILEGES';
C_OBJECTTYPE_USER_PRIVILEGES CONSTANT MD_DERIVATIVES.SRC_TYPE%TYPE := 'MD_USER_PRIVILEGES';
-- Dummy flag for a dummy catalog.
C_DUMMYFLAG_TRUE             CONSTANT MD_CATALOGS.DUMMY_FLAG%TYPE := 'Y';
-- Flag in MD_DERIVATIVES to show if something has been transformed
C_TRANSFORMED_TRUE           CONSTANT MD_DERIVATIVES.TRANSFORMED%TYPE := 'Y';
-- Flag in MD_SYNONYMS.PRIVATE_VISIBILITY to highlight that a synonym is marked as private
C_SYNONYM_PRIVATE            CONSTANT MD_SYNONYMS.PRIVATE_VISIBILITY%TYPE := 'Y';
-- Flag in MD_GROUPS.GROUP_FLAG to show this is a role
C_ROLE_FLAG                  CONSTANT MD_GROUPS.GROUP_FLAG%TYPE := 'R';
-- Flag in MD_COLUMNS TO SHOW A COLUMN IS NULLABLE
C_NULLABLE_YES               CONSTANT MD_COLUMNS.NULLABLE%TYPE := 'Y';
-- Special defined additional properties.
C_PROPKEY_SEEDVALUE          CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'SEEDVALUE';
C_PROPKEY_INCREMENT          CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'INCREMENT';
C_PROPKEY_LASTVALUE          CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'LASTVALUE';
C_PROPKEY_EXTENDEDINDEXTYPE	 CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'EXTENDEDINDEXTYPE';
C_PROPKEY_SEQUENCEID	       CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'SEQUENCEID';
C_PROPKEY_TRIGGER_REWRITE	   CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'TRIGGER_REWRITE';
C_PROPKEY_REAL_IDENTITY      CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'REALIDENTITY';
C_PROPKEY_ALREADY_IDENTITY   CONSTANT MD_ADDITIONAL_PROPERTIES.PROP_KEY%TYPE := 'ALREADYIDENTITY';
-- Name spaces for identifiers
C_NS_SCHEMA_OBJS             CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_SCHEMAOBJS';
C_NS_INDEXES                 CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_INDEXES';
C_NS_CONSTRAINTS             CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_CONSTRAINTS';
C_NS_CLUSTERS                CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_CLUSTERS';
C_NS_DB_TRIGGERS             CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_DB_TRIGGERS';
C_NS_PRIVATE_DBLINKS         CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_PRIVATEDBLINKS';
C_NS_DIMENSIONS              CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_DIMENSIONS';
C_NS_USER_ROLES              CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_USERROLES';
C_NS_PUBLIC_SYNONYMS         CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_PUB_SYNONYMS';
C_NS_PUBLIC_DBLINKS          CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_PUBLICDBLINKS';
C_NS_TABLESPACES             CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_TABLESPACES';
C_NS_PROFILES                CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_PROFILES';
C_NS_DATABASE                CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_DATABASE';
C_NS_USERS                   CONSTANT MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := 'NS_USERS';
-- Constants for Filter Types
 -- Filter Types are 0-> ALL, 1->NAMELIST, 2->WHERE CLAUSE, 3->OBJECTID LIST
C_FILTERTYPE_ALL	     CONSTANT INTEGER := 0;
C_FILTERTYPE_NAMELIST	     CONSTANT INTEGER := 1;
C_FILTERTYPE_WHERECLAUSE     CONSTANT INTEGER := 2;
C_FILTERTYPE_OBJECTIDLIST    CONSTANT INTEGER := 3;
-- Constatns for TEXT INDEX TYPES
-- see http://download-west.oracle.com/docs/cd/B10501_01/text.920/a96518/csql.htm#19446
-- Use this index type when there is one CLOB or BLOB column in the index only
C_INDEXTYPE_CONTEXT	CONSTANT MD_ADDITIONAL_PROPERTIES.VALUE%TYPE := 'ctxsys.context';
-- Use this index type when the index containst a CLOB or BLOB column.
C_INDEXTYPE_CTXCAT CONSTANT  MD_ADDITIONAL_PROPERTIES.VALUE%TYPE := 'ctxsys.ctxcat';
-- Constant for LANGUAGE - Used in MD_TRIGGERS, MD_PACKAGES, MD_STORED_PROGRAMS, MD_VIEWS, and MD_CONSTRAINTS
C_LANGUAGEID_ORACLE CONSTANT MD_TRIGGERS.LANGUAGE%TYPE := 'OracleSQL';
-- Type for a generic REF CURSOR
TYPE REF_CURSOR IS REF CURSOR;
/**
 * Find a filter element from a filter list
 */
FUNCTION find_filter_for_type(p_filterSet MIGR_FILTER_SET, p_objtype MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE) RETURN MIGR_FILTER
IS
BEGIN
  IF p_filterset is NULL OR p_objtype is NULL then
    return NULL;
  END IF;
  FOR indx in p_filterset.FIRST .. p_filterset.LAST
  LOOP
    if p_filterset(indx).OBJTYPE = p_objtype THEN
      return p_filterset(indx);
    end if;
  END LOOP;
  return NULL;
END find_filter_for_type;

/**
 * Convert a name list from a filter into a condition for use in a where clause.
 * @param p_nameList the set of names that form part of the filter
 * @param p_nameField the name of the field to be compared against.
 * @return A condition that can be used in a where clause.
 */
FUNCTION namelist_to_where_clause(p_nameList NAMELIST, p_nameField VARCHAR2) RETURN VARCHAR2
IS
  v_ret VARCHAR2(4000);
BEGIN
  v_ret := p_nameField || ' IN (';
  FOR indx IN p_nameList.FIRST .. p_nameList.LAST
  LOOP
    v_ret := v_ret || '''' || p_nameList(indx) || '''';
    IF  indx != p_nameList.LAST THEN
      v_ret := v_ret || ', ';
    END IF;
  END LOOP;
  v_ret := v_ret || ')';
  return v_ret;
END namelist_to_where_clause;

/**
 * Convert an object id list from a filter into a condition for use in a where clause.
 * @param p_oidList The list of object ids taken from the filter.
 * @param p_idFIeld The field to be tested against.
 * @return A condition that can be used in a where clause.
 */
FUNCTION objectIdList_to_where_clause(p_oidList OBJECTIDLIST, p_idField VARCHAR2) RETURN VARCHAR2
IS
  v_ret VARCHAR2(4000);
BEGIN
  V_RET := p_idField || ' IN (';
  FOR indx IN p_oidList.FIRST .. p_oidList.LAST
  LOOP
    v_ret := v_ret || TO_CHAR(p_oidList(indx));
    IF indx != p_oidList.LAST THEN
      v_ret := v_ret || ', ';
    END IF;
  END LOOP;
  v_ret := v_ret || ')';
  return v_ret;
END objectIdList_to_where_clause;

/**
 * Convert a filter to a condition for use in a where clause.
 * @param p_filter The filter
 * @param p_nameFileld The name field that will be used in the names list or where clause.
 * @param p_idField The id field that will be used if the filter is an objectid list.
 * @return A condition that could be used in a where clause.  NULL if no additional filtering is required.
 */
FUNCTION where_clause_from_filter(p_filter MIGR_FILTER, p_nameField VARCHAR2, p_idField VARCHAR2) RETURN VARCHAR2
IS
BEGIN
	IF p_filter.FILTER_TYPE = C_FILTERTYPE_ALL THEN
	  RETURN NULL;
    ELSIF p_filter.FILTER_TYPE = C_FILTERTYPE_NAMELIST THEN
      RETURN namelist_to_where_clause(p_filter.NAMES, p_nameField);
    ELSIF p_filter.FILTER_TYPE = C_FILTERTYPE_WHERECLAUSE THEN
	  RETURN p_nameField || ' ' || p_filter.WHERECLAUSE;
    ELSE
	  RETURN objectidlist_to_where_clause(p_filter.OBJECTIDS, p_idField);
	END IF;
END where_clause_from_filter;

/**
 * Apply a filter to an existing select statement
 * @param p_filter_set The filter set.
 * @param p_filter_type The type of the object, for finding in the filter set.
 * @param p_name_field The name field of the table being filtered
 * @param p_id_field The id field of the table being filtered.
 * @param p_select_stmt The select statment to tag the new condition on to
 * @return The select statement with the new condition added to it (or the original statement if
 *         there is no applicable filter for this object type.
 */
FUNCTION apply_filter(p_filter_set MIGR_FILTER_SET,
                      p_filter_type MD_DERIVATIVES.SRC_TYPE%TYPE,
                      p_name_field VARCHAR2,
                      p_id_field VARCHAR2,
                      p_select_stmt VARCHAR2) RETURN VARCHAR2
IS
  v_filt MIGR_FILTER;
  v_condition VARCHAR2(4000);
BEGIN
  v_filt := find_filter_for_type(p_filter_set, p_filter_type);
  --if the filter is null, then we need to set a value that will fail always so nothing is moved.
  -- ie 1=2
  IF v_filt IS NOT NULL THEN
    v_condition := where_clause_from_filter(v_filt, p_name_field, p_id_field);
    IF v_condition IS NOT NULL THEN
      RETURN p_select_stmt || ' AND ' || v_condition;
    ELSE
     RETURN p_select_stmt;
    END IF;
  END IF;
  RETURN p_select_stmt ;
END apply_filter;


/**
 * Find the copy of a particular object.  This function checks for a copied object of a particular
 * type by searching the MD_DERIVATIVES table.
 * @param p_objectid The id of the object to search for.
 * @param p_objecttype The type of the object to search for.
 * @return the id of the copy object if it is present, or NULL if it is not.
 */
FUNCTION find_object_copy(p_objectid md_projects.id%TYPE, p_objecttype MD_DERIVATIVES.SRC_TYPE%TYPE, p_derivedconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS 
  v_ret MD_DERIVATIVES.DERIVED_ID%TYPE;
BEGIN
  SELECT /* APEX53913a */  derived_id INTO v_ret FROM MD_DERIVATIVES
    WHERE src_id = p_objectid 
     AND src_type = p_objecttype
     AND derived_type = p_objecttype 
     AND derived_connection_id_fk = p_derivedconnectionid;
  RETURN v_ret;
EXCEPTION
  WHEN NO_DATA_FOUND then
    -- Should we raise an error?
    RETURN NULL;
END find_object_copy;

/**
 * Copy additional properties. function copies the additional properties for an object.
 * @param p_refobjectid The object id whose additional properties have to be copied
 * @param p_newrefobject The id of the copied object the new properties should refer to
 * @return number of additional properties copied
 */
FUNCTION copy_additional_properties(p_refobjectid MD_ADDITIONAL_PROPERTIES.REF_ID_FK%TYPE, p_newrefobject MD_PROJECTS.ID%TYPE, p_newconnectionid MD_ADDITIONAL_PROPERTIES.CONNECTION_ID_FK%TYPE) RETURN NUMBER
IS
  CURSOR ORIGINAL_RECS IS SELECT PROPERTY_ORDER, PROP_KEY, REF_TYPE, VALUE FROM MD_ADDITIONAL_PROPERTIES WHERE REF_ID_FK=p_refobjectid;
  v_numcopied NUMBER := 0;
BEGIN
  for newrec in ORIGINAL_RECS LOOP
    INSERT INTO MD_ADDITIONAL_PROPERTIES (ref_id_fk, ref_type, property_order, prop_key, value, connection_id_fk)
      VALUES (p_newrefobject, newrec.ref_type, newrec.property_order, newrec.prop_key, newrec.value, p_newconnectionid);
    v_numcopied := v_numcopied + 1;
  END LOOP;
  commit;
  return v_numcopied;
END copy_additional_properties;

FUNCTION copy_connection(p_connectionid MD_CONNECTIONS.ID%TYPE, p_scratchModel BOOLEAN := FALSE) RETURN NUMBER
IS
  newrec MD_CONNECTIONS%ROWTYPE;
  newid MD_CONNECTIONS.ID%TYPE;
  origName MD_CONNECTIONS.NAME%TYPE;
BEGIN
  SELECT /* APEX1930d7 */  * INTO newrec from MD_CONNECTIONS WHERE id = p_connectionid;

  newrec.HOST := NULL;
  newrec.PORT := NULL;
  newrec.USERNAME := NULL;
  newrec.DBURL := NULL;
  -- TODO.  Need to do this in a more i18n friendly manner.
  origName := newrec.NAME;

  IF p_scratchModel = FALSE 
  THEN
     newrec.TYPE :=C_CONNECTIONTYPE_CONVERTED;  
     newrec.NAME := 'Converted:' || newrec.NAME;
  ELSE
     newrec.TYPE :=C_CONNECTIONTYPE_SCRATCH;  
     newrec.NAME := 'Scratch:' || newrec.NAME;     
  END IF;
  -- Let the trigger create the new ID
  newrec.ID := NULL;
  INSERT /* APEX5e30c0 */  INTO MD_CONNECTIONS VALUES newrec
  	RETURNING id into newid;
  INSERT /* APEXc1acd0 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, derived_connection_id_fk, original_identifier, new_identifier)
    VALUES (p_connectionid, C_OBJECTTYPE_CONNECTIONS, newid, C_OBJECTTYPE_CONNECTIONS, newid, origName, newrec.NAME);
  commit;
  return newid;
END copy_connection;


FUNCTION create_dummy_catalog(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  newid MD_CATALOGS.ID%TYPE;
BEGIN
  INSERT /* APEXa33eb5 */  INTO MD_CATALOGS (CONNECTION_ID_FK, CATALOG_NAME, DUMMY_FLAG, NATIVE_SQL, NATIVE_KEY)
  VALUES (p_connectionid, ' ', C_DUMMYFLAG_TRUE, NULL, NULL)
  RETURNING ID INTO newid;
  RETURN newid;
END create_dummy_catalog;

FUNCTION find_or_create_dummy_catalog(p_connectionid MD_CONNECTIONS.ID%TYPE, p_catalogid MD_CATALOGS.ID%TYPE) RETURN NUMBER
IS
  newrec MD_CATALOGS%ROWTYPE;
  newid MD_CATALOGS.ID%TYPE;
BEGIN
  SELECT /* APEX6fc7e7 */  * INTO newrec from MD_CATALOGS where connection_id_fk = p_connectionid and "ID" = p_catalogid;
  return newrec.id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  INSERT /* APEX5171b3 */  INTO MD_CATALOGS (CONNECTION_ID_FK, CATALOG_NAME, DUMMY_FLAG, NATIVE_SQL, NATIVE_KEY)
  VALUES (p_connectionid, ' ', C_DUMMYFLAG_TRUE, NULL, NULL)
  RETURNING ID INTO newid;
  INSERT /* APEXd6ad63 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, derived_connection_id_fk, DERIVED_OBJECT_NAMESPACE)
    VALUES (p_catalogid, C_OBJECTTYPE_CATALOGS, newid, C_OBJECTTYPE_CATALOGS, p_connectionid, C_NS_DATABASE);
  commit;
  return newid;
END find_or_create_dummy_catalog;

-- Enterprise convert may have 1 catalog belonging to a given connection id
PROCEDURE create_dummy_catalogs(p_connectionid MD_CONNECTIONS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_scratchModel BOOLEAN) 
IS
  CURSOR curcats(connId MD_CONNECTIONS.ID%TYPE) IS select * from MD_CATALOGS where connection_id_fk = connId;
  cat_row MD_CATALOGS%ROWTYPE;
  newid MD_CATALOGS."ID"%TYPE;
  v_sql VARCHAR2(300);
BEGIN
   OPEN curcats(p_connectionid);
   FETCH curcats INTO cat_row;  
   LOOP
     EXIT WHEN curcats%NOTFOUND;
     newid := find_or_create_dummy_catalog(p_newconnectionid, cat_row."ID");
     v_sql := 'UPDATE MD_CATALOGS SET CATALOG_NAME = ''' || cat_row."CATALOG_NAME"  || ''' WHERE ID = ' || TO_CHAR(newid);
     EXECUTE IMMEDIATE v_sql;
     FETCH curcats INTO cat_row;  
   END LOOP;
  CLOSE curcats; 
  COMMIT;
END create_dummy_catalogs;


FUNCTION copy_individual_catalog(p_catalogid MD_CATALOGS.ID%TYPE) RETURN NUMBER
IS
  newrec MD_CATALOGS%ROWTYPE;
  newconnectionid MD_CATALOGS.CONNECTION_ID_FK%TYPE;
  dummycatalogid MD_CATALOGS.ID%TYPE;
  originalconnectionid MD_CATALOGS.CONNECTION_ID_FK%TYPE;
BEGIN
  -- Catalogs aren't copied as such. Instead, we make a single DUMMY catalog
  -- Within the new connection
  -- So..first see if one exists for the copied connection
  SELECT /* APEX4a8b0f */  CONNECTION_ID_FK INTO originalconnectionid FROM MD_CATALOGS WHERE ID = p_catalogid;
  -- For connections, we have a special case.  We can't store the new connection, but 0 is ok.
  newconnectionid := find_object_copy(originalconnectionid, C_OBJECTTYPE_CONNECTIONS, 0);
  IF newconnectionid IS NULL THEN
    newconnectionid := copy_connection(originalconnectionid);
  END IF;
  dummycatalogid := find_or_create_dummy_catalog(newconnectionid, p_catalogid);
  RETURN dummycatalogid;  
END copy_individual_catalog;

FUNCTION copy_individual_schema(p_schemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  newid MD_SCHEMAS.ID%TYPE;
  newrec MD_SCHEMAS%ROWTYPE;
  newcatalogid MD_CATALOGS.ID%TYPE;
  originalcatalogname MD_CATALOGS.CATALOG_NAME%TYPE;
  originalcatalogid MD_SCHEMAS.CATALOG_ID_FK%TYPE;
  originalschemaname MD_SCHEMAS.NAME%TYPE;
  originalisdummy CHAR;
BEGIN
  SELECT /* APEXdeeaa8 */  * INTO newrec FROM md_schemas WHERE id = p_schemaid;
  newcatalogid := find_object_copy(newrec.catalog_id_fk,   C_OBJECTTYPE_CATALOGS, p_newconnectionid);
  originalcatalogid := newrec.catalog_id_fk;
  originalschemaname := newrec.NAME;
  select /* APEX8764f4 */  CATALOG_NAME, DUMMY_FLAG into originalcatalogname, originalisdummy from MD_CATALOGS WHERE ID = originalcatalogid;
  IF newcatalogid IS NULL THEN
    newcatalogid := copy_individual_catalog(newrec.catalog_id_fk);
  END IF;

  newrec.catalog_id_fk := newcatalogid;
  if originalisdummy <> C_DUMMYFLAG_TRUE THEN
    newrec.name := originalcatalogname || '_' || newrec.name;
  end if;
  -- Let the trigger work out the new id
  newrec.ID := NULL;
  INSERT /* APEXb791c3 */  INTO MD_SCHEMAS VALUES newrec RETURNING ID INTO newid;
  INSERT /* APEX934add */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, original_identifier, new_identifier, DERIVED_OBJECT_NAMESPACE)
    VALUES (p_schemaid, C_OBJECTTYPE_SCHEMAS, newid, C_OBJECTTYPE_SCHEMAS, originalschemaname, newrec.name, C_NS_DATABASE);
  INSERT /* APEX5a0913 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type)
    VALUES (originalcatalogid, C_OBJECTTYPE_CATALOGS, newid, C_OBJECTTYPE_SCHEMAS);
  COMMIT;
  return newid;
END copy_individual_schema;

FUNCTION copy_individual_table(p_tableid MD_TABLES.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  newrec MD_TABLES%rowtype;
  newid MD_TABLES.ID%TYPE;
  newschemaid MD_SCHEMAS.ID%TYPE;
BEGIN
  SELECT /* APEX674369 */  * INTO newrec FROM MD_tables WHERE id = p_tableid;
  newschemaid := find_object_copy(newrec.schema_id_fk,   C_OBJECTTYPE_SCHEMAS, p_newconnectionid);
  IF newschemaid IS NULL THEN
    newschemaid := copy_individual_schema(newrec.schema_id_fk, p_newconnectionid);
  END IF;

  newrec.schema_id_fk := newschemaid;
  -- Let the trigger work out the new id
  newrec.ID := NULL;
  INSERT /* APEXc18abc */  INTO MD_TABLES VALUES newrec RETURNING ID INTO newid;
  INSERT /* APEX21ce7a */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, derived_connection_id_fk, original_identifier, new_identifier, DERIVED_OBJECT_NAMESPACE)
    VALUES(p_tableid,   C_OBJECTTYPE_TABLES,   newid,   C_OBJECTTYPE_TABLES, p_newconnectionid, newrec.table_name, newrec.table_name, C_NS_SCHEMA_OBJS || TO_CHAR(newschemaid));
  COMMIT;
  RETURN newid;
END copy_individual_table;

FUNCTION copy_individual_column(p_columnid MD_COLUMNS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  newid MD_COLUMNS.ID%TYPE;
  newrec MD_COLUMNS%rowtype;
  newtableid MD_TABLES.ID%TYPE;
BEGIN
  SELECT /* APEX55d38b */  * INTO newrec FROM md_columns WHERE id = p_columnid;
  -- TODO: How do I check if this worked?
  -- OK. We need to fix up table id
  newtableid := find_object_copy(newrec.table_id_fk,   C_OBJECTTYPE_TABLES, p_newconnectionid);

  IF newtableid IS NULL THEN
    newtableid := copy_individual_table(newrec.table_id_fk, p_newconnectionid);
  END IF;

  newrec.table_id_fk := newtableid;
  -- Let the trigger work out the new id
  newrec.ID := NULL;
  INSERT /* APEX39b0de */  INTO md_columns VALUES newrec RETURNING ID INTO newid;
  -- Columns have their own namespace.  They must be unique within the given table.  So..we'll use the table id as the namespace
  INSERT /* APEXb60765 */  INTO md_derivatives(src_id,   src_type,   derived_id,   derived_type, derived_connection_id_fk, original_identifier, new_identifier, DERIVED_OBJECT_NAMESPACE)
    VALUES(p_columnid,   C_OBJECTTYPE_COLUMNS,   newid,   C_OBJECTTYPE_COLUMNS, p_newconnectionid, newrec.column_name, newrec.column_name, C_OBJECTTYPE_COLUMNS || TO_CHAR(newtableid));
  COMMIT;
  RETURN newid;
END copy_individual_column;

FUNCTION copy_all_tables(p_connectionid MD_CONNECTIONS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR all_tables_cursor is select table_id from mgv_all_tables where connection_id = p_connectionid;
  v_count NUMBER := 0;
  newid MD_TABLES.ID%TYPE;
BEGIN
  FOR v_tableid IN all_tables_cursor LOOP
    newid := copy_individual_table(v_tableid.table_id, p_newconnectionid);
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END copy_all_tables;

FUNCTION copy_all_columns(p_connectionid MD_CONNECTIONS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR all_columns_cursor is select id from MD_COLUMNS where table_id_fk in 
    (select table_id from MGV_ALL_TABLES where connection_id = p_connectionid);
  v_count NUMBER :=0;
  newid MD_COLUMNS.ID%TYPE;
BEGIN
  FOR v_columnid IN all_columns_cursor LOOP
    newid := copy_individual_column(v_columnid.id, p_newconnectionid);
    v_count := v_count + 1;
  END LOOP;
  return v_count;
END copy_all_columns;

FUNCTION copy_constraint_details(p_oldconsid MD_CONSTRAINTS.ID%TYPE, p_newconsid MD_CONSTRAINTS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR curs is SELECT * FROM MD_CONSTRAINT_DETAILS WHERE CONSTRAINT_ID_FK = p_oldconsid;
  v_newid MD_CONSTRAINT_DETAILS.ID%TYPE;
  v_count NUMBER := 0;
  v_originalid MD_CONSTRAINT_DETAILS.ID%TYPE;
  v_ret NUMBER;
BEGIN
  FOR v_row IN curs LOOP
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.COLUMN_ID_FK := find_object_copy(v_row.COLUMN_ID_FK , C_OBJECTTYPE_COLUMNS, p_newconnectionid);
    v_row.CONSTRAINT_ID_FK := p_newconsid;
    INSERT INTO MD_CONSTRAINT_DETAILS values v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- Constraint details don't have an identifier, so don't need a namespace.
    INSERT INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK)
      VALUES(v_originalid, C_OBJECTTYPE_CNSTRNT_DETAILS, v_newid, C_OBJECTTYPE_CNSTRNT_DETAILS, p_newconnectionid);
  END LOOP;
  return v_count;
END copy_constraint_details;

FUNCTION copy_all_constraints_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
   v_selectStmt VARCHAR2(4000) :=     
  'SELECT * FROM MD_CONSTRAINTS WHERE TABLE_ID_FK IN       
    (SELECT SRC_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = ''' || C_OBJECTTYPE_TABLES ||''' AND DERIVED_TYPE = '''
    || C_OBJECTTYPE_TABLES || ''' AND DERIVED_ID IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE SCHEMA_ID = ' || p_newschemaid || '))';
  v_count NUMBER := 0;
  v_newid MD_CONSTRAINTS.ID%TYPE;
  v_originalid MD_CONSTRAINTS.ID%TYPE;
  v_ret NUMBER;
  v_row MD_CONSTRAINTS%ROWTYPE;
  v_storeRefTableId MD_TABLES.ID%TYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_CONSTRAINTS, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.TABLE_ID_FK := find_object_copy(v_row.TABLE_ID_FK , C_OBJECTTYPE_TABLES, p_newconnectionid);
    if v_row.REFTABLE_ID_FK IS NOT NULL THEN
      v_storeRefTableId := v_row.REFTABLE_ID_FK;
      v_row.REFTABLE_ID_FK := find_object_copy(v_row.REFTABLE_ID_FK , C_OBJECTTYPE_TABLES, p_newconnectionid);
    END IF;
    INSERT /* APEX47e80e */  INTO MD_CONSTRAINTS values v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX980c66 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid, C_OBJECTTYPE_CONSTRAINTS, v_newid, C_OBJECTTYPE_CONSTRAINTS, p_newconnectionid, v_row.NAME, v_row.NAME, C_NS_CONSTRAINTS|| TO_CHAR(p_newschemaid));
    v_ret := copy_constraint_details(v_originalid, v_newid, p_newconnectionid);
  END LOOP;
  CLOSE cv_curs;
  return v_count;    
END copy_all_constraints_cascade;

FUNCTION copy_all_columns_cascade(p_oldtableid MD_TABLES.ID%TYPE, p_newtableid MD_TABLES.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_COLUMNS WHERE TABLE_ID_FK = ' || p_oldtableid;
  v_originalId MD_COLUMNS.ID%TYPE;
  v_newid MD_COLUMNS.ID%TYPE;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_COLUMNS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_COLUMNS, 'COLUMN_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.TABLE_ID_FK := p_newtableid;
    INSERT /* APEX13e8c1 */  INTO MD_COLUMNS values  v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- Columns don't need a namespace as such, they must not clash within the table.  We'll handle this
	-- As a special case.
    INSERT /* APEX6ad23f */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, original_identifier, new_identifier, DERIVED_OBJECT_NAMESPACE)
    VALUES(v_originalid, C_OBJECTTYPE_COLUMNS, v_newid, C_OBJECTTYPE_COLUMNS, p_newconnectionid, v_row.column_name, v_row.column_name, C_OBJECTTYPE_COLUMNS || TO_CHAR(p_newtableid));
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_columns_cascade;

FUNCTION copy_index_details(p_oldindexid MD_INDEXES.ID%TYPE, p_newindexid MD_INDEXES.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR curs is SELECT * FROM MD_INDEX_DETAILS WHERE MD_INDEX_DETAILS.INDEX_ID_FK = p_oldindexid;
  v_originalid MD_INDEX_DETAILS.ID%TYPE;
  v_newid MD_INDEX_DETAILS.ID%TYPE;
  v_count NUMBER := 0;
  v_ret NUMBER;
BEGIN
  FOR v_row IN CURS LOOP
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.INDEX_ID_FK := p_newindexid;
    v_row.COLUMN_ID_FK := find_object_copy(v_row.COLUMN_ID_FK, C_OBJECTTYPE_COLUMNS, p_newconnectionid);
    INSERT INTO MD_INDEX_DETAILS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- Index details don't have identifiers, so don't need a namespace.
    INSERT INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK)
    VALUES(v_originalid, C_OBJECTTYPE_INDEX_DETAILS, v_newid, C_OBJECTTYPE_INDEX_DETAILS, p_newconnectionid);
  END LOOP;
  RETURN v_count;
END copy_index_details;

FUNCTION copy_all_indexes(p_oldtableid MD_TABLES.ID%TYPE, p_newtableid MD_TABLES.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_filter_set MIGR_FILTER_SET) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_INDEXES WHERE MD_INDEXES.TABLE_ID_FK = ' || p_oldtableid;
  v_originalid MD_INDEXES.ID%TYPE;
  v_newid MD_INDEXES.ID%TYPE;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_INDEXES%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_INDEXES, 'INDEX_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;

    v_row.ID := NULL;
    v_row.TABLE_ID_FK := p_newtableid;
    INSERT /* APEX97ce1b */  INTO MD_INDEXES values v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEXe06bd4 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
    VALUES(v_originalid, C_OBJECTTYPE_INDEXES, v_newid, C_OBJECTTYPE_INDEXES, p_newconnectionid, v_row.INDEX_NAME, v_row.INDEX_NAME, C_NS_INDEXES || p_newschemaid);
    v_ret := copy_index_details(v_originalid, v_newid, p_newconnectionid);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_indexes;

FUNCTION copy_all_table_triggers(p_oldtableid MD_TABLES.ID%TYPE, p_newtableid MD_TABLES.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_TRIGGERS WHERE MD_TRIGGERS.TABLE_OR_VIEW_ID_FK = ' || p_oldtableid;
  v_originalid MD_TRIGGERS.ID%TYPE;
  v_newid MD_TRIGGERS.ID%TYPE;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_TRIGGERS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_TRIGGERS, 'TRIGGER_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.TABLE_OR_VIEW_ID_FK := p_newtableid;
    INSERT /* APEX4ced8d */  INTO MD_TRIGGERS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX2ea386 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
    VALUES(v_originalid, C_OBJECTTYPE_TRIGGERS, v_newid, C_OBJECTTYPE_TRIGGERS, p_newconnectionid, v_row.TRIGGER_NAME, v_row.TRIGGER_NAME, C_NS_DB_TRIGGERS);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_table_triggers;

FUNCTION copy_all_tables_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET :=NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  /*CURSOR curs IS SELECT * FROM MD_TABLES where SCHEMA_ID_FK = p_oldschemaid; */
  v_newid MD_TABLES.ID%TYPE := NULL;
  v_originalid MD_TABLES.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_TABLES%ROWTYPE;
  v_filt MIGR_FILTER;
  v_condition VARCHAR2(4000);
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_TABLES where SCHEMA_ID_FK = ' || p_oldschemaid;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_TABLES, 'TABLE_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEXdc6972 */  INTO MD_TABLES values v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEXcd0659 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid, C_OBJECTTYPE_TABLES, v_newid, C_OBJECTTYPE_TABLES, p_newconnectionid, v_row.TABLE_NAME, v_row.TABLE_NAME,  C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
    v_ret := copy_all_columns_cascade(v_originalid, v_newid, p_newconnectionid, p_filter_set);
    v_ret := copy_all_indexes(v_originalid, v_newid, p_newconnectionid, p_newschemaid, p_filter_set);
    v_ret := copy_all_table_triggers(v_originalid, v_newid, p_newconnectionid, p_filter_set);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_tables_cascade;

FUNCTION copy_all_view_triggers(p_oldviewid MD_VIEWS.ID%TYPE, p_newviewid MD_VIEWS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR curs IS SELECT * FROM MD_TRIGGERS WHERE MD_TRIGGERS.TABLE_OR_VIEW_ID_FK = p_oldviewid;
  v_originalid MD_TRIGGERS.ID%TYPE;
  v_newid MD_TRIGGERS.ID%TYPE;
  v_count NUMBER := 0;
  v_ret NUMBER;
BEGIN
  FOR v_row IN curs LOOP
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.TABLE_OR_VIEW_ID_FK := p_newviewid;
    INSERT INTO MD_TRIGGERS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
    VALUES(v_originalid, C_OBJECTTYPE_TRIGGERS, v_newid, C_OBJECTTYPE_TRIGGERS, p_newconnectionid, v_row.TRIGGER_NAME, v_row.TRIGGER_NAME, C_NS_DB_TRIGGERS);
  END LOOP;
  return v_count;
END copy_all_view_triggers;

FUNCTION copy_all_views_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_VIEWS WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_VIEWS.ID%TYPE := NULL;
  v_originalid MD_VIEWS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_VIEWS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_VIEWS, 'VIEW_NAME' ,'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs into v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEX82b502 */  INTO MD_VIEWS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX97cda7 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_VIEWS,   v_newid,   C_OBJECTTYPE_VIEWS, p_newconnectionid, v_row.VIEW_NAME, v_row.VIEW_NAME, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
    v_ret := copy_all_view_triggers(v_originalid, v_newid, p_newconnectionid);
  END LOOP;
  CLOSE cv_curs;
  RETURN v_count;
END copy_all_views_cascade;

FUNCTION copy_group_members(p_oldgroupid MD_GROUPS.ID%TYPE, p_newgroupid MD_GROUPS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR curs IS SELECT * FROM MD_GROUP_MEMBERS WHERE GROUP_ID_FK = p_oldgroupid;
  v_newid MD_GROUP_MEMBERS.ID%TYPE := NULL;
  v_originalid MD_GROUP_MEMBERS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
BEGIN
  FOR v_row IN curs LOOP
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.GROUP_ID_FK := p_newgroupid;
    v_row.USER_ID_FK := find_object_copy(v_row.USER_ID_FK, C_OBJECTTYPE_USERS, p_newconnectionid);
    INSERT INTO MD_GROUP_MEMBERS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- Group members do not have identifiers, so don't need a namespace
    INSERT INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK)
      VALUES(v_originalid,   C_OBJECTTYPE_GROUP_MEMBERS,   v_newid,   C_OBJECTTYPE_GROUP_MEMBERS, p_newconnectionid);
  END LOOP;
  return v_count;
END copy_group_members;

FUNCTION copy_all_groups_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_GROUPS WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_GROUPS.ID%TYPE := NULL;
  v_originalid MD_GROUPS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_namespace MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE := NULL;
  v_row MD_GROUPS%ROWTYPE;
  v_catalogname MD_CATALOGS.CATALOG_NAME%TYPE;
  v_catalogdummy MD_CATALOGS.DUMMY_FLAG%TYPE;
  v_oldname MD_GROUPS.GROUP_NAME%TYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_GROUPS, 'GROUP_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    SELECT /* APEXf67838 */  CATALOG_NAME, DUMMY_FLAG INTO v_catalogname, v_catalogdummy
      FROM MD_CATALOGS, MD_SCHEMAS WHERE MD_CATALOGS.ID = MD_SCHEMAS.CATALOG_ID_FK 
      AND MD_SCHEMAS.ID = p_oldschemaid;
    v_oldname := v_row.GROUP_NAME;
    if v_catalogdummy <> C_DUMMYFLAG_TRUE then
      v_row.GROUP_NAME := v_row.GROUP_NAME || '_' || v_catalogname;
    END IF;
    INSERT /* APEX590cc8 */  INTO MD_GROUPS values v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	IF v_row.GROUP_FLAG = C_ROLE_FLAG THEN
		v_namespace := C_NS_USER_ROLES;
	ELSE
		v_namespace := C_NS_DATABASE;
	END IF;
    INSERT /* APEX5af855 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid, C_OBJECTTYPE_GROUPS, v_newid, C_OBJECTTYPE_GROUPS, p_newconnectionid, v_oldname, v_row.GROUP_NAME, v_namespace);
    v_ret := copy_group_members(v_originalid, v_newid, p_newconnectionid);   
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_groups_cascade;

FUNCTION copy_all_users_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_USERS WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_USERS.ID%TYPE := NULL;
  v_originalid MD_USERS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_USERS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_USERS, 'USERNAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEX0fe45d */  INTO MD_USERS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX0e5fd5 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_USERS,   v_newid,   C_OBJECTTYPE_USERS, p_newconnectionid, v_row.USERNAME, v_row.USERNAME, C_NS_USERS);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_users_cascade;

FUNCTION copy_all_other_objects_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_OTHER_OBJECTS WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_OTHER_OBJECTS.ID%TYPE := NULL;
  v_originalid MD_OTHER_OBJECTS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_OTHER_OBJECTS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_OTHER_OBJECTS, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEXa579b1 */  INTO MD_OTHER_OBJECTS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX16da27 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_OTHER_OBJECTS,   v_newid,   C_OBJECTTYPE_OTHER_OBJECTS, p_newconnectionid, v_row.NAME, v_row.NAME, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_other_objects_cascade;

FUNCTION copy_all_tablespaces_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_TABLESPACES WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_TABLESPACES.ID%TYPE := NULL;
  v_originalid MD_TABLESPACES.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_TABLESPACES%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_TABLESPACES, 'TABLESPACE_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEXcc0cda */  INTO MD_TABLESPACES VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX9d43e8 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_TABLESPACES,   v_newid,   C_OBJECTTYPE_TABLESPACES, p_newconnectionid, v_row.TABLESPACE_NAME, v_row.TABLESPACE_NAME, C_NS_TABLESPACES);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_tablespaces_cascade;

FUNCTION copy_all_udds_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_USER_DEFINED_DATA_TYPES WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_USER_DEFINED_DATA_TYPES.ID%TYPE := NULL;
  v_originalid MD_USER_DEFINED_DATA_TYPES.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_USER_DEFINED_DATA_TYPES%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_UDDT, 'DATA_TYPE_NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEX6f21bc */  INTO MD_USER_DEFINED_DATA_TYPES VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX10196b */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_UDDT,   v_newid,   C_OBJECTTYPE_UDDT, p_newconnectionid, v_row.DATA_TYPE_NAME, v_row.DATA_TYPE_NAME, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_udds_cascade;

FUNCTION copy_child_procedures(p_oldpackageid MD_PACKAGES.ID%TYPE, p_newpackageid MD_PACKAGES.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_STORED_PROGRAMS WHERE PACKAGE_ID_FK = ' || p_oldpackageid;
  v_newid MD_STORED_PROGRAMS.ID%TYPE := NULL;
  v_originalid MD_STORED_PROGRAMS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_STORED_PROGRAMS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_STORED_PROGRAMS, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.PACKAGE_ID_FK := p_newpackageid;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEXdf6e6a */  INTO MD_STORED_PROGRAMS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- No need for namespace here, the namespace is the package itself.
    INSERT /* APEXc32b1c */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
      VALUES(v_originalid,   C_OBJECTTYPE_STORED_PROGRAMS,   v_newid,   C_OBJECTTYPE_STORED_PROGRAMS, p_newconnectionid, v_row.NAME, v_row.NAME);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_child_procedures;

FUNCTION copy_all_packages_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_PACKAGES WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_PACKAGES.ID%TYPE := NULL;
  v_originalid MD_PACKAGES.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_PACKAGES%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_PACKAGES, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEX261d79 */  INTO MD_PACKAGES VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX71aa11 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_PACKAGES,   v_newid,   C_OBJECTTYPE_PACKAGES, p_newconnectionid, v_row.NAME, v_row.NAME, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
    v_ret := copy_child_procedures(v_originalid, v_newid, p_newschemaid, p_newconnectionid, p_filter_set);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_packages_cascade;

FUNCTION copy_all_unpackaged_sps(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_STORED_PROGRAMS WHERE SCHEMA_ID_FK = ' || p_oldschemaid ||' AND PACKAGE_ID_FK IS NULL';
  v_newid MD_STORED_PROGRAMS.ID%TYPE := NULL;
  v_originalid MD_STORED_PROGRAMS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_STORED_PROGRAMS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_STORED_PROGRAMS, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.schema_id_fk := p_newschemaid;
    INSERT /* APEXb512c3 */  INTO MD_STORED_PROGRAMS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- Non-packaged procedures belong in the schema objects namespace.
    INSERT /* APEX5a765e */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid, C_OBJECTTYPE_STORED_PROGRAMS, v_newid, C_OBJECTTYPE_STORED_PROGRAMS, p_newconnectionid, v_row.NAME, v_row.NAME, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_unpackaged_sps;

FUNCTION copy_all_synonyms_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_SYNONYMS WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_SYNONYMS.ID%TYPE := NULL;
  v_originalid MD_SYNONYMS.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_namespace MD_DERIVATIVES.DERIVED_OBJECT_NAMESPACE%TYPE;
  v_row MD_SYNONYMS%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_SYNONYMS, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.SYNONYM_FOR_ID := find_object_copy(v_row.SYNONYM_FOR_ID, v_row.FOR_OBJECT_TYPE, p_newconnectionid);
    INSERT /* APEX847b11 */  INTO MD_SYNONYMS VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
	-- Synonyms have two potential name spaces:  Private synonyms belong in the schema objects, while public 
	-- synonyms belong in their own namespace.
	IF v_row.PRIVATE_VISIBILITY = C_SYNONYM_PRIVATE THEN
		v_namespace := C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid);
	ELSE
		v_namespace := C_NS_PUBLIC_SYNONYMS;
        END IF;
    INSERT /* APEX77a859 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid, C_OBJECTTYPE_SYNONYMS, v_newid, C_OBJECTTYPE_SYNONYMS, p_newconnectionid, v_row.NAME, v_row.NAME, v_namespace);
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_synonyms_cascade;

FUNCTION copy_all_sequences_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_SEQUENCES WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_SEQUENCES.ID%TYPE := NULL;
  v_originalid MD_SEQUENCES.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_SEQUENCES%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_SEQUENCES, 'NAME', 'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    INSERT /* APEX8dc51f */  INTO MD_SEQUENCES VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT /* APEX8995e0 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, derived_connection_id_fk, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid, C_OBJECTTYPE_SEQUENCES, v_newid, C_OBJECTTYPE_SEQUENCES, p_newconnectionid, v_row.NAME, v_row.NAME, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
  END LOOP;
  CLOSE cv_curs;
  return v_count;
END copy_all_sequences_cascade;

FUNCTION copy_user_privileges(p_olduserid MD_PRIVILEGES.ID%TYPE, p_newuserid MD_PRIVILEGES.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR curs is SELECT * FROM MD_USER_PRIVILEGES WHERE PRIVILEGE_ID_FK = p_olduserid;
  v_newid MD_USER_PRIVILEGES.ID%TYPE;
  v_count NUMBER := 0;
  v_originalid MD_USER_PRIVILEGES.ID%TYPE;
  v_ret NUMBER;
BEGIN
  FOR v_row IN curs LOOP
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.USER_ID_FK := find_object_copy(v_row.USER_ID_FK , C_OBJECTTYPE_USERS, p_newconnectionid);
    v_row.PRIVILEGE_ID_FK := p_newuserid;
    INSERT INTO MD_USER_PRIVILEGES values v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    INSERT INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK)
      VALUES(v_originalid, C_OBJECTTYPE_USER_PRIVILEGES, v_newid, C_OBJECTTYPE_USER_PRIVILEGES, p_newconnectionid);
  END LOOP;
  return v_count;
END copy_user_privileges;

FUNCTION copy_all_privileges_cascade(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_PRIVILEGES WHERE SCHEMA_ID_FK = ' || p_oldschemaid;
  v_newid MD_PRIVILEGES.ID%TYPE := NULL;
  v_originalid MD_PRIVILEGES.ID%TYPE := NULL;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_row MD_PRIVILEGES%ROWTYPE;
BEGIN
  v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_PRIVILEGES, 'PRIVILEGE_NAME' ,'ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs into v_row;
    EXIT WHEN cv_curs%NOTFOUND;
    v_originalid := v_row.ID;
    v_row.ID := NULL;
    v_row.PRIVELEGE_OBJECT_ID := find_object_copy(v_row.PRIVELEGE_OBJECT_ID , v_row.PRIVELEGEOBJECTTYPE, p_newconnectionid);
    v_row.SCHEMA_ID_FK := p_newschemaid;
    INSERT /* APEX77d54d */  INTO MD_PRIVILEGES VALUES v_row RETURNING ID INTO v_newid;
    v_ret := copy_additional_properties(v_originalid, v_newid, p_newconnectionid);
    v_count := v_count + 1;
    -- No need to pass on the identifiers to the derivatives as no need to worry about the clashes for the same.
    INSERT /* APEX0ce3d5 */  INTO MD_DERIVATIVES(src_id, src_type, derived_id, derived_type, DERIVED_CONNECTION_ID_FK, DERIVED_OBJECT_NAMESPACE)
      VALUES(v_originalid,   C_OBJECTTYPE_PRIVILEGES,   v_newid,   C_OBJECTTYPE_PRIVILEGES, p_newconnectionid, C_NS_SCHEMA_OBJS || TO_CHAR(p_newschemaid));
    v_ret := copy_user_privileges(v_originalid, v_newid, p_newconnectionid);
  END LOOP;
  CLOSE cv_curs;
  RETURN v_count;
END copy_all_privileges_cascade;

FUNCTION copy_all_cross_schema_objects(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  v_ret NUMBER;
BEGIN
-- DD; Can't do this until all schema tables are done
-- There may be foreign keys between schema
  v_ret := copy_all_constraints_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_groups_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_other_objects_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_privileges_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  -- Do synonyms last: This way, we can be sure that the oject for which it is a synonym
  -- has already been copied.
  v_ret := copy_all_synonyms_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  return v_ret;
END copy_all_cross_schema_objects;

FUNCTION copy_all_schema_objects(p_oldschemaid MD_SCHEMAS.ID%TYPE, p_newschemaid MD_SCHEMAS.ID%TYPE, p_newconnectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL) RETURN NUMBER
IS
  v_ret NUMBER;
BEGIN
  v_ret := copy_all_tables_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_views_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_users_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_tablespaces_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_udds_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_packages_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_unpackaged_sps(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  v_ret := copy_all_sequences_cascade(p_oldschemaid, p_newschemaid, p_newconnectionid, p_filter_set);
  -- TODO: Roles are wrong in the model right now.  I need to fix these up.
  --v_ret := copy_all_roles_cascade(p_oldschemaid, p_newschemaid);
  return v_ret;  
END copy_all_schema_objects;


FUNCTION CREATE_SCHEMANAME(p_schemaName VARCHAR2,p_catalogName VARCHAR2) RETURN VARCHAR2
IS
BEGIN
IF UPPER(p_schemaName)  = 'DBO' THEN
  RETURN p_catalogName;
ELSE
 RETURN p_schemaName || '_' || p_catalogName;
 END IF;
END CREATE_SCHEMANAME;

FUNCTION copy_catalogs_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE, 
                                   p_catalogid MD_CATALOGS.ID%TYPE, 
                                   p_newcatalogid MD_CATALOGS.ID%TYPE, 
                                   p_newconnectionid MD_CONNECTIONS.ID%TYPE, 
                                   p_filter_set MIGR_FILTER_SET :=NULL) RETURN NUMBER
IS
  cv_curs REF_CURSOR;
  v_newid NUMBER;
  v_count NUMBER := 0;
  v_ret NUMBER;
  v_newName MD_SCHEMAS.NAME%TYPE;
  v_filt MIGR_FILTER;
  v_selectStmt VARCHAR2(4000) := 'SELECT a.id schema_id, A.name schema_name, b.id catalog_id, B.CATALOG_NAME, B.DUMMY_FLAG, A.type, A.character_set, A.version_tag 
      FROM MD_SCHEMAS A, MD_CATALOGS B
      WHERE 
      	A.CATALOG_ID_FK = B.ID 
        AND B.ID =' || p_catalogid  || 
        ' AND CONNECTION_ID_FK = ' || p_connectionid ;
--  v_schemaid MD_SCHEMAS.ID%TYPE;
--  v_schemaname MD_SCHEMAS.NAME%TYPE;
--  v_catalogid MD_CATALOGS.ID%TYPE;
--  v_catalogname MD_CATALOGS.CATALOG_NAME%TYPE;
--  v_catalogdummy MD_CATALOGS.DUMMY_FLAG%TYPE;
--  v_schematype MD_SCHEMAS.TYPE%TYPE;
--  v_schemacharset MD_SCHEMAS.CHARACTER_SET%TYPE;
--  v_schemaversiontag MD_SCHEMAS.VERSION_TAG%TYPE;

  v_derivedRec  DERIVATIVE_REC;
  v_derivedRec2 DERIVATIVE_REC2;
BEGIN
  --v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_CATALOGS, 'B.CATALOG_NAME', 'B.ID', v_selectStmt);
  -- NOTE: May need to apply a schema filter here too
  --v_selectStmt := apply_filter(p_filter_set, C_OBJECTTYPE_SCHEMAS, 'A.NAME', 'A.ID', v_selectStmt);
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    --FETCH cv_curs INTO v_schemaid, v_schemaname, v_catalogid, v_catalogname, v_catalogdummy, v_schematype, v_schemacharset, v_schemaversiontag;
    FETCH cv_curs INTO v_derivedRec;
    EXIT WHEN cv_curs%NOTFOUND;

    /*
     schema_id          NUMBER,
     schema_name        VARCHAR2(4000 BYTE),
     catalog_id         NUMBER,
     catalog_name       VARCHAR2(4000 BYTE),
     dummy_flag         CHAR(1 BYTE),
     character_set      VARCHAR2(4000 BYTE),
     version_tag        VARCHAR2(40 BYTE)

    */
    -- TODO: Handle wrapping here.
    if v_derivedRec.dummy_flag  <> C_DUMMYFLAG_TRUE then
      v_newName := CREATE_SCHEMANAME(v_derivedRec.schema_name,v_derivedRec.catalog_name);
	else
	  v_newName := v_derivedRec.schema_name;
	end if;
    INSERT /* APEXabce74 */  INTO MD_SCHEMAS(CATALOG_ID_FK, NAME, TYPE, CHARACTER_SET, VERSION_TAG)
    VALUES (p_newcatalogid,  v_newName, v_derivedRec.cap_type, v_derivedRec.character_set, v_derivedRec.version_tag)
    RETURNING ID INTO v_newid;
    -- Here's and interesting situation.  What will we do with the additional properties?
    -- I can coalesce them such that they are in the condensed catalog/schema pair
    -- But their order could (will) contain duplicates.....
    v_ret := copy_additional_properties(p_catalogid, v_newid, p_newconnectionid);
    v_ret := copy_additional_properties(v_derivedRec.schema_id, v_newid, p_newconnectionid);
	-- No Need for namespace stuff for catalogs.
    INSERT /* APEX057955 */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK,
      ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
    VALUES (v_derivedRec.schema_id, C_OBJECTTYPE_SCHEMAS, v_newid, C_OBJECTTYPE_SCHEMAS, p_newconnectionid, v_derivedRec.schema_name, v_newName);
    INSERT /* APEX06931c */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
    VALUES (v_derivedRec.catalog_id, C_OBJECTTYPE_CATALOGS, v_newid, C_OBJECTTYPE_SCHEMAS, p_newconnectionid, v_derivedRec.catalog_name, v_newName);
    -- TODO: ADD THE FILTER TO THE PARAMETERS BELOW
    v_ret := copy_all_schema_objects(v_derivedRec.schema_id, v_newid, p_newconnectionid, p_filter_set);
    v_count := v_count + 1;
    v_newName :='';
  END LOOP;
  CLOSE cv_curs;
  -- Now...Once all of the schema objects have been done, we have to copy all of those objects that could cross
  -- schema boundaries.  So we need to loop through them again
v_selectStmt := 'SELECT SRC_ID, DERIVED_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = ' 
  					|| '''' || C_OBJECTTYPE_SCHEMAS || ''' AND DERIVED_TYPE = ''' || C_OBJECTTYPE_SCHEMAS ||''''
  					--|| ' AND DERIVED_CONNECTION_ID_FK = ' || p_newconnectionid
                      || ' AND DERIVED_ID IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CATALOG_ID = ' || p_newcatalogid || ' AND CONNECTION_ID = ' || p_newconnectionid || ')';
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs into v_derivedRec2;
    EXIT when cv_curs%NOTFOUND;
    v_ret := copy_all_cross_schema_objects(v_derivedRec2.schemaid, v_derivedRec2.newid, p_newconnectionid, p_filter_set);
  END LOOP;
  CLOSE cv_curs;  					
  return v_count;
END copy_catalogs_cascade;

FUNCTION remove_duplicate_indexes(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR v_curs IS select  index_id_fk, sum(md_index_details.column_id_fk * md_index_details.detail_order) simplehash from md_index_details 
    where index_id_fk in (select id from md_indexes where table_id_fk in (select table_id from mgv_all_tables where connection_id = p_connectionid)) 
    group by index_id_fk
    order by simplehash, index_id_fk;
  v_lasthash NUMBER :=0;
  v_currenthash NUMBER :=0;
  v_currentid MD_INDEX_DETAILS.INDEX_ID_FK%TYPE;
  v_lastid MD_INDEX_DETAILS.INDEX_ID_FK%TYPE;
  v_count NUMBER := 0;
  v_sql VARCHAR(255);
BEGIN
  OPEN v_curs;
  LOOP
    FETCH v_curs into v_currentid, v_currenthash;
    EXIT WHEN v_curs%NOTFOUND;
    if v_currenthash = v_lasthash THEN
      -- dbms_output.put_line('Index ' || TO_CHAR(v_currentid) || ' is a duplicate');
      v_sql := 'DELETE FROM MD_INDEXES WHERE ID = ' || v_currentid;
      EXECUTE IMMEDIATE v_sql;
      --dbms_output.put_line('DELETE FROM MD_INDEXES WHERE ID = ' || v_currentid);
      v_sql := 'UPDATE MD_DERIVATIVES SET DERIVATIVE_REASON = ''DUPIND'', DERIVED_ID = ' || TO_CHAR(v_lastid)  || ' WHERE DERIVED_ID = ' || TO_CHAR(v_currentid);
      EXECUTE IMMEDIATE v_sql;
      -- dbms_output.put_line('UPDATE MD_DERIVATIVES SET DERIVED_ID = ' || TO_CHAR(v_lastid)  || ' WHERE DERIVED_ID = ' || TO_CHAR(v_currentid));
      v_count := v_count + 1;
    else
      v_lasthash := v_currenthash;
      v_lastid := v_currentid;
    end if;
  END LOOP;
  CLOSE v_curs;
  return v_count;    
END remove_duplicate_indexes;

FUNCTION remove_indexes_used_elsewhere(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR v_curs IS
    select INDEX_ID_FK from 
      (select  index_id_fk, sum(md_index_details.column_id_fk * md_index_details.detail_order) simplehash from md_index_details 
       where index_id_fk in (select id from md_indexes where table_id_fk in (select table_id from mgv_all_tables where connection_id = p_connectionid)) 
       group by index_id_fk
       order by simplehash) a
    WHERE A.SIMPLEHASH 
    IN
    (
      SELECT b.simplehash FROM 
      (
        SELECT SUM(MD_CONSTRAINT_DETAILS.COLUMN_ID_FK * MD_CONSTRAINT_DETAILS.DETAIL_ORDER) simplehash from md_constraint_details
        where constraint_id_fk in (select id from md_constraints where table_id_fk in (select table_id from mgv_all_tables where connection_id = p_connectionid))
        group by constraint_id_fk
        order by simplehash
      ) b
     );
  v_currentId MD_INDEX_DETAILS.INDEX_ID_FK%TYPE;     
  v_sql VARCHAR2(255);
  v_count NUMBER := 0;
BEGIN
  OPEN v_curs;
  LOOP
    FETCH v_curs into v_currentid;
    EXIT WHEN v_curs%NOTFOUND;
      v_sql := 'DELETE FROM MD_INDEXES WHERE ID = ' || v_currentid;
      EXECUTE IMMEDIATE v_sql;
      --dbms_output.put_line('DELETE FROM MD_INDEXES WHERE ID = ' || v_currentid);
      v_sql := 'DELETE FROM MD_DERIVATIVES WHERE DERIVED_ID = ' || TO_CHAR(v_currentid);
      EXECUTE IMMEDIATE v_sql;
      -- dbms_output.put_line('UPDATE MD_DERIVATIVES SET DERIVED_ID = ' || TO_CHAR(v_lastid)  || ' WHERE DERIVED_ID = ' || TO_CHAR(v_currentid));
      v_count := v_count + 1;
  END LOOP;
  CLOSE v_curs;
  RETURN v_count;
END remove_indexes_used_elsewhere;    

PROCEDURE cut_lob_indexes_to_25(p_connectionId MD_CONNECTIONS.ID%TYPE)
IS
  CURSOR v_curs (context MD_ADDITIONAL_PROPERTIES.VALUE%TYPE, ctxcat MD_ADDITIONAL_PROPERTIES.VALUE%TYPE) is 
    SELECT * FROM MD_INDEXES WHERE 
    TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid)
    AND LENGTH(INDEX_NAME) > 25 AND  
    ( EXISTS (SELECT 1 FROM MD_ADDITIONAL_PROPERTIES WHERE ( VALUE = context 
    OR VALUE = ctxcat ) AND REF_ID_FK = MD_INDEXES.ID ) )
    FOR UPDATE OF INDEX_NAME;
  v_numIndexCount INTEGER := 1;
  v_newName MD_INDEXES.INDEX_NAME%TYPE;
  v_row MD_INDEXES%ROWTYPE;
BEGIN
-- totierne: for each lob index cut to 23 or 22 or 21 to put _XXX up to 25 chars (should be bytes)
  OPEN v_curs (C_INDEXTYPE_CONTEXT, C_INDEXTYPE_CTXCAT);
  LOOP
    FETCH v_curs INTO v_row;
    EXIT WHEN v_curs%NOTFOUND;
    v_newName := MIGRATION_TRANSFORMER.add_suffix(v_row.INDEX_NAME, '_' || TO_CHAR(v_numIndexCount), 25);
    update /* APEXa5c421 */  MD_INDEXES SET index_name = v_newName where current of v_curs;
    v_numIndexCount := v_numIndexCount + 1;
  END LOOP;
  CLOSE v_curs;
  commit;
END cut_lob_indexes_to_25;

FUNCTION fixupTextIndexes(p_connectionId MD_CONNECTIONS.ID%TYPE) return NUMBER
IS
  CURSOR v_curs is
    select index_id_fk, count(*) numcols from md_index_details where
    index_id_fk in (
      select c.id
      from md_columns a, md_index_details b, md_indexes c
      where b.column_id_fk = a.id
      and column_type in ('BLOB', 'CLOB')
      and b.index_id_fk = c.id
      and c.table_id_fk in (select table_id from mgv_all_tables where connection_id = p_connectionid)
    ) group by index_id_fk;
  v_indexId MD_INDEXES.ID%TYPE;
  v_numCols INTEGER;
  v_extendedIndexType MD_ADDITIONAL_PROPERTIES.VALUE%TYPE;
BEGIN        
  OPEN v_curs;
  LOOP
    FETCH v_curs into v_indexId, v_numCols;
    EXIT WHEN v_curs%NOTFOUND;
    IF v_numCols = 1 THEN
      v_extendedIndexType := C_INDEXTYPE_CONTEXT;
    ELSE
      v_extendedIndexType := C_INDEXTYPE_CTXCAT;
    END IF;
    INSERT /* APEX0325eb */  INTO MD_ADDITIONAL_PROPERTIES(CONNECTION_ID_FK ,REF_ID_FK, REF_TYPE, PROP_KEY, VALUE)
    VALUES (p_connectionId, v_indexId, C_OBJECTTYPE_INDEXES, C_PROPKEY_EXTENDEDINDEXTYPE, v_extendedIndexType);
    COMMIT;
  END LOOP;
  -- NCLOBs cannot be indexed.  They aren't allowed in normal indexes, and they aren't allowed in TEXT 
  -- indexes.   The only thing to do here is to remove it.
  -- TODO: We can't just do this silently.
   -- Mark THE derivative RECORD AS DELETEd.
  UPDATE /* APEX411608 */  md_derivatives SET DERIVATIVE_REASON = 'NCLOBIND' WHERE DERIVED_TYPE = 'MD_INDEXES' AND DERIVED_CONNECTION_ID_FK = p_connectionid
      AND  DERIVED_ID IN 
             (SELECT C.ID   FROM MD_COLUMNS A, MD_INDEX_DETAILS B, MD_INDEXES C, MGV_ALL_TABLES D
                 WHERE B.COLUMN_ID_FK = A.ID AND COLUMN_TYPE ='NCLOB' AND B.INDEX_ID_FK = C.ID
                  AND C.TABLE_ID_FK = D.TABLE_ID AND D.CONNECTION_ID = p_connectionid);
  DELETE /* APEXe4da0a */  FROM MD_INDEXES WHERE ID IN
             (SELECT C.ID   FROM MD_COLUMNS A, MD_INDEX_DETAILS B, MD_INDEXES C, MGV_ALL_TABLES D
                 WHERE B.COLUMN_ID_FK = A.ID AND COLUMN_TYPE ='NCLOB' AND B.INDEX_ID_FK = C.ID
                  AND C.TABLE_ID_FK = D.TABLE_ID AND D.CONNECTION_ID = p_connectionid);
  -- cut blob/clob index string to 25 characters with _nn incrementing marker
  cut_lob_indexes_to_25(p_connectionId);
  CLOSE v_curs;
  return 0;
END fixupTextIndexes;

PROCEDURE createDummyScrTblPerSchema_ee(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS                               
  v_qualified_native_name VARCHAR2(300);
  n_newtblid NUMBER;
  tbltrigRec MD_TRIGGERS%ROWTYPE;
  n_newtrigId MD_TRIGGERS."ID"%TYPE;
  origtrigId MD_TRIGGERS."ID"%TYPE;
  CURSOR curtblTrig(schId MD_SCHEMAS."ID"%TYPE) IS SELECT * FROM MD_TRIGGERS 
                                       WHERE TRIGGER_ON_FLAG = 'T'
                                           AND TABLE_OR_VIEW_ID_FK IN (
                                                SELECT "ID" 
                                                FROM MD_TABLES
                                                WHERE SCHEMA_ID_FK = schId);

BEGIN
   SELECT /* APEX7ee71a */  A.catalog_name || '.' || B."NAME" || 'DUMMY' INTO v_qualified_native_name
             FROM MD_CATALOGS A, MD_SCHEMAS B
             WHERE A."ID" = B.catalog_id_fk
                   AND B."ID" = schemaId;

   -- insert 1 DUMMY table per schema.  We don't want to create peer records in md_tables for each table entry
   INSERT /* APEXc8bf9a */  INTO MD_TABLES(schema_id_fk, table_name, qualified_native_name)
                  VALUES(new_schemaId, 'DUMMY', v_qualified_native_name)
                  RETURNING "ID" INTO n_newtblid;
   -- There is no additional property to copy as this is a dummy table with no src peer
   -- This table is used to attached all the translated triggers

   -- insert corresponding row into md_derivatives
   INSERT /* APEX8dc967 */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK,
               ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
                   VALUES (n_newtblid, C_OBJECTTYPE_TABLES, n_newtblId, C_OBJECTTYPE_TABLES, p_scratchConn, 'DUMMY', 'DUMMY');  

   --copy_all_tbl_trigs_ee
   OPEN curtblTrig(schemaId);
   FETCH curtblTrig INTO tbltrigRec;
   LOOP
      EXIT WHEN curtblTrig%NOTFOUND;
      origtrigId := tbltrigRec."ID";
      tbltrigRec."ID" := NULL;
      tbltrigRec.table_or_view_id_fk := n_newtblid;
      INSERT /* APEXeb2a18 */  INTO MD_TRIGGERS VALUES tbltrigRec RETURNING "ID" INTO n_newtrigId;

      -- insert corresponding row into md_derivatives
      INSERT /* APEXd4c5e7 */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK,
               ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
                   VALUES (origtrigId, C_OBJECTTYPE_TRIGGERS, n_newtrigId, C_OBJECTTYPE_TRIGGERS, p_scratchConn, tbltrigRec.TRIGGER_NAME, tbltrigRec.TRIGGER_NAME);  


      FETCH curtblTrig INTO tbltrigRec;
   END LOOP;
   CLOSE curtblTrig;

END createDummyScrTblPerSchema_ee;

PROCEDURE copy_all_views_ee(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS                         
   CURSOR curViews(schId MD_SCHEMAS."ID"%TYPE) IS SELECT * FROM MD_VIEWS WHERE SCHEMA_ID_FK = schId;
   viewRec MD_VIEWS%ROWTYPE;
   n_newVwid MD_VIEWS."ID"%TYPE;
   norigVwid MD_VIEWS."ID"%TYPE;
   n_ret NUMBER;

  vwtrigRec MD_TRIGGERS%ROWTYPE;
  n_newtrigId MD_TRIGGERS."ID"%TYPE;
  origtrigId MD_TRIGGERS."ID"%TYPE;
  CURSOR curvwTrig(schId MD_SCHEMAS."ID"%TYPE) IS SELECT * FROM MD_TRIGGERS 
                                       WHERE TRIGGER_ON_FLAG = 'V'
                                           AND TABLE_OR_VIEW_ID_FK IN (
                                                SELECT "ID" 
                                                FROM MD_TABLES
                                                WHERE SCHEMA_ID_FK = schId);   
BEGIN
   OPEN curViews(schemaId);
   FETCH curViews INTO viewRec;
   LOOP
      EXIT WHEN curViews%NOTFOUND;
      norigVwid := viewRec."ID";
      viewRec."ID" := NULL;
      viewRec.SCHEMA_ID_FK := new_schemaId;
      INSERT /* APEX9a24c0 */  INTO MD_VIEWS VALUES viewRec RETURNING "ID" INTO n_newVwId;
      n_ret := copy_additional_properties(viewRec."ID", n_newVwId, p_scratchConn);

      INSERT /* APEX047d7e */  INTO MD_DERIVATIVES(src_id, 
                                 src_type, 
                                 derived_id, 
                                 derived_type, 
                                 DERIVED_CONNECTION_ID_FK, 
                                 ORIGINAL_IDENTIFIER, 
                                 NEW_IDENTIFIER, 
                                 DERIVED_OBJECT_NAMESPACE)
                           VALUES(norigVwid,   
                                  C_OBJECTTYPE_VIEWS,   
                                  n_newVwId,   
                                  C_OBJECTTYPE_VIEWS, 
                                  p_scratchConn, viewRec.VIEW_NAME, viewRec.VIEW_NAME, C_NS_SCHEMA_OBJS || TO_CHAR(new_schemaId));

      -- Handle view triggers
      OPEN curvwTrig(schemaId);
      FETCH curvwTrig INTO vwtrigRec;
      LOOP
         EXIT WHEN curvwTrig%NOTFOUND;
         origtrigId := vwtrigRec."ID";
         vwtrigRec."ID" := NULL;
         vwtrigRec.table_or_view_id_fk := n_newVwId;

         INSERT /* APEX174e8d */  INTO MD_TRIGGERS VALUES vwtrigRec RETURNING "ID" INTO n_newtrigId;

         INSERT /* APEXc04ef5 */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK,
               ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
                   VALUES (origtrigId, C_OBJECTTYPE_TRIGGERS, n_newtrigId, C_OBJECTTYPE_TRIGGERS, p_scratchConn, vwtrigRec.TRIGGER_NAME, vwtrigRec.TRIGGER_NAME);           

         FETCH curvwTrig INTO vwtrigRec;         
      END LOOP; -- end vw trigger loop
      CLOSE curvwTrig;

      FETCH curViews INTO viewRec;
      --copy_all_tbl_trigs_ee      
   END LOOP; -- end vw loop
   CLOSE curViews;
END copy_all_views_ee;

PROCEDURE copy_all_unpackaged_sps_ee(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS              
   CURSOR curSps(schId MD_SCHEMAS."ID"%TYPE) IS SELECT * FROM MD_STORED_PROGRAMS WHERE SCHEMA_ID_FK = schId;
   spRec MD_STORED_PROGRAMS%ROWTYPE;
   n_newSpid MD_STORED_PROGRAMS."ID"%TYPE;
   norigSpid MD_STORED_PROGRAMS."ID"%TYPE;
   n_ret NUMBER;
BEGIN
   OPEN curSps(schemaId);
   FETCH curSps INTO spRec;
   LOOP
      EXIT WHEN curSps%NOTFOUND;
      norigSpid := spRec."ID";
      spRec."ID" := NULL;
      spRec.schema_id_fk := new_schemaId;

      INSERT /* APEX11b4d7 */  INTO MD_STORED_PROGRAMS VALUES spRec RETURNING "ID" INTO n_newSpid;
      n_ret := copy_additional_properties(spRec."ID", n_newSpid, p_scratchConn);

      INSERT /* APEX20b0a4 */  INTO MD_DERIVATIVES(src_id, 
                                 src_type, 
                                 derived_id, 
                                 derived_type, 
                                 DERIVED_CONNECTION_ID_FK, 
                                 ORIGINAL_IDENTIFIER, 
                                 NEW_IDENTIFIER, 
                                 DERIVED_OBJECT_NAMESPACE)
                           VALUES(norigSpid,   
                                  C_OBJECTTYPE_STORED_PROGRAMS,   
                                  n_newSpid,   
                                  C_OBJECTTYPE_STORED_PROGRAMS, 
                                  p_scratchConn, spRec."NAME", spRec."NAME", C_NS_SCHEMA_OBJS || TO_CHAR(new_schemaId));
      FETCH curSps INTO spRec;
   END LOOP;
   CLOSE curSps;
END copy_all_unpackaged_sps_ee;

PROCEDURE copy_all_tbl_trigs_ee(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS                                 
BEGIN
   NULL;
END copy_all_tbl_trigs_ee;

PROCEDURE copy_all_vw_trigs_ee(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS                                 
BEGIN
   NULL;
END copy_all_vw_trigs_ee;

PROCEDURE createIndexEntry(tableId MD_TABLES."ID"%TYPE, 
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS
   CURSOR curIndexes(tableId MD_TABLES."ID"%TYPE) IS SELECT * FROM md_indexes WHERE table_id_fk = tableId;
   idxRow MD_INDEXES%ROWTYPE;

BEGIN
   OPEN curIndexes(tableId);
   FETCH curIndexes INTO idxRow;

   LOOP
      EXIT WHEN curIndexes%NOTFOUND;

      INSERT /* APEX5aa9ac */  INTO MD_DERIVATIVES(src_id, 
                                 src_type, 
                                 derived_id, 
                                 derived_type, 
                                 DERIVED_CONNECTION_ID_FK, 
                                 ORIGINAL_IDENTIFIER, 
                                 NEW_IDENTIFIER, 
                                 DERIVED_OBJECT_NAMESPACE)
                           VALUES
                           (
                              idxRow."ID",
                              C_OBJECTTYPE_INDEXES,
                              idxRow."ID",
                              'MD_INDEXES',
                              p_scratchConn,
                              idxRow.index_name,
                              idxRow.index_name,
                              C_OBJECTTYPE_INDEXES || TO_CHAR(tableId)         
                           );      
      FETCH curIndexes INTO idxRow;
   END LOOP;
   CLOSE curIndexes;

END;

PROCEDURE createColumnEntry(tableId MD_TABLES."ID"%TYPE, 
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS
   CURSOR curColumns(tableId MD_TABLES."ID"%TYPE) IS SELECT * FROM md_columns WHERE table_id_fk = tableId;
   colRow MD_COLUMNS%ROWTYPE;
BEGIN
   OPEN curColumns(tableId);
   FETCH curColumns INTO colRow;

   LOOP
      EXIT WHEN curColumns%NOTFOUND;

      INSERT /* APEX37caa8 */  INTO MD_DERIVATIVES(src_id, 
                                 src_type, 
                                 derived_id, 
                                 derived_type, 
                                 DERIVED_CONNECTION_ID_FK, 
                                 ORIGINAL_IDENTIFIER, 
                                 NEW_IDENTIFIER, 
                                 DERIVED_OBJECT_NAMESPACE)
                           VALUES
                           (
                              colRow."ID",
                              C_OBJECTTYPE_COLUMNS,
                              colRow."ID",
                              'MD_COLUMNS',
                              p_scratchConn,
                              colRow.column_name,
                              colRow.column_name,
                              C_OBJECTTYPE_COLUMNS || TO_CHAR(tableId)         
                           );      
      FETCH curColumns INTO colRow;
   END LOOP;
   CLOSE curColumns;
END;


PROCEDURE createTableEntry(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS
   CURSOR curTables(schemaId MD_SCHEMAS."ID"%TYPE) IS SELECT * FROM md_tables WHERE schema_id_fk = schemaId;
   tblRow MD_TABLES%ROWTYPE;
BEGIN
   OPEN curTables(schemaId);
   FETCH curTables INTO tblRow;

   LOOP
      EXIT WHEN curTables%NOTFOUND;

      INSERT /* APEXf0d835 */  INTO MD_DERIVATIVES(src_id, 
                                 src_type, 
                                 derived_id, 
                                 derived_type, 
                                 DERIVED_CONNECTION_ID_FK, 
                                 ORIGINAL_IDENTIFIER, 
                                 NEW_IDENTIFIER, 
                                 DERIVED_OBJECT_NAMESPACE)
                           VALUES
                           (
                              tblRow."ID",
                              C_OBJECTTYPE_TABLES,
                              tblRow."ID",
                              'MD_TABLES',
                              p_scratchConn,
                              tblRow.table_name,
                              tblRow.table_name,
                              C_NS_SCHEMA_OBJS || TO_CHAR(new_schemaid)         
                           );      
      createColumnEntry(tblRow."ID", p_scratchConn);      
      createIndexEntry(tblRow."ID", p_scratchConn);      
      FETCH curTables INTO tblRow;
   END LOOP;
   CLOSE curTables;
END;


PROCEDURE createConstraintEntry(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS
BEGIN
   NULL;
END;


PROCEDURE copy_schema_objects_ee(schemaId MD_SCHEMAS."ID"%TYPE, 
                                 new_schemaId MD_SCHEMAS."ID"%TYPE,
                                 p_scratchConn MD_CONNECTIONS."ID"%TYPE)
IS                                 
BEGIN
    --This create scratch model for table triggers as well
    createDummyScrTblPerSchema_ee(schemaId,   
                                 new_schemaId,
                                 p_scratchConn);
    -- Make md_derivatives entry only for the following objects -- begin 
    createTableEntry(schemaId, new_schemaId, p_scratchConn);
    createConstraintEntry(schemaId, new_schemaId, p_scratchConn);    
    -- Make md_derivatives entry only for the following objects -- end

    --This create scratch model for view triggers as well                                 
    copy_all_views_ee(schemaId, 
                   new_schemaId,
                   p_scratchConn);

    copy_all_unpackaged_sps_ee(schemaId, 
                 new_schemaId,
                 p_scratchConn);                                    
END copy_schema_objects_ee;

-- p_connectionid -- scratch model connection id
PROCEDURE copy_catalogs_cascade_ee(p_connectionid MD_CONNECTIONS.ID%TYPE)
IS
   CURSOR curDerivatives(conId MD_CONNECTIONS."ID"%TYPE) IS
                SELECT *
                       FROM MD_DERIVATIVES 
                       WHERE DERIVED_CONNECTION_ID_FK = conId
                       AND SRC_TYPE = C_OBJECTTYPE_CATALOGS;
   recDerived MD_DERIVATIVES%ROWTYPE;

   CURSOR curSchemas(catId MD_SCHEMAS.CATALOG_ID_FK%TYPE) IS
                SELECT * FROM MD_SCHEMAS WHERE CATALOG_ID_FK = catId;
   recSchema MD_SCHEMAS%ROWTYPE;

   ncatId MD_SCHEMAS.CATALOG_ID_FK%TYPE;
   n_newschId MD_SCHEMAS."ID"%TYPE;
   v_ret NUMBER;
   v_catalogdummy MD_CATALOGS.DUMMY_FLAG%TYPE;
   v_catalogname VARCHAR2(300);
   v_newName VARCHAR2(300); 
BEGIN
   OPEN curDerivatives(p_connectionid);
   FETCH curDerivatives INTO recDerived;
   LOOP -- for each of the catalog process its schemas
      EXIT WHEN curDerivatives%NOTFOUND;
      SELECT /* APEXa213de */  dummy_flag, catalog_name INTO v_catalogdummy, v_catalogname FROM MD_CATALOGS WHERE "ID" = recDerived.src_id;
      ncatId := recDerived.src_id;
      OPEN curSchemas(ncatId);
      FETCH curSchemas INTO recSchema;
      LOOP
         EXIT WHEN curSchemas%NOTFOUND;

         v_newName := CREATE_SCHEMANAME(recSchema."NAME",v_catalogname);

         INSERT /* APEXc5ddfb */  INTO MD_SCHEMAS(CATALOG_ID_FK, "NAME", "TYPE", CHARACTER_SET, VERSION_TAG)
                          VALUES (recDerived.derived_id, 
                                  v_newName, 
                                  recSchema."TYPE",
                                  recSchema.CHARACTER_SET, 
                                  recSchema.VERSION_TAG)
                          RETURNING "ID" INTO n_newschId;
         v_ret := copy_additional_properties(ncatId, n_newschId, p_connectionid);                          
         v_ret := copy_additional_properties(recSchema."ID", n_newschId, p_connectionid);

	       -- No Need for namespace stuff for catalogs.
         INSERT /* APEXbc229f */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK,
               ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
                   VALUES (recSchema."ID", C_OBJECTTYPE_SCHEMAS, n_newschId, C_OBJECTTYPE_SCHEMAS, p_connectionid, recSchema."NAME", v_newName);

         INSERT /* APEX3b1b2b */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER)
                   VALUES (recDerived.src_id, C_OBJECTTYPE_CATALOGS, n_newschId, C_OBJECTTYPE_SCHEMAS, p_connectionid, v_catalogname, v_newName);         

         copy_schema_objects_ee(recSchema."ID", n_newschId, p_connectionId);
         FETCH curSchemas INTO recSchema;
      END LOOP; -- end schema loop
      CLOSE curSchemas;

      FETCH curDerivatives INTO recDerived;
   END LOOP;  -- end catalog loop
   CLOSE curDerivatives;
END copy_catalogs_cascade_ee;

FUNCTION copy_connection_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL, p_scratchModel BOOLEAN := FALSE) RETURN NUMBER
IS
  v_newConnectionId MD_CONNECTIONS.ID%TYPE;
  v_numProps NUMBER;
  v_catalogId MD_CATALOGS.ID%TYPE;
  v_catalogName MD_CATALOGS.CATALOG_NAME%TYPE;
  v_numCatalogs NUMBER;
  v_numDuplicateIndexes NUMBER;
  v_sql VARCHAR(255);   

  CURSOR curDerivatives(conId MD_CONNECTIONS."ID"%TYPE) IS
                SELECT distinct 
                           id,
                           src_id,
                           src_type,
                           derived_id,
                           derived_type,
                           derived_connection_id_fk,
                           transformed,
                           original_identifier,
                           new_identifier,
                           derived_object_namespace,
                           derivative_reason,
                           security_group_id,
                           created_on,
                           created_by,
                           last_updated_on,
                           last_updated_by,
                           enabled
                       FROM MD_DERIVATIVES 
                       WHERE DERIVED_CONNECTION_ID_FK = conId
                       AND SRC_TYPE = C_OBJECTTYPE_CATALOGS;

   recDerived MD_DERIVATIVES%ROWTYPE;


BEGIN

  --DROP ANY EXISTING CONVERTED MODEL, AS WE ONLY HAVE A ONE TO ONE RELATIONSHIP WITH CAPTURED AND CONVERTED MODELS NOW
  DELETE /* APEXaa078e */  FROM Md_Connections C 
  WHERE C.Type = 'CONVERTED' --only want to delete CONVERTED MODELS
  AND C.Id IN ( -- delete all converted models associated with this captured model
  SELECT d.derived_id FROM md_derivatives d WHERE d.src_id =  p_connectionid
  );

  -- The connection doesn't use the filter, because it is called for a single connection.
  v_newConnectionId := copy_connection(p_connectionid, p_scratchModel);
  -- Don't forget its additional props
  v_numProps := copy_additional_properties(p_connectionid, v_newConnectionId, v_newConnectionId);
  -- OK - Next coalesce the schema/catalogs

  IF p_scratchModel = FALSE 
  THEN
      --v_catalogId := create_dummy_catalog(v_newConnectionId);
      --select CATALOG_NAME INTO v_catalogName FROM MD_CATALOGS WHERE CONNECTION_ID_FK = p_connectionid;
      --v_sql := 'UPDATE MD_CATALOGS SET CATALOG_NAME = ''' || v_catalogName  || ''' WHERE ID = ' || TO_CHAR(v_catalogId);
      --EXECUTE IMMEDIATE v_sql;
      create_dummy_catalogs(p_connectionid, v_newConnectionId, FALSE);

      OPEN curDerivatives(v_newConnectionId);

      LOOP
            FETCH curDerivatives INTO recDerived;
            EXIT WHEN curDerivatives%NOTFOUND;
           --v_numCatalogs := copy_catalogs_cascade(p_connectionid, v_catalogid, v_newConnectionId, p_filter_set);
           v_numCatalogs := copy_catalogs_cascade(p_connectionid, recDerived.src_id, recDerived.derived_id, v_newConnectionId, p_filter_set);
           --FETCH curDerivatives INTO recDerived;
      END LOOP;
      CLOSE curDerivatives;
      v_numDuplicateIndexes := remove_duplicate_indexes(v_newConnectionId);
      v_numDuplicateIndexes := v_numDuplicateIndexes + remove_indexes_used_elsewhere(v_newConnectionId);
  ELSE -- enterprise capture
      create_dummy_catalogs(p_connectionid, v_newConnectionId, TRUE);
      copy_catalogs_cascade_ee(v_newConnectionId);
  END IF;
  COMMIT;
  return v_newConnectionId;
END copy_connection_cascade;

PROCEDURE update_derivative_record(p_orig VARCHAR2, p_new VARCHAR2, p_derivedid MD_DERIVATIVES.DERIVED_ID%TYPE,
p_derivedtype MD_DERIVATIVES.DERIVED_TYPE%TYPE, p_connectionid MD_DERIVATIVES.DERIVED_CONNECTION_ID_FK%TYPE)
IS	
BEGIN
    UPDATE /* APEX46913a */  MD_DERIVATIVES SET TRANSFORMED = C_TRANSFORMED_TRUE, ORIGINAL_IDENTIFIER = p_orig, NEW_IDENTIFIER = p_new
      WHERE DERIVED_ID = p_derivedid
      AND DERIVED_TYPE = p_derivedtype
      AND DERIVED_CONNECTION_ID_FK = p_connectionid;
END update_derivative_record;

/*
 * This procedure is like update_derivative_record except it should be used at name clash stage
 * basically, this will work the same as update_derivative_record except in those cases where
 * there is already a derivative record.  In this latter case, we want ORIGINAL_IDENTIFIER preserved
 * (this is called when there is a possiblity that we've carried out a second transformation
 */
PROCEDURE second_update_derivative(p_orig VARCHAR2, p_new VARCHAR2, p_derivedid MD_DERIVATIVES.DERIVED_ID%TYPE,
p_derivedtype MD_DERIVATIVES.DERIVED_TYPE%TYPE, p_connectionid MD_DERIVATIVES.DERIVED_CONNECTION_ID_FK%TYPE)
IS
  v_firstOriginal MD_DERIVATIVES.ORIGINAL_IDENTIFIER%TYPE;
BEGIN
  -- see if p_orig is already the new identifier
  select /* APEX3d4c8f */  ORIGINAL_IDENTIFIER INTO v_firstOriginal FROM MD_DERIVATIVES
      WHERE DERIVED_ID = p_derivedid
      AND DERIVED_TYPE = p_derivedtype
      AND NEW_IDENTIFIER = p_orig
      AND DERIVED_CONNECTION_ID_FK = p_connectionid;
  if v_firstOriginal IS NULL then
    update_derivative_record(p_orig, p_new, p_derivedid, p_derivedtype, p_connectionid);
  else
    update_derivative_record(v_firstOriginal, p_new, p_derivedid, p_derivedtype, p_connectionid);
  end if;
EXCEPTION
  when NO_DATA_FOUND THEN
    update_derivative_record(p_orig, p_new, p_derivedid, p_derivedtype, p_connectionid);
  WHEN TOO_MANY_ROWS THEN
    dbms_output.put_line(TO_CHAR(p_derivedid) || ' ' || TO_CHAR(p_derivedtype) || ' '|| TO_CHAR(p_connectionid));

END second_update_derivative;

FUNCTION transform_column_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                 p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
    SELECT * FROM MD_COLUMNS
    WHERE TABLE_ID_FK IN
    (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = connid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(COLUMN_NAME) != COLUMN_NAME 
    FOR UPDATE OF COLUMN_NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
    SELECT c.*, d.NEW_IDENTIFIER FROM MD_COLUMNS c, MD_DERIVATIVES d
    WHERE (c.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
       WHERE SRC_TYPE= C_OBJECTTYPE_COLUMNS AND DERIVED_CONNECTION_ID_FK = connid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(d.NEW_IDENTIFIER) != COLUMN_NAME
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH
    FOR UPDATE OF COLUMN_NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.COLUMN_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_COLUMNS, p_connectionid);    
    IF p_scratchModel = FALSE -- Update md_columns only for non migration estimation models
    THEN
        UPDATE /* APEXb1b33a */  MD_COLUMNS SET COLUMN_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_COLUMNS, v_count);
  --return v_count;
END transform_column_identifiers;

FUNCTION transform_constraint_idents(p_connectionid MD_CONNECTIONS.ID%TYPE, 
                                     p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_CONSTRAINTS
  WHERE TABLE_ID_FK IN
    (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = connid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT c.*, d.NEW_IDENTIFIER FROM MD_CONSTRAINTS c, MD_DERIVATIVES d
  WHERE (c.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
       WHERE SRC_TYPE = C_OBJECTTYPE_CONSTRAINTS AND DERIVED_CONNECTION_ID_FK = connid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(d.NEW_IDENTIFIER) != c.NAME
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH 
    FOR UPDATE OF NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_CONSTRAINTS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN    
       UPDATE /* APEXf3bef4 */  MD_CONSTRAINTS SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_CONSTRAINTS, v_count);
END transform_constraint_idents;

FUNCTION transform_group_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                          p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_GROUPS WHERE
   SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(GROUP_NAME) != GROUP_NAME
    FOR UPDATE OF GROUP_NAME;
*/    

  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_GROUPS WHERE
   ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES 
       WHERE SRC_TYPE = C_OBJECTTYPE_GROUPS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(GROUP_NAME) != GROUP_NAME
    FOR UPDATE OF GROUP_NAME;
  v_rec MD_GROUPS%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_rec.GROUP_NAME);

    update_derivative_record(v_rec.GROUP_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_GROUPS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN    
       UPDATE /* APEX09ecb8 */  MD_GROUPS SET GROUP_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_GROUPS, v_count);
END transform_group_identifiers;

FUNCTION transform_index_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_INDEXES WHERE TABLE_ID_FK IN
    (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||INDEX_NAME) != INDEX_NAME
    FOR UPDATE OF INDEX_NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT i.*, d.NEW_IDENTIFIER FROM MD_INDEXES i, MD_DERIVATIVES d WHERE (i.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE = C_OBJECTTYPE_INDEXES AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||d.NEW_IDENTIFIER) != i.INDEX_NAME
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH 
    FOR UPDATE OF INDEX_NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.INDEX_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_INDEXES, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN    
        UPDATE /* APEXc5eeb3 */  MD_INDEXES SET INDEX_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  commit;
  CLOSE v_curs;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_INDEXES, v_count);
END transform_index_identifiers;

FUNCTION transform_othobj_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                          p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_OTHER_OBJECTS  WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_OTHER_OBJECTS  WHERE ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE = C_OBJECTTYPE_OTHER_OBJECTS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
  v_rec MD_OTHER_OBJECTS%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NAME);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_OTHER_OBJECTS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEXb71a65 */  MD_OTHER_OBJECTS SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_OTHER_OBJECTS, v_count);
END transform_othobj_identifiers;

FUNCTION transform_package_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                        p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_PACKAGES  WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_PACKAGES  WHERE ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES 
    WHERE SRC_TYPE = C_OBJECTTYPE_PACKAGES AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
  v_rec MD_PACKAGES%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NAME);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_PACKAGES, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX7aeacf */  MD_PACKAGES SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_PACKAGES, v_count);
END transform_package_identifiers;

FUNCTION transform_schema_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                         p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_SCHEMAS WHERE ID IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT s.*, d.NEW_IDENTIFIER FROM MD_SCHEMAS s, MD_DERIVATIVES d WHERE (s.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE = C_OBJECTTYPE_SCHEMAS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(d.NEW_IDENTIFIER) != NAME 
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH 
    FOR UPDATE OF NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName:= MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_SCHEMAS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX29798d */  MD_SCHEMAS SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_SCHEMAS, v_count);
END transform_schema_identifiers;

FUNCTION transform_sequence_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                           p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_SEQUENCES WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT s.*, d.NEW_IDENTIFIER FROM MD_SEQUENCES s, MD_DERIVATIVES d WHERE (s.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE = C_OBJECTTYPE_SEQUENCES AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||d.NEW_IDENTIFIER) != NAME
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH
    FOR UPDATE OF NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_SEQUENCES, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEXb2479c */  MD_SEQUENCES SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_SEQUENCES, v_count);
END transform_sequence_identifiers;

FUNCTION transform_sproc_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                         p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_STORED_PROGRAMS WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT sp.*, d.NEW_IDENTIFIER FROM MD_STORED_PROGRAMS sp, MD_DERIVATIVES d WHERE (sp.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = C_OBJECTTYPE_STORED_PROGRAMS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||d.NEW_IDENTIFIER) != sp.NAME 
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH 
    FOR UPDATE OF NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_STORED_PROGRAMS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX62fa1b */  MD_STORED_PROGRAMS SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_STORED_PROGRAMS, v_count);
END transform_sproc_identifiers;

FUNCTION transform_synonym_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                       p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_SYNONYMS WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_SYNONYMS WHERE ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES 
       WHERE SRC_TYPE =  C_OBJECTTYPE_SYNONYMS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||NAME) != NAME
    FOR UPDATE OF NAME;
  v_rec MD_SYNONYMS%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NAME);

    update_derivative_record(v_rec.NAME, v_newName, v_rec.ID, C_OBJECTTYPE_SYNONYMS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX294351 */  MD_SYNONYMS SET NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_SYNONYMS, v_count);
END transform_synonym_identifiers;

FUNCTION transform_table_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_TABLES WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||TABLE_NAME) != TABLE_NAME
    FOR UPDATE OF TABLE_NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT t.*, d.NEW_IDENTIFIER FROM MD_TABLES t, MD_DERIVATIVES d WHERE (t.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE = C_OBJECTTYPE_TABLES AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||d.NEW_IDENTIFIER) != TABLE_NAME 
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH 
    FOR UPDATE OF TABLE_NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.TABLE_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_TABLES, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX2d2098 */  MD_TABLES SET TABLE_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_TABLES, v_count);
END transform_table_identifiers;

FUNCTION transform_view_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_VIEWS WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||VIEW_NAME) != VIEW_NAME
    FOR UPDATE OF VIEW_NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT v.*, d.NEW_IDENTIFIER FROM MD_VIEWS v, MD_DERIVATIVES d WHERE (v.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = C_OBJECTTYPE_VIEWS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||d.NEW_IDENTIFIER) != VIEW_NAME
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH 
    FOR UPDATE OF VIEW_NAME;
  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.VIEW_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_VIEWS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEXba7a16 */  MD_VIEWS SET VIEW_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_VIEWS, v_count);
END transform_view_identifiers;

FUNCTION transform_tablespace_idents(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_TABLESPACES WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(TABLESPACE_NAME) != TABLESPACE_NAME
    FOR UPDATE OF TABLESPACE_NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_TABLESPACES WHERE ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE = C_OBJECTTYPE_TABLESPACES AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(TABLESPACE_NAME) != TABLESPACE_NAME
    FOR UPDATE OF TABLESPACE_NAME;
  v_rec MD_TABLESPACES%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_rec.TABLESPACE_NAME);

    update_derivative_record(v_rec.TABLESPACE_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_TABLESPACES, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEXf7e330 */  MD_TABLESPACES SET TABLESPACE_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_TABLESPACES, v_count);
END transform_tablespace_idents;

FUNCTION transform_trigger_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                       p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs IS 
  SELECT * FROM MD_TRIGGERS  WHERE TABLE_OR_VIEW_ID_FK IN
    (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||TRIGGER_NAME) != TRIGGER_NAME
    FOR UPDATE OF TRIGGER_NAME;
  CURSOR v_view_trigger_curs IS 
    SELECT * FROM MD_TRIGGERS  WHERE TABLE_OR_VIEW_ID_FK IN
    (SELECT VIEW_ID FROM MGV_ALL_VIEWS WHERE CONNECTION_ID =  p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||TRIGGER_NAME) != TRIGGER_NAME
    FOR UPDATE OF TRIGGER_NAME;
*/    
  CURSOR v_curs IS 
  SELECT t.*, d.NEW_IDENTIFIER FROM MD_TRIGGERS t, MD_DERIVATIVES d WHERE (t.ID, d.SRC_ID) IN
    (SELECT DERIVED_ID, SRC_ID FROM MD_DERIVATIVES 
      WHERE SRC_TYPE =  C_OBJECTTYPE_TRIGGERS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||d.NEW_IDENTIFIER) != t.TRIGGER_NAME
    AND d.DERIVATIVE_REASON = C_CONNECTIONTYPE_SCRATCH
    FOR UPDATE OF TRIGGER_NAME;

  v_rec v_curs%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs;
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.NEW_IDENTIFIER);

    update_derivative_record(v_rec.TRIGGER_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_TRIGGERS, p_connectionid);
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX1343ad */  MD_TRIGGERS SET TRIGGER_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;       

  END LOOP;
  CLOSE v_curs;
  /*
  OPEN v_view_trigger_curs;
  LOOP
    FETCH v_view_trigger_curs INTO v_rec;
    EXIT WHEN v_view_trigger_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.TRIGGER_NAME);

    IF p_scratchModel = FALSE
    THEN        
       UPDATE MD_TRIGGERS SET TRIGGER_NAME = v_newName WHERE CURRENT OF v_view_trigger_curs;
    END IF;

    update_derivative_record(v_rec.TRIGGER_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_TRIGGERS, p_connectionid);
  END LOOP;
  CLOSE v_view_trigger_curs;
  */
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_TRIGGERS, v_count);
END transform_trigger_identifiers;

FUNCTION transform_uddt_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                      p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_USER_DEFINED_DATA_TYPES WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||DATA_TYPE_NAME) != DATA_TYPE_NAME
    FOR UPDATE OF DATA_TYPE_NAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_USER_DEFINED_DATA_TYPES WHERE ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = C_OBJECTTYPE_UDDT AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||DATA_TYPE_NAME) != DATA_TYPE_NAME
    FOR UPDATE OF DATA_TYPE_NAME;
  v_rec MD_USER_DEFINED_DATA_TYPES%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_prefixName||v_rec.DATA_TYPE_NAME);

    update_derivative_record(v_rec.DATA_TYPE_NAME, v_newName, v_rec.ID, C_OBJECTTYPE_UDDT, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEX656142 */  MD_USER_DEFINED_DATA_TYPES SET DATA_TYPE_NAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_UDDT, v_count);
END transform_uddt_identifiers;

FUNCTION transform_user_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                    p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_T
IS
/*
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_USERS WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(USERNAME) != USERNAME
    FOR UPDATE OF USERNAME;
*/    
  CURSOR v_curs(connid MD_CONNECTIONS.ID%TYPE) IS 
  SELECT * FROM MD_USERS WHERE ID IN
    (SELECT DERIVED_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = C_OBJECTTYPE_USERS AND DERIVED_CONNECTION_ID_FK = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(USERNAME) != USERNAME
    FOR UPDATE OF USERNAME;
  v_rec MD_USERS%ROWTYPE;
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_T;
  v_newName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
BEGIN
  OPEN v_curs(p_connectionid);
  LOOP
    FETCH v_curs INTO v_rec;
    EXIT WHEN v_curs%NOTFOUND;
    v_count := v_count + 1;
    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_rec.USERNAME);

    update_derivative_record(v_rec.USERNAME, v_newName, v_rec.ID, C_OBJECTTYPE_USERS, p_connectionid);    
    IF p_scratchModel = FALSE
    THEN        
       UPDATE /* APEXf2ee88 */  MD_USERS SET USERNAME = v_newName WHERE CURRENT OF v_curs;
    END IF;

  END LOOP;
  CLOSE v_curs;
  commit;
  return NAME_AND_COUNT_T(C_OBJECTTYPE_USERS, v_count);
END transform_user_identifiers;

PROCEDURE rename_duplicate_index_names(p_connectionid MD_CONNECTIONS.ID%TYPE, p_scratchModel BOOLEAN := FALSE)
IS
    CURSOR v_curs IS
    select * from md_derivatives a 
          where a.derived_connection_id_fk = p_connectionid
                and 1 < (select count(*) 
                          from md_derivatives b 
                              where a.new_identifier = b.new_identifier 
                                  and a.derived_type='MD_INDEXES'
                                      and a.derived_connection_id_fk = b.derived_connection_id_fk)
                                      order by new_identifier;

  v_row MD_DERIVATIVES%ROWTYPE;
  v_newName MD_INDEXES.INDEX_NAME%TYPE;

  v_id MD_DERIVATIVES.DERIVED_ID%TYPE;

  v_curName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
  v_count NUMBER := 1;
  v_maxIdentLen NUMBER := 30;
BEGIN
  v_curName := 'dsa;lkjsd;alskj;';
  v_maxIdentLen := MIGRATION_TRANSFORMER.GET_ORACLE_LONG_IDENTIFIER();
  OPEN v_curs;
  LOOP
    FETCH v_curs INTO v_row;
    EXIT WHEN v_curs%NOTFOUND;


   IF UPPER(v_row.NEW_IDENTIFIER) = UPPER(v_curName) THEN
      v_newName := MIGRATION_TRANSFORMER.ADD_SUFFIX(v_row.NEW_IDENTIFIER, '_' || TO_CHAR(v_count), v_maxIdentLen);
      v_count := v_count + 1;

      if p_scratchModel = FALSE
      THEN
         update /* APEX6007dc */  MD_INDEXES SET index_name = v_newName where id = v_row.DERIVED_ID;
      END IF;
      second_update_derivative(v_row.NEW_IDENTIFIER, v_newName, v_row.DERIVED_ID, C_OBJECTTYPE_INDEXES, p_connectionid);
    else
      v_curName := v_row.NEW_IDENTIFIER;
      v_count := 1;
    END IF;
  END LOOP;
  CLOSE v_curs;
  commit;
END rename_duplicate_index_names;

PROCEDURE fixup_duplicate_identifier(p_connectionid MD_CONNECTIONS.ID%TYPE, 
                                      p_mdrec_id MD_DERIVATIVES.ID%TYPE,
                                      p_derived_type MD_DERIVATIVES.DERIVED_TYPE%TYPE,
                                      p_derived_id MD_DERIVATIVES.DERIVED_ID%TYPE,
                                      p_new_identifier MD_DERIVATIVES.NEW_IDENTIFIER%TYPE,
                                      p_suffix INTEGER, 
                                      p_scratchModel BOOLEAN := FALSE)
IS
	v_transform_identifier MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
	v_did_a_transform CHAR(1) := 'Y';
	v_maxIdentLen NUMBER := 30;
	--v_underscoresuffixsize NUMBER;
	--v_underscoresuffix VARCHAR2(100);
  --v_sizebeforeprefix NUMBER;
BEGIN
  --v_underscoresuffix := '_' || TO_CHAR(p_suffix);
  --v_underscoresuffixsize := LENGTH(v_underscoresuffix);
  --v_sizebeforeprefix := 30 - v_underscoresuffixsize;
  v_maxIdentLen := MIGRATION_TRANSFORMER.GET_ORACLE_LONG_IDENTIFIER();
  v_transform_identifier := MIGRATION_TRANSFORMER.ADD_SUFFIX(p_new_identifier, '_' || TO_CHAR(p_suffix) , v_maxIdentLen);

  IF p_scratchModel = FALSE
  THEN
     CASE p_derived_type
      WHEN C_OBJECTTYPE_CONNECTIONS THEN
        UPDATE /* APEXe75c92 */  MD_CONNECTIONS SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_CATALOGS THEN
        UPDATE /* APEX9d59e6 */  MD_CATALOGS SET CATALOG_NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_SCHEMAS THEN
        UPDATE /* APEXf18c9c */  MD_SCHEMAS SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_TABLES THEN
        UPDATE /* APEX4e4a3a */  MD_TABLES SET TABLE_NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_CONSTRAINTS THEN
        UPDATE /* APEXacb055 */  MD_CONSTRAINTS SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_INDEXES THEN
        UPDATE /* APEX9a6ec3 */  MD_INDEXES SET INDEX_NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_TRIGGERS THEN
        UPDATE /* APEXbfe20a */  MD_TRIGGERS SET TRIGGER_NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_VIEWS THEN
        UPDATE /* APEXf05c07 */  MD_VIEWS SET VIEW_NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_USERS THEN
        UPDATE /* APEX21fb2b */  MD_USERS SET USERNAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_GROUPS THEN
        UPDATE /* APEX3bb2ec */  MD_GROUPS SET GROUP_NAME  = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_OTHER_OBJECTS THEN
        UPDATE /* APEXee949f */  MD_OTHER_OBJECTS SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_TABLESPACES THEN
        UPDATE /* APEX601b91 */  MD_TABLESPACES SET TABLESPACE_NAME  = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_UDDT THEN
        UPDATE /* APEXa954ee */  MD_USER_DEFINED_DATA_TYPES SET DATA_TYPE_NAME  = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_STORED_PROGRAMS THEN
        UPDATE /* APEX58551f */  MD_STORED_PROGRAMS SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_PACKAGES THEN
        UPDATE /* APEX4639d1 */  MD_PACKAGES SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_SYNONYMS THEN
        UPDATE /* APEXa96fbb */  MD_SYNONYMS SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      WHEN C_OBJECTTYPE_SEQUENCES THEN
        UPDATE /* APEX9aa6b2 */  MD_SEQUENCES SET NAME = v_transform_identifier WHERE ID = p_derived_id;
      ELSE
        -- Handle column namespace here.
        IF SUBSTR(P_DERIVED_TYPE,1, LENGTH(C_OBJECTTYPE_COLUMNS)) = C_OBJECTTYPE_COLUMNS THEN
          UPDATE /* APEXb3a512 */  MD_COLUMNS SET COLUMN_NAME = v_transform_identifier WHERE ID = p_derived_id;
        ELSE
          v_did_a_transform := 'N';
        END IF;
      END CASE;
  END IF; -- end if scratch model

	IF v_did_a_transform = 'Y' THEN
	  UPDATE /* APEX247405 */  MD_DERIVATIVES SET NEW_IDENTIFIER = v_transform_identifier WHERE ID = p_mdrec_id;
	  commit;
    END IF;
    commit;
END fixup_duplicate_identifier;

FUNCTION getClashCount(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN INTEGER 
IS
  v_clashCount INTEGER;
BEGIN
  SELECT /* APEXf4178c */  COUNT(*) INTO v_clashCount FROM md_derivatives a
    where rowid > (
      select min(rowid) from md_derivatives b
      where
        b.derived_connection_id_fk = p_connectionid
        AND b.derived_connection_id_fk = a.derived_connection_id_fk
        AND UPPER(b.new_identifier) = UPPER(a.new_identifier)--  Uppercasing the name so that case sensitve names are caught (see bug 6922052)
        AND b.derived_object_namespace = a.derived_object_namespace);
  RETURN v_clashCount;
END getClashCount;

PROCEDURE transform_clashes(p_connectionid MD_CONNECTIONS.ID%TYPE, p_scratchModel BOOLEAN := FALSE)
IS
  CURSOR v_curs IS
    select id,derived_type, derived_id, UPPER(new_identifier) --  Uppercasing the name so that case sensitve names are caught (see bug 6922052)
    from md_derivatives a
    where rowid > (
      select min(rowid) from md_derivatives b
      where
        b.derived_connection_id_fk = p_connectionid
        AND b.derived_connection_id_fk = a.derived_connection_id_fk
        AND UPPER(b.new_identifier) = UPPER(a.new_identifier) --  Uppercasing the name so that case sensitve names are caught (see bug 6922052)
        AND b.derived_object_namespace = a.derived_object_namespace)
        ORDER BY new_identifier, derived_type;
  v_derived_type MD_DERIVATIVES.DERIVED_TYPE%TYPE;
  v_curr_type v_derived_type%TYPE := '~~dasdddfl;';
  v_derived_id MD_DERIVATIVES.DERIVED_ID%TYPE;
  v_new_identifier MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
  v_curr_identifier v_new_identifier%TYPE := '~~~~asdasnc';
  v_suffix INTEGER := 0;
  v_innerSuffix INTEGER;
  v_clashCount INTEGER;
  v_mdrec_id MD_DERIVATIVES.ID%TYPE;
BEGIN

  rename_duplicate_index_names(p_connectionid, p_scratchModel);

  v_clashCount := getClashCount(p_connectionid);
  WHILE v_clashCount > 0 
  LOOP
	v_suffix := v_suffix + 1;
	v_innerSuffix := v_suffix; 
    -- Now lets see if there are any identifier clashes
    OPEN v_curs;
    LOOP 
      FETCH v_curs into v_mdrec_id, v_derived_type, v_derived_id, v_new_identifier;
      EXIT WHEN v_curs%NOTFOUND;
 	  IF v_derived_type = v_curr_type AND v_new_identifier = v_curr_identifier THEN
		  v_innerSuffix := v_innerSuffix + 1;
	  else
		  v_curr_type := v_derived_type;
		  v_curr_identifier := v_new_identifier;
	  END IF;
      -- We have to fix up all of these identifiers
      fixup_duplicate_identifier(p_connectionid, v_mdrec_id, v_derived_type, v_derived_id, v_new_identifier, v_innerSuffix, p_scratchModel);
    END LOOP;
	CLOSE v_curs;
    v_clashCount := getClashCount(p_connectionid);
  END LOOP;
END transform_clashes;

FUNCTION getDuplicateIdentifierID(p_connectionid MD_CONNECTIONS.ID%TYPE, v_duplicateIdentifier md_derivatives.new_identifier%TYPE) RETURN NUMBER 
IS 
  v_md_derivative_id NUMBER;
BEGIN
 select a.id into v_md_derivative_id from md_derivatives a, mgv_all_details m
      where
        a.derived_connection_id_fk = p_connectionid    
         AND m.objname = a.original_identifier
         and a.derived_connection_id_fk = m.connid
         and m.capturedorconverted = 'CONVERTED'
          AND m.objtype = a.derived_type 
        and m.objid = a.derived_id 
        AND a.original_identifier = v_duplicateIdentifier
        and a.derived_type not in ('MD_COLUMNS')
        and rownum = 1;
return v_md_derivative_id;
end getDuplicateIdentifierID;

FUNCTION isDuplicateIdentifier(p_connectionid MD_CONNECTIONS.ID%TYPE, v_duplicateIdentifier md_derivatives.new_identifier%TYPE) RETURN CHAR 
IS 
  v_recordExists CHAR;
BEGIN

 select case 
            when exists (select 1 
                         from md_derivatives a, mgv_all_details m 
                         where a.new_identifier = v_duplicateIdentifier and a.derived_connection_id_fk = p_connectionid    
         AND m.objname = a.original_identifier
         and a.derived_connection_id_fk = m.connid
         and m.capturedorconverted = 'CONVERTED'
        and a.derived_type not in ('MD_COLUMNS') )
            then 'Y' 
            else 'N' 
        end as rec_exists
into v_recordExists from dual;
return v_recordExists;
end isDuplicateIdentifier;


PROCEDURE remove_duplicate_id_objecttype(p_connectionid MD_CONNECTIONS.ID%TYPE, p_scratchModel BOOLEAN := FALSE)
IS
CURSOR v_duplicateIdentifier_cur
  IS SELECT New_identifier FROM (
select a.new_identifier,a.DERIVED_OBJECT_NAMESPACE from md_derivatives a, mgv_all_details m
      where
        a.derived_connection_id_fk = p_connectionid
         AND m.objname = a.original_identifier
         and a.derived_connection_id_fk = m.connid
         and m.capturedorconverted = 'CONVERTED'
          AND m.objtype = a.derived_type
        and m.objid = a.derived_id
        and a.derived_type not in ('MD_COLUMNS')
       GROUP BY a.new_identifier,a.DERIVED_OBJECT_NAMESPACE
       HAVING COUNT(*) > 1)X ;

  v_duplicateIdentifier md_derivatives.new_identifier%TYPE;
  v_transform_identifier MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
  v_derived_type MD_DERIVATIVES.DERIVED_TYPE%TYPE;
  v_derived_id MD_DERIVATIVES.DERIVED_ID%TYPE;

  v_recordExists CHAR(1) := 'N';
  v_suffix INTEGER := 0;
  p_mdrec_id NUMBER := 0;
  v_mdDerivativeRow MD_DERIVATIVES%ROWTYPE;
  v_maxIdentLen NUMBER := 30;

BEGIN
  v_maxIdentLen := MIGRATION_TRANSFORMER.GET_ORACLE_LONG_IDENTIFIER();
  OPEN v_duplicateIdentifier_cur;
  FETCH v_duplicateIdentifier_cur INTO v_duplicateIdentifier;
  LOOP
    EXIT WHEN v_duplicateIdentifier_cur%NOTFOUND;
       LOOP
       v_suffix := v_suffix + 1;
       v_transform_identifier := MIGRATION_TRANSFORMER.ADD_SUFFIX(v_duplicateIdentifier, '_' || TO_CHAR(v_suffix) , v_maxIdentLen);
       v_recordExists := isDuplicateIdentifier(p_connectionid, v_transform_identifier);
       exit when v_recordExists = 'N';
       END LOOP;    
       p_mdrec_id := getDuplicateIdentifierID(p_connectionid, v_duplicateIdentifier);

       SELECT * INTO v_mdDerivativeRow from MD_DERIVATIVES WHERE "ID" = p_mdrec_id;     
       v_derived_type := v_mdDerivativeRow.DERIVED_TYPE;
       v_derived_id := v_mdDerivativeRow.DERIVED_ID;

       fixup_duplicate_identifier(p_connectionid, p_mdrec_id, v_derived_type, v_derived_id, v_duplicateIdentifier, v_suffix, p_scratchModel);         
       v_suffix := 0;

    FETCH v_duplicateIdentifier_cur INTO v_duplicateIdentifier;
  END LOOP;
  CLOSE v_duplicateIdentifier_cur;
  COMMIT;
END remove_duplicate_id_objecttype;

FUNCTION transform_all_identifiers_x(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                             p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_ARRAY
IS
  v_count INTEGER := 0;
  v_ret NAME_AND_COUNT_ARRAY;
  v_rec NAME_AND_COUNT_T;
BEGIN
  v_ret := NAME_AND_COUNT_ARRAY();
  -- We need to update identifiers on pretty much the whole schema
  -- MD_COLUMNS
  v_rec := transform_column_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');

  -- MD_CONSTRAINTS
  v_rec := transform_constraint_idents(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_GROUPS
  v_rec := transform_group_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_INDEXES
  v_rec := transform_index_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_OTHER_OBJECTS
  v_rec := transform_othobj_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_PACKAGES
  v_rec := transform_package_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_SCHEMAS
  v_rec := transform_schema_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_SEQUENCES
  v_rec := transform_sequence_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_STORED_PROGRAMS
  v_rec := transform_sproc_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_SYNONYMS
  v_rec := transform_synonym_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_TABLES
  v_rec := transform_table_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_TABLESPACES
  v_rec := transform_tablespace_idents(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_TRIGGERS
  v_rec := transform_trigger_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_USER_DEFINED_DATA_TYPES
  v_rec := transform_uddt_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  -- MD_USERS
  v_rec := transform_user_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  /*
  UPDATE MD_USERS SET USERNAME = MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(USERNAME) WHERE SCHEMA_ID_FK IN
    (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionid)
    AND MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(USERNAME) != USERNAME;
  dbms_output.put_line(SQL%ROWCOUNT || ' USER names updated');
  */
  -- MD_VIEWS
  v_rec := transform_view_identifiers(p_connectionid, p_scratchModel);
  v_ret.EXTEND;
  v_ret(v_ret.count) := v_rec;
  dbms_output.put_line(v_rec.UPDATE_COUNT || v_rec.OBJECT_NAME || ' names udpates');
  transform_clashes(p_connectionid, p_scratchModel);
  -- TODO: Something meaningful if all goes wrong

  -- The following call will remove Duplicate Identifiers across the all objects types
  remove_duplicate_id_objecttype(p_connectionid, p_scratchModel); 

  return v_ret;
  COMMIT;
END transform_all_identifiers_x;

FUNCTION transform_all_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE, p_prefixName VARCHAR2, p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_ARRAY
IS
BEGIN
v_prefixName := p_prefixName;
RETURN  transform_all_identifiers_x(p_connectionid, p_scratchModel);
END transform_all_identifiers;

FUNCTION rule_specificity(p_precision MIGR_DATATYPE_TRANSFORM_RULE.SOURCE_PRECISION%TYPE, p_scale MIGR_DATATYPE_TRANSFORM_RULE.SOURCE_SCALE%TYPE) RETURN INTEGER
IS
BEGIN
  IF p_precision is NULL then 
    return 1;
  END IF;
  IF p_scale is NULL then
    return 2;
  END IF;
  return 3;
END rule_specificity;

FUNCTION addToWhereClause(p_whereclause VARCHAR2, p_toAdd VARCHAR2) return VARCHAR2
IS
BEGIN
  IF p_whereclause is NULL then
    return p_toAdd;
  else
    return p_whereclause || ' AND ' || p_toAdd;
  END IF;
END addToWhereClause;

FUNCTION precision_val(p_srcPrecision MD_COLUMNS.PRECISION%TYPE, p_newDataType VARCHAR2) RETURN VARCHAR2
IS
  v_newDataType VARCHAR2(255);
  v_ret VARCHAR2(255);
BEGIN
  v_newDataType := UPPER(to_char(p_newDataType));
  -- Assume that no precision should be present
  v_ret := 'NULL';
  -- No see what the new data type is and ensure that a precision is required
  IF v_newDataType = 'VARCHAR2' OR
     v_newDataType = 'NVARCHAR2' OR
     v_newDataType = 'NUMBER' OR
     v_newDataType = 'DECIMAL' OR
     v_newDataType = 'TIMESTAMP' OR
     v_newDataType = 'INTERVAL YEAR' OR
     v_newDataType = 'INTERVAL DAY' OR
     v_newDataType = 'UROWID' OR
     v_newDataType = 'CHAR' OR
     v_newDataType = 'RAW' OR
     v_newDataType = 'NCHAR' THEN
     v_ret := p_srcPrecision;
  END IF;
  return v_ret;
END precision_val;

FUNCTION scale_val(p_srcPrecision MD_COLUMNS.SCALE%TYPE, p_newDataType VARCHAR2) RETURN VARCHAR2
IS
  v_newDataType VARCHAR2(255);
  v_ret VARCHAR2(255);
BEGIN
  v_newDataType := UPPER(to_char(p_newDataType));
  v_ret := 'NULL';
  IF v_newDataType = 'NUMBER'  OR v_newDataType = 'DECIMAL' THEN
    v_ret := p_srcPrecision;
  END IF;
  return v_ret;
END scale_val;

FUNCTION check_for_invalid_data_types(p_connectionid MD_CONNECTIONS.ID%TYPE, p_numbytesperchar INTEGER, p_is12c CHAR:= 'N') RETURN NUMBER
IS
    --make limits that vary in 12c variables
    v_limitVarchar2 MD_COLUMNS.PRECISION%TYPE :=4000;
    v_limitChar MD_COLUMNS.PRECISION%TYPE := 2000;
    v_limitNChar MD_COLUMNS.PRECISION%TYPE := 2000;
    v_limitNChar_2 MD_COLUMNS.PRECISION%TYPE := 1000;
    v_limitNVarchar2 MD_COLUMNS.PRECISION%TYPE := 4000;
    v_limitNVarchar2_2 MD_COLUMNS.PRECISION%TYPE := 2000;
    v_limitRaw MD_COLUMNS.PRECISION%TYPE := 2000;
BEGIN
    IF (p_is12c = 'Y') THEN
    	--Note: CHAR and NCHAR are not effected
        v_limitVarchar2 :=32767;
        v_limitNVarchar2 := 32767;
        v_limitNVarchar2_2 := 16383;
        v_limitRaw := 32767;
    END IF;
    -- First, for char(n) columns, drop back to varchar2 - this could go up to 4k.
    -- If its even greater than this, it will be caught later on and made into a CLOB.
    UPDATE /* APEXa70168 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
        AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'CHAR' AND PRECISION > v_limitChar
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX0d0107 */  MD_COLUMNS SET COLUMN_TYPE = 'VARCHAR2' WHERE COLUMN_TYPE = 'CHAR' AND PRECISION > v_limitChar
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    -- We'll do something similar for NCHARs
    IF p_numbytesperchar = 1 THEN
        UPDATE /* APEX785abf */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
          AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NCHAR' AND PRECISION > v_limitNChar 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
        UPDATE /* APEXbcc963 */  MD_COLUMNS SET COLUMN_TYPE = 'NVARCHAR2' WHERE COLUMN_TYPE = 'NCHAR' AND PRECISION > v_limitNChar 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    ELSE   
        -- 2 bytes per char - max is actually 1k          
        UPDATE /* APEX02dfc9 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
          AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NCHAR' AND PRECISION > v_limitNChar_2 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
        UPDATE /* APEXe5183d */  MD_COLUMNS SET COLUMN_TYPE = 'NVARCHAR2' WHERE COLUMN_TYPE = 'NCHAR' AND PRECISION > v_limitNChar_2 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    END IF;            
    -- VARCHAR or VARCHAR2 can't go above 4000 (32767 in 12c).  If they do, they need to fallback to a CLOB
    UPDATE /* APEX8b4b3d */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'VARCHAR' AND PRECISION > v_limitVarchar2 
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX096a2c */  MD_COLUMNS SET COLUMN_TYPE = 'CLOB', PRECISION = NULL, SCALE = NULL WHERE COLUMN_TYPE = 'VARCHAR' AND PRECISION > v_limitVarchar2 
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEXf2a9a1 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS  WHERE COLUMN_TYPE = 'VARCHAR2' AND PRECISION > v_limitVarchar2 
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX69c07f */  MD_COLUMNS SET COLUMN_TYPE = 'CLOB', PRECISION = NULL, SCALE = NULL WHERE COLUMN_TYPE = 'VARCHAR2' AND PRECISION > v_limitVarchar2 
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    -- NUMBER has a max precision of 38, and scale must be between -84 and 127
    -- We can only narrow this.  

    UPDATE /* APEX3d0724 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NUMBER' AND PRECISION > 38
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX10b202 */  MD_COLUMNS SET PRECISION = 38 WHERE COLUMN_TYPE = 'NUMBER' AND PRECISION > 38
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEX9ffcee */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NUMBER' AND SCALE < -84
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX596ca6 */  MD_COLUMNS SET SCALE = -84 WHERE COLUMN_TYPE = 'NUMBER' AND SCALE < -84
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEX91ec93 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NUMBER' AND SCALE > 127
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX4b7717 */  MD_COLUMNS SET SCALE = 127 WHERE COLUMN_TYPE = 'NUMBER' AND SCALE > 127
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    -- NVARCHAR has a max of 4000 (32767 in 12c) bytes.  But its definition depends on the character set in use.
    IF  p_numbytesperchar = 1 THEN
        UPDATE /* APEX21479a */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
          AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NVARCHAR2' AND PRECISION > v_limitNVarchar2 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
        UPDATE /* APEXa6699b */  MD_COLUMNS SET COLUMN_TYPE = 'NCLOB', PRECISION = NULL, SCALE = NULL WHERE COLUMN_TYPE = 'NVARCHAR2' AND PRECISION > v_limitNVarchar2 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    ELSE
        UPDATE /* APEX7efb4a */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
          AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'NVARCHAR2' AND PRECISION > v_limitNVarchar2_2 
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
        UPDATE /* APEX222907 */  MD_COLUMNS SET COLUMN_TYPE = 'NCLOB', PRECISION = NULL, SCALE = NULL WHERE COLUMN_TYPE = 'NVARCHAR2' AND PRECISION > v_limitNVarchar2_2
            AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    END IF;            
    -- TIMESTAMP has a max size of 9

    UPDATE /* APEXbe9787 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'TIMESTAMP' AND PRECISION > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX2972c8 */  MD_COLUMNS SET PRECISION = 9 WHERE COLUMN_TYPE = 'TIMESTAMP' AND PRECISION > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEXd90649 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'INTERVAL YEAR' AND PRECISION > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEXe6819d */  MD_COLUMNS SET PRECISION = 9 WHERE COLUMN_TYPE = 'INTERVAL YEAR' AND PRECISION > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEX0f2de6 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'INTERVAL DAY' AND PRECISION > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX80e93f */  MD_COLUMNS SET PRECISION = 9 WHERE COLUMN_TYPE = 'INTERVAL DAY' AND PRECISION > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEX52de60 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'INTERVAL DAY' AND SCALE > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEXc299dd */  MD_COLUMNS SET SCALE = 9 WHERE COLUMN_TYPE = 'INTERVAL DAY' AND SCALE > 9
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);

    UPDATE /* APEX1b3ace */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'UROWID' AND PRECISION > 4000
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX7f22a3 */  MD_COLUMNS SET PRECISION = 4000 WHERE COLUMN_TYPE = 'UROWID' AND PRECISION > 4000
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    -- Too large RAW?  Make it a CLOB        

    UPDATE /* APEXa72390 */  MD_DERIVATIVES SET DERIVATIVE_REASON = 'INVDTTYPE' WHERE DERIVED_CONNECTION_ID_FK = p_connectionid
      AND DERIVED_TYPE = 'MD_COLUMNS' AND DERIVED_ID IN (SELECT ID FROM MD_COLUMNS WHERE COLUMN_TYPE = 'RAW' AND PRECISION > v_limitRaw
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid));
    UPDATE /* APEX2119b7 */  MD_COLUMNS SET COLUMN_TYPE = 'BLOB', PRECISION = NULL WHERE COLUMN_TYPE = 'RAW' AND PRECISION > v_limitRaw
        AND TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid);
    commit;
    RETURN 0;        
END check_for_invalid_data_types;

FUNCTION transform_datatypes(p_connectionid MD_CONNECTIONS.ID%TYPE, p_mapid MIGR_DATATYPE_TRANSFORM_MAP.ID%TYPE, p_numbytesperchar INTEGER, p_is12c VARCHAR2 :=  'N') RETURN NUMBER
IS
  v_projectid MD_PROJECTS.ID%TYPE;
  v_mapProjectid MD_PROJECTS.ID%TYPE;
  CURSOR v_curs(mapid MIGR_DATATYPE_TRANSFORM_MAP.ID%TYPE) IS
    SELECT * FROM MIGR_DATATYPE_TRANSFORM_RULE WHERE map_ID_fk = mapid
    ORDER BY     DECODE(source_precision,
            NULL, 0,
            1) +
    DECODE(source_scale,
            NULL, 0,
            1)  DESC;
  v_rule MIGR_DATATYPE_TRANSFORM_RULE%ROWTYPE;
  v_whereClause VARCHAR2(4000);
  v_updateClause VARCHAR2(4000);
  v_count NUMBER := 0;
  v_ret NUMBER;
BEGIN
  -- We should only work with our "own" maps.  I.e. The map should be part of this project.
  SELECT /* APEX276ceb */  project_id_fk into v_projectid from MD_CONNECTIONS where id = p_connectionid;
  SELECT /* APEXd9efb1 */  project_id_fk into v_mapProjectid from MIGR_DATATYPE_TRANSFORM_MAP where id = p_mapid;
  IF v_projectid != v_mapProjectid then 
    -- TODO.  Some nice RAISE_APPLICATION_ERROR stuff here.
    return 0;
  END IF;
  -- OK We can work with our map
  OPEN v_curs(p_mapid);
  LOOP
    fetch v_curs INTO v_rule;
    EXIT WHEN v_curs%NOTFOUND;
    v_whereClause := 'UPPER(COLUMN_TYPE) = ''' || UPPER(v_rule.SOURCE_DATA_TYPE_NAME) || '''';
    if v_rule.SOURCE_PRECISION is not NULL then
      v_whereClause := addToWhereClause(v_whereClause, 'PRECISION = ' || to_char(v_rule.source_precision));
      IF v_rule.SOURCE_SCALE is not NULL then
        v_whereClause := addToWhereClause(v_whereClause, 'SCALE = ' || to_char(v_rule.source_scale));
      end IF;
    END IF;
    v_whereClause := addToWhereClause(v_whereClause, 'table_id_fk in (SELECT table_id from MGV_ALL_TABLES WHERE connection_id = ' || to_char(p_connectionid) || ')');
    v_whereClause := addTowhereclause(v_whereClause, 'DATATYPE_TRANSFORMED_FLAG IS NULL');
    v_updateClause := 'UPDATE MD_COLUMNS SET COLUMN_TYPE = ''' || v_rule.TARGET_DATA_TYPE_NAME || ''', DATATYPE_TRANSFORMED_FLAG=''Y''';
    IF v_rule.TARGET_PRECISION is not NULL then
      v_updateClause := v_updateClause || ', PRECISION = ' || precision_val(v_rule.TARGET_PRECISION, v_rule.TARGET_DATA_TYPE_NAME);
      IF v_rule.TARGET_SCALE is not NULL then
        -- The rule says change it to a specific scale, but we may override this is the data type shouldn't have a scale
        v_updateClause := v_updateClause || ', SCALE = ' || scale_val(v_rule.TARGET_SCALE, v_rule.TARGET_DATA_TYPE_NAME);
      ELSE
        -- There was no mention on the rule to touch the scale, so we should leave it alone...
        -- ..unless of course the data type forbids having it.
        IF scale_val(1, v_rule.TARGET_DATA_TYPE_NAME) = 'NULL' THEN
          v_updateClause := v_updateClause || ', SCALE = NULL';
        END IF;
      END IF;
    ELSE
      -- There was no metion on the rul to touch the precision, so we should leave it alone...
      -- ..unless of course the data type forbids having it.
      IF precision_val(1, v_rule.TARGET_DATA_TYPE_NAME) = 'NULL' THEN
        v_updateClause := v_updateClause || ', PRECISION = NULL';
      END IF;
      IF scale_val(1, v_rule.TARGET_DATA_TYPE_NAME) = 'NULL' THEN
        v_updateClause := v_updateClause || ', SCALE = NULL';
      END IF;
    END IF;
    v_updateClause := v_updateClause || ' WHERE ' || v_whereClause;
    dbms_output.put_line(v_updateClause);
    EXECUTE IMMEDIATE v_updateClause;
    v_count := v_count + SQL%ROWCOUNT;
  END LOOP;
  CLOSE v_curs;
  COMMIT;
  -- OK.  Lets see if we've made any columns invalid.
  v_ret := check_for_invalid_data_types(p_connectionid, p_numbytesperchar, p_is12c);  
  -- Now that we know the data types of the index columns, we may have flag some of the indexes
  -- as text indexes.
  v_ret := fixupTextIndexes(p_connectionid);

  RETURN v_count;
END transform_datatypes;

FUNCTION GET_SIMPLE_IDENTITY_TRIGGER(v_triggerName VARCHAR2 , v_tableName VARCHAR2  , 
v_ColumnName VARCHAR2,v_emulationPkgNamePrefix VARCHAR2 ) RETURN VARCHAR2
as
 v_identityClause VARCHAR2(200);
BEGIN

IF (v_emulationpkgnameprefix = 'mysql_utilities.') THEN
  v_identityclause := '  --used to emulate LAST_INSERT_ID()'|| chr(10) || '  --'||v_emulationpkgnameprefix || 'identity := v_newVal; '|| chr(10) ;
ELSIF (v_emulationpkgnameprefix = 'utils.') THEN --sqlserver and sybase use identity_value
  v_identityclause := '  -- save this to emulate @@identity'|| chr(10) || '  '||v_emulationpkgnameprefix || 'identity_value := v_newVal; '|| chr(10) ;
ELSE
  v_identityclause := '  --used to help get last identity value '|| chr(10) || '  '||v_emulationpkgnameprefix || 'identity := v_newVal; '|| chr(10) ;
END IF;

return 'CREATE OR REPLACE TRIGGER ' || v_triggerName || ' AFTER INSERT ON ' || v_tableName || CHR(10) ||
       'FOR EACH ROW' || CHR(10) ||
       'DECLARE ' || CHR(10)||
       'v_newVal NUMBER(12) := 0;' ||CHR(10) ||
       'BEGIN' || CHR(10) ||
       '  v_newVal := :new.' || v_ColumnName || ';' || CHR(10) ||
       v_identityClause
      ||
       'END;' || CHR(10);
END GET_SIMPLE_IDENTITY_TRIGGER;

FUNCTION GET_IDENTITY_TRIGGER(v_triggerName VARCHAR2 , v_tableName VARCHAR2  , 
v_ColumnName VARCHAR2  ,v_seqName VARCHAR2 ,v_emulationPkgNamePrefix VARCHAR2 ) RETURN VARCHAR2
as
 v_identityClause VARCHAR2(200);
BEGIN

IF (v_emulationpkgnameprefix = 'mysql_utilities.') THEN
  v_identityclause := '    --used to emulate LAST_INSERT_ID()'|| chr(10) || '    --'||v_emulationpkgnameprefix || 'identity := v_newVal; '|| chr(10) ;
ELSIF (v_emulationpkgnameprefix = 'utils.') THEN --sqlserver and sybase use identity_value
  v_identityclause := '  -- save this to emulate @@identity'|| chr(10) || '  '||v_emulationpkgnameprefix || 'identity_value := v_newVal; '|| chr(10) ;
ELSE
  v_identityclause := '  --used to help get last identity value '|| chr(10) || '  '||v_emulationpkgnameprefix || 'identity := v_newVal; '|| chr(10) ;
END IF;

return 'CREATE OR REPLACE TRIGGER ' || v_triggerName || ' BEFORE INSERT ON ' || v_tableName || CHR(10) ||
       'FOR EACH ROW' || CHR(10) ||
       'DECLARE ' || CHR(10)||
       'v_newVal NUMBER(12) := 0;' ||CHR(10) ||
	   'v_incval NUMBER(12) := 0;'||CHR(10) ||
       'BEGIN' || CHR(10) ||
       '  IF INSERTING AND :new.' || v_ColumnName || ' IS NULL THEN' || CHR(10) ||
       '    SELECT  ' || v_seqName || '.NEXTVAL INTO v_newVal FROM DUAL;' || CHR(10) ||
	   '    -- If this is the first time this table have been inserted into (sequence == 1)' || CHR(10) ||
	   '    IF v_newVal = 1 THEN ' || CHR(10) ||
	   '      --get the max indentity value from the table' || CHR(10) ||
	   '      SELECT NVL(max(' || v_ColumnName || '),0) INTO v_newVal FROM ' || v_tableName || ';'|| CHR(10) || 
	   '      v_newVal := v_newVal + 1;' || CHR(10) || 
	   '      --set the sequence to that value'|| CHR(10) || 
	   '      LOOP'|| CHR(10) || 
	   '           EXIT WHEN v_incval>=v_newVal;'|| CHR(10) || 
	   '           SELECT ' || v_seqName || '.nextval INTO v_incval FROM dual;'|| CHR(10) || 
       '      END LOOP;'|| CHR(10) || 
       '    END IF;'|| chr(10) ||    
       v_identityClause
      ||
       '   -- assign the value from the sequence to emulate the identity column'|| CHR(10) || 
       '   :new.' || v_ColumnName || ' := v_newVal;'|| CHR(10) || 
       '  END IF;' || CHR(10) ||
       'END;' || CHR(10);
END GET_IDENTITY_TRIGGER;

FUNCTION get_plugin_name(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN VARCHAR2
IS
  CURSOR v_pluginNameCur IS SELECT value FROM MD_ADDITIONAL_PROPERTIES WHERE prop_key='PLUGIN_ID' AND connection_id_fk = p_connectionid;
  v_pluginName MD_ADDITIONAL_PROPERTIES.VALUE%TYPE;
  BEGIN
	  OPEN v_pluginNameCur;
	  FETCH v_pluginNameCur INTO v_pluginName;
	  CLOSE v_pluginNameCur;
	  RETURN v_pluginName;
END get_plugin_name;	  

FUNCTION get_emulation_pkg_name(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN VARCHAR2
AS
v_pkgName VARCHAR2(1000);
v_pluginName MD_ADDITIONAL_PROPERTIES.VALUE%TYPE;
BEGIN
	v_pluginName := get_plugin_name(p_connectionid);
	IF LOWER(v_pluginName) LIKE '%sqlserver%'THEN
	  	v_pkgName := 'utils.';
	  ELSIF LOWER(v_pluginName) LIKE '%access%'THEN
	    v_pkgName := 'msaccess_utilities.';
	  ELSIF LOWER(v_pluginName) LIKE '%sybase%'THEN
	    v_pkgName := 'utils.';
	  ELSIF LOWER(v_pluginName) LIKE '%mysql%' THEN
	    v_pkgName := 'mysql_utilities.';
	  ELSIF LOWER(v_pluginName) LIKE '%db2%' THEN
	    v_pkgName := 'db2_utilities.';
	END IF;
  RETURN v_pkgName;
END get_emulation_pkg_name;

FUNCTION transform_identity_columns(p_connectionid MD_CONNECTIONS.ID%TYPE, p_is12c VARCHAR2) RETURN NUMBER
IS
  CURSOR v_curs IS SELECT a.schema_id_fk, a.id tableid, a.TABLE_NAME, b.id, b.column_name, b.NULLABLE
                   FROM md_tables a, md_columns b WHERE b.id IN
                     (SELECT ref_id_fk FROM md_additional_properties WHERE prop_key = C_PROPKEY_SEEDVALUE)
                   AND table_id_fk IN (SELECT table_id FROM mgv_all_tables WHERE connection_id = p_connectionid)
                   AND a.id = b.table_id_fk
                   AND b.id NOT IN (SELECT SRC_ID FROM MD_DERIVATIVES WHERE SRC_TYPE = C_OBJECTTYPE_COLUMNS AND DERIVED_TYPE = C_OBJECTTYPE_SEQUENCES AND 
                                    DERIVED_CONNECTION_ID_FK = p_connectionid);  
  	v_schemaId MD_SCHEMAS.ID%TYPE;
	v_tableId MD_TABLES.ID%TYPE;
        v_tableName MD_TABLES.TABLE_NAME%TYPE;
	v_columnId MD_COLUMNS.ID%TYPE;
	v_columnName MD_COLUMNS.COLUMN_NAME%TYPE;
	v_row MD_ADDITIONAL_PROPERTIES%ROWTYPE;
	v_seedValue NUMBER;
	-- Default the increment to 1 if it is not supplied.
	v_increment NUMBER := 1;
	v_lastVal NUMBER := NULL;
	v_retId MD_SEQUENCES.ID%TYPE;
	v_retSeqId MD_SEQUENCES.ID%TYPE;
	v_seqName MD_SEQUENCES.NAME%TYPE;
        v_trgName MD_TRIGGERS.TRIGGER_NAME%TYPE;
	v_triggerText VARCHAR2(4000);
        v_lob CLOB;
	v_transRet NAME_AND_COUNT_T;
	v_dbTypeCurs VARCHAR2(1000);
	v_emulationPkgNamePrefix VARCHAR2(100) := '';
	v_nullable MD_COLUMNS.NULLABLE%TYPE;
    v_alreadyDone NUMBER;
    v_continueTriggered BOOLEAN := FALSE;
    v_identityClause VARCHAR2(4000);
BEGIN
  -- Auxillary, get the emulation package name
  v_emulationPkgNamePrefix := get_emulation_pkg_name(p_connectionid);

  OPEN v_curs;
  LOOP
    v_continueTriggered := FALSE;
  	FETCH v_curs into v_schemaId, v_tableId, v_tableName, v_columnId, v_columnName, v_nullable;
  	EXIT WHEN v_curs%NOTFOUND;
  	-- The above query excludes already created sequences, so we should be ok.
  	-- create the sequence:
  	-- 1. Get the seedvalue, increment, lastvalue if present
    v_alreadyDone := 0;
    BEGIN
      IF (p_is12c = 'Y') THEN
        SELECT /* APEX34db74 */  1 INTO  v_alreadyDone FROM MD_ADDITIONAL_PROPERTIES
        WHERE CONNECTION_ID_FK = p_connectionid 
        AND REF_ID_FK = v_tableId 
        AND REF_TYPE = C_OBJECTTYPE_TABLES 
        AND PROP_KEY = C_PROPKEY_ALREADY_IDENTITY;
      ELSE
        v_alreadyDone:=0;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN v_alreadyDone :=0;
    END;

    IF (v_nullable = 'N' AND p_is12c = 'Y' AND v_alreadyDone != 1) THEN
	    FOR v_row in (SELECT * FROM MD_ADDITIONAL_PROPERTIES WHERE REF_ID_FK = v_columnId)
	  	LOOP
	  	  IF v_row.PROP_KEY = C_PROPKEY_SEEDVALUE THEN
	  	    v_seedValue := TO_NUMBER(v_row.VALUE);
	      END IF;
	  	  IF v_row.PROP_KEY = C_PROPKEY_INCREMENT THEN
	  	    v_increment := TO_NUMBER(v_row.VALUE);
	      END IF;
	  	END LOOP;
      -- Bug 29230132 - MIGRATE AUTO_INCREMENT COLUMN GET ORA-04006
      v_identityClause := 'GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH '||v_seedValue||' INCREMENT BY '||v_increment||' MINVALUE '||v_seedValue||' NOMAXVALUE';
      INSERT /* APEXe30c52 */  INTO MD_ADDITIONAL_PROPERTIES ( CONNECTION_ID_FK, REF_ID_FK, REF_TYPE, PROP_KEY, VALUE )
      VALUES (p_connectionid, v_columnId, C_OBJECTTYPE_COLUMNS, C_PROPKEY_REAL_IDENTITY, v_identityClause);
      INSERT /* APEX5242f6 */  INTO MD_ADDITIONAL_PROPERTIES ( CONNECTION_ID_FK, REF_ID_FK, REF_TYPE, PROP_KEY, VALUE )
      VALUES (p_connectionid, v_tableId, C_OBJECTTYPE_TABLES, C_PROPKEY_ALREADY_IDENTITY, '');

      v_continueTriggered:=FALSE; -- no need to have Trigger Created 

      --DONE do it in create table/ enable - 
      --ISSUES: DONE can be ascending or decending 
      --        DONE top (bottom) value has to be set at end (along with enable constraints)
      --ISSUE   If no entries sequence next val will be 0+increment - there was some work by Indian integrator to recapture current sequence,
      --            if capture convert generate is not done at the same time, or the sequence is otherwise above max/min value.

  	END IF; -- IF (v_nullable = 'N' AND p_is12c = 'Y' AND v_alreadyDone != 1)

    IF (p_is12c = 'N' ) THEN
	  	IF (v_continueTriggered = TRUE) THEN /* need simple trigger to fill @@identity */
	      v_trgName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_tableName || '_' || v_columnName || '_TRG');
	      v_triggerText := GET_SIMPLE_IDENTITY_TRIGGER(v_trgName, v_tableName , v_ColumnName ,v_emulationPkgNamePrefix);
	      -- Note: I'm adding _TRG to the column name for now.We'll have to use the collsion manager in the futre.
	  	  INSERT /* APEX66f507 */  INTO MD_TRIGGERS(TABLE_OR_VIEW_ID_FK, TRIGGER_ON_FLAG, TRIGGER_NAME, TRIGGER_TIMING, TRIGGER_OPERATION, NATIVE_SQL, LANGUAGE)
	      VALUES(v_tableId, 'T', v_trgName, 'AFTER', 'INSERT OR UPDATE', EMPTY_CLOB(), C_LANGUAGEID_ORACLE)
	      RETURNING ID INTO v_retId;
	      INSERT /* APEX61327d */  INTO MD_ADDITIONAL_PROPERTIES ( CONNECTION_ID_FK, REF_ID_FK, REF_TYPE, PROP_KEY, VALUE )
	        VALUES (p_connectionid, v_retId, C_OBJECTTYPE_TRIGGERS, C_PROPKEY_TRIGGER_REWRITE, '');
	      --INSERT INTO MD_ADDITIONAL_PROPERTIES ( CONNECTION_ID_FK, REF_ID_FK, REF_TYPE, PROP_KEY, VALUE )
	      --  VALUES (p_connectionid, v_retId, C_OBJECTTYPE_TRIGGERS, C_PROPKEY_SEQUENCEID, TO_CHAR(v_retSeqId));  
	      INSERT /* APEX6120aa */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
	        VALUES(v_columnId, C_OBJECTTYPE_COLUMNS, v_retId, C_OBJECTTYPE_TRIGGERS, p_connectionId, C_TRANSFORMED_TRUE, NULL, v_trgName, C_NS_SCHEMA_OBJS || TO_CHAR(v_schemaId));
	      SELECT /* APEXec4ee7 */  NATIVE_SQL INTO v_lob FROM MD_TRIGGERS WHERE ID = v_retId;          
	        DBMS_LOB.OPEN(v_lob, DBMS_LOB.LOB_READWRITE);
	        DBMS_LOB.WRITE(v_lob, LENGTH(v_triggerText), 1, v_triggerText);
	        DBMS_LOB.CLOSE(v_lob);
	  	ELSE	
	  	 FOR v_row in (SELECT /* APEXc1c83e */  * FROM MD_ADDITIONAL_PROPERTIES WHERE REF_ID_FK = v_columnId)
	  	LOOP
	  	  IF v_row.PROP_KEY = C_PROPKEY_SEEDVALUE THEN
	  	    v_seedValue := TO_NUMBER(v_row.VALUE);
	          END IF;
	  	  IF v_row.PROP_KEY = C_PROPKEY_INCREMENT THEN
	  	    v_increment := TO_NUMBER(v_row.VALUE);
	          END IF;
	  	  IF v_row.PROP_KEY = C_PROPKEY_LASTVALUE THEN
	  	    v_lastVal := TO_NUMBER(v_row.VALUE);
	  	  END IF;
	  	END LOOP;
	  	-- Note: We'll start our sequence where the source left off.
	  	IF v_lastVal IS NOT NULL THEN
	  	  v_seedValue := v_lastVal;
	  	END IF;

	  	-- 2. Create the sequence
	  	-- Note: I'm adding _SEQ to the column name for now. We'll have to use the collision manager in the
	  	-- future.
	  	v_seqName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_tableName || '_' || v_columnName || '_SEQ');
	  	INSERT /* APEX5f9e5e */  INTO MD_SEQUENCES(SCHEMA_ID_FK, NAME, SEQ_START, INCR)
	  	  VALUES (v_schemaId, v_seqName, v_seedValue, v_increment)
	  	  RETURNING ID INTO v_retId;
	  	v_retSeqId := v_retId;
	  	-- And of course a new derivative record
	  	INSERT /* APEX51180d */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
	  	  VALUES(v_columnId, C_OBJECTTYPE_COLUMNS, v_retId, C_OBJECTTYPE_SEQUENCES, p_connectionId, C_TRANSFORMED_TRUE, NULL, v_seqName, C_NS_SCHEMA_OBJS || TO_CHAR(v_schemaId));
	  	-- Create the trigger
	        v_trgName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_tableName || '_' || v_columnName || '_TRG');
	  	v_triggerText := GET_IDENTITY_TRIGGER(v_trgName, v_tableName , v_ColumnName ,v_seqName ,v_emulationPkgNamePrefix);
	  	-- Note: I'm adding _TRG to the column name for now.We'll have to use the collsion manager in the futre.
	  	INSERT /* APEX7c7756 */  INTO MD_TRIGGERS(TABLE_OR_VIEW_ID_FK, TRIGGER_ON_FLAG, TRIGGER_NAME, TRIGGER_TIMING, TRIGGER_OPERATION, NATIVE_SQL, LANGUAGE)
	  	  VALUES(v_tableId, 'T', v_trgName, 'BEFORE', 'INSERT OR UPDATE', EMPTY_CLOB(), C_LANGUAGEID_ORACLE)
	  	  RETURNING ID INTO v_retId;
	  	INSERT /* APEXce94e3 */  INTO MD_ADDITIONAL_PROPERTIES ( CONNECTION_ID_FK, REF_ID_FK, REF_TYPE, PROP_KEY, VALUE )
	       VALUES (p_connectionid, v_retId, C_OBJECTTYPE_TRIGGERS, C_PROPKEY_TRIGGER_REWRITE, '');
	    INSERT /* APEXcf7d69 */  INTO MD_ADDITIONAL_PROPERTIES ( CONNECTION_ID_FK, REF_ID_FK, REF_TYPE, PROP_KEY, VALUE )
	       VALUES (p_connectionid, v_retId, C_OBJECTTYPE_TRIGGERS, C_PROPKEY_SEQUENCEID, TO_CHAR(v_retSeqId));	
	  	INSERT /* APEX2740dd */  INTO MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED, ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE)
	  	  VALUES(v_columnId, C_OBJECTTYPE_COLUMNS, v_retId, C_OBJECTTYPE_TRIGGERS, p_connectionId, C_TRANSFORMED_TRUE, NULL, v_trgName, C_NS_SCHEMA_OBJS || TO_CHAR(v_schemaId));
	        SELECT /* APEX58d98d */  NATIVE_SQL INTO v_lob FROM MD_TRIGGERS WHERE ID = v_retId;          
	        DBMS_LOB.OPEN(v_lob, DBMS_LOB.LOB_READWRITE);
	        DBMS_LOB.WRITE(v_lob, LENGTH(v_triggerText), 1, v_triggerText);
	        DBMS_LOB.CLOSE(v_lob);
	    END IF;
   END IF; -- if (p_is12c = 'N' )
  END LOOP;
  COMMIT;
  CLOSE v_curs;
  RETURN 0;
END transform_identity_columns;

FUNCTION transform_rewrite_trigger(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER
IS
  CURSOR v_curs is SELECT ID, TABLE_OR_VIEW_ID_FK, TRIGGER_ON_FLAG, TRIGGER_NAME,
    TRIGGER_TIMING, TRIGGER_OPERATION, TRIGGER_EVENT, NATIVE_SQL, NATIVE_KEY,
    LANGUAGE, COMMENTS from MD_TRIGGERS where ID in
    (SELECT REF_ID_FK from MD_ADDITIONAL_PROPERTIES
    WHERE CONNECTION_ID_FK = p_connectionid and PROP_KEY = C_PROPKEY_TRIGGER_REWRITE);

  v_rowTriggers MD_TRIGGERS%ROWTYPE;
  v_tableName MD_TABLES.TABLE_NAME%TYPE;
	v_columnName MD_COLUMNS.COLUMN_NAME%TYPE;
	v_retId MD_SEQUENCES.ID%TYPE;
  v_retSeqId MD_SEQUENCES.ID%TYPE;
	v_seqName MD_SEQUENCES.NAME%TYPE;
  v_seqName2 MD_SEQUENCES.NAME%TYPE;
	v_triggerText VARCHAR2(4000);
  v_lob CLOB;
  v_projectName VARCHAR2(100);
  v_emulationPkgNamePrefix VARCHAR2(100) := '';
BEGIN
  -- Auxillary, get the emulation package name
  v_emulationPkgNamePrefix := get_emulation_pkg_name(p_connectionid);

  open v_curs;
  loop
    fetch v_curs into v_rowTriggers.ID, v_rowTriggers.TABLE_OR_VIEW_ID_FK, v_rowTriggers.TRIGGER_ON_FLAG, v_rowTriggers.TRIGGER_NAME,
    v_rowTriggers.TRIGGER_TIMING, v_rowTriggers.TRIGGER_OPERATION, v_rowTriggers.TRIGGER_EVENT, v_rowTriggers.NATIVE_SQL, v_rowTriggers.NATIVE_KEY,
    v_rowTriggers.LANGUAGE, v_rowTriggers.COMMENTS ;
    EXIT WHEN v_curs%NOTFOUND;
    update /* APEXab31cc */  MD_TRIGGERS set native_sql = empty_clob() where id = v_rowTriggers.ID;

    -- get table and column name from the derivative of this trigger
    select /* APEX5cc7d2 */  T.TABLE_NAME, C.COLUMN_NAME into v_tableName, v_columnName from MD_TABLES T,
      MD_COLUMNS C where C.TABLE_ID_FK = T.ID and C.ID =
      (select SRC_ID from MD_DERIVATIVES where DERIVED_ID =  v_rowTriggers.ID and SRC_TYPE =
      C_OBJECTTYPE_COLUMNS and DERIVED_CONNECTION_ID_FK = p_connectionid);
    -- get sequence name from id got from additional property
    BEGIN
      select /* APEX83cfe5 */  s.NAME into v_seqName from MD_SEQUENCES s where s.ID =
        (select TO_NUMBER(VALUE) from MD_ADDITIONAL_PROPERTIES where CONNECTION_ID_FK = p_connectionid
        AND REF_ID_FK = v_rowTriggers.ID and PROP_KEY = C_PROPKEY_SEQUENCEID);
      v_triggerText := GET_IDENTITY_TRIGGER(v_rowTriggers.TRIGGER_NAME, v_tableName , v_ColumnName ,v_seqName ,v_emulationPkgNamePrefix);
    EXCEPTION WHEN NO_DATA_FOUND THEN
      --no sequence known (its 12 c identity)
      v_triggerText := GET_SIMPLE_IDENTITY_TRIGGER(v_rowTriggers.TRIGGER_NAME, v_tableName , v_ColumnName ,v_emulationPkgNamePrefix);
    END;
    SELECT /* APEXa55231 */  NATIVE_SQL INTO v_lob FROM MD_TRIGGERS WHERE ID = v_rowTriggers.ID;          
    DBMS_LOB.OPEN(v_lob, DBMS_LOB.LOB_READWRITE);
    DBMS_LOB.WRITE(v_lob, LENGTH(v_triggerText), 1, v_triggerText);
    DBMS_LOB.CLOSE(v_lob);
  END LOOP;
  COMMIT;
  CLOSE v_curs;
  return 0;
END transform_rewrite_trigger;

-- Remove all ForeignKeys that are created on the same table with same referenced Table columns
PROCEDURE remove_duplicate_foreignkeys(p_connectionid MD_CONNECTIONS.ID%TYPE)
IS
  CURSOR v_reftableidfk_cur
  IS
    SELECT CONSTRAINT_ID, TABLE_ID_FK, REFTABLE_ID_FK, COL_ID_FK FROM 
	(
	    SELECT ROW_NUMBER() OVER (PARTITION BY A.COL_ID_FK ORDER BY A.CONSTRAINT_ID) rn, A.CONSTRAINT_ID, A.TABLE_ID_FK, A.REFTABLE_ID_FK, A.COL_ID_FK FROM 
	    (
	        (
	            SELECT
	                mc.id CONSTRAINT_ID,
	                mc.table_id_fk TABLE_ID_FK,
	                mc.reftable_id_fk REFTABLE_ID_FK,
	                LISTAGG(mcd.column_id_fk, ',') WITHIN GROUP (ORDER BY mc.id) COL_ID_FK,
	                COUNT(*)
	            FROM
	                md_constraints   mc,
	                md_constraint_details mcd,
	                mgv_all_constraints_details macd
	            WHERE
	                mc.constraint_type = 'FOREIGN KEY'
	                AND mc.id = macd.objid
	                AND mcd.constraint_id_fk = mc.id
	                AND mc.table_id_fk = macd.mainobjid
	                AND macd.connid = p_connectionid
	            GROUP BY
	                mc.id,
	                mc.table_id_fk,
	                mc.reftable_id_fk
	            ORDER BY
	                CONSTRAINT_ID
	        ) A   
	    )
	)
	WHERE RN > 1; 

  v_reftable_id_fk_id md_constraints.reftable_id_fk%TYPE;
  v_temprow MD_CONSTRAINTS%ROWTYPE;
  v_tableName VARCHAR(4000);
  v_record v_reftableidfk_cur%rowtype;
  v_constraint_id md_constraints.id%TYPE;
  row_num        INTEGER;
  single_quote   CHAR(1) := '''';
  n_char         CHAR(1) := 'N';
  delete_command VARCHAR(1000);

BEGIN
  OPEN v_reftableidfk_cur;
  LOOP
    FETCH v_reftableidfk_cur INTO v_record;
    EXIT
  WHEN v_reftableidfk_cur%NOTFOUND;
  delete_command := 'DELETE from md_constraints where id = :constraint_id and table_id_fk = :table_id and reftable_id_fk = :reftable_id' ;
  EXECUTE IMMEDIATE delete_command USING v_record.constraint_id, v_record.table_id_fk, v_record.reftable_id_fk ;

  delete_command := 'DELETE FROM md_constraint_details WHERE constraint_id_fk = :constraint_id AND ref_flag = ' ||single_quote||n_char||single_quote ;
  EXECUTE IMMEDIATE delete_command USING v_record.constraint_id;

  delete_command := 'DELETE FROM md_derivatives WHERE derived_id = :constraint_id' ;
  EXECUTE IMMEDIATE delete_command USING v_record.constraint_id;

  END LOOP; 
  CLOSE v_reftableidfk_cur;
  COMMIT;

END remove_duplicate_foreignkeys;

-- Remove all UniqueKeys that are created on the same table columns that has Primary keys created. 
PROCEDURE remove_unwanted_uniquekeys(p_connectionid MD_CONNECTIONS.ID%TYPE) 
IS  
  CURSOR v_tableidfk_cur
  IS
    SELECT uk_c.table_id_fk
    FROM md_constraints uk_c,
      md_constraints pk_c,
      mgv_all_tables mt
    WHERE pk_c.constraint_type = 'PK'
    AND uk_c.constraint_type   = 'UNIQUE'
    AND pk_c.table_id_fk       = uk_c.table_id_fk
    AND uk_c.TABLE_ID_FK       = mt.table_id
    AND mt.CONNECTION_ID       = p_connectionid;
  CURSOR v_uk_constraint_id_cur(table_id_fk_id md_constraints.table_id_fk%TYPE)
  IS
    SELECT cd.constraint_id_fk,
      cd.column_id_fk
    FROM md_constraint_details cd
    WHERE cd.constraint_id_fk IN
      (SELECT ID
      FROM md_constraints mc,
        mgv_all_tables mt
      WHERE mc.table_id_fk   = table_id_fk_id
      AND mc.constraint_type = 'UNIQUE'
      AND mc.table_id_fk     = mt.table_id
      AND mt.CONNECTION_ID   = p_connectionid
      )
  ORDER BY column_id_fk;
  CURSOR v_pk_constraint_id_cur(table_id_fk_id md_constraints.table_id_fk%TYPE)
  IS
    SELECT cd.constraint_id_fk,
      cd.column_id_fk
    FROM md_constraint_details cd
    WHERE cd.constraint_id_fk IN
      (SELECT ID
      FROM md_constraints mc,
        mgv_all_tables mt
      WHERE table_id_fk    = table_id_fk_id
      AND constraint_type  = 'PK'
      AND mc.table_id_fk   = mt.table_id
      AND mt.CONNECTION_ID = p_connectionid
      )
  ORDER BY column_id_fk;
TYPE ukColListType
IS
  TABLE OF NUMBER;
  ukColList ukColListType := ukColListType();
TYPE pkColListType
IS
  TABLE OF NUMBER;
  pkColList pkColListType := pkColListType();
  v_record v_tableidfk_cur%rowtype;
  v_record_uk_constraint v_uk_constraint_id_cur%rowtype;
  v_record_pk_constraint v_pk_constraint_id_cur%rowtype;
  counter        INTEGER;
  ukpkFlag       BOOLEAN;
  n_char         CHAR(1) := 'N';
  single_quote   CHAR(1) := '''';
  uniquekey      CHAR(6) := 'UNIQUE';
  delete_command VARCHAR(1000);
BEGIN
  OPEN v_tableidfk_cur;
  FETCH v_tableidfk_cur INTO v_record;
  LOOP
    EXIT
  WHEN v_tableidfk_cur%NOTFOUND;
    counter := 1;
    OPEN v_uk_constraint_id_cur(v_record.table_id_fk);
    FETCH v_uk_constraint_id_cur INTO v_record_uk_constraint;
    LOOP
      EXIT
    WHEN v_uk_constraint_id_cur%NOTFOUND;
      ukColList.extend(1) ;
      ukColList(counter) := v_record_uk_constraint.column_id_fk;
      counter            := counter + 1;
      FETCH v_uk_constraint_id_cur INTO v_record_uk_constraint;
    END LOOP;
    CLOSE v_uk_constraint_id_cur;
    counter := 1;
    OPEN v_pk_constraint_id_cur(v_record.table_id_fk);
    FETCH v_pk_constraint_id_cur INTO v_record_pk_constraint;
    LOOP
      EXIT
    WHEN v_pk_constraint_id_cur%NOTFOUND;
      pkColList.extend(1) ;
      pkColList(counter) := v_record_pk_constraint.column_id_fk;
      counter            := counter + 1;
      FETCH v_pk_constraint_id_cur INTO v_record_pk_constraint;
    END LOOP;
    CLOSE v_pk_constraint_id_cur;
    ukpkFlag := FALSE;
    FOR i IN ukColList.FIRST .. ukColList.LAST
    LOOP
      FOR j IN pkColList.FIRST .. pkColList.LAST
      LOOP
        IF ukColList(i) = pkColList(j) THEN
          ukpkFlag     := TRUE;
        END IF;
      END LOOP; -- j
    END LOOP;   -- i
    IF ukpkFlag THEN
      delete_command := 'DELETE from md_constraints where id = :constraint_id and table_id_fk = :table_id and constraint_type = ' ||single_quote||uniquekey||single_quote ;
      EXECUTE IMMEDIATE delete_command USING v_record_uk_constraint.constraint_id_fk,
      v_record.table_id_fk;
      delete_command := 'DELETE FROM md_constraint_details WHERE constraint_id_fk = :constraint_id AND ref_flag = ' ||single_quote||n_char||single_quote ;
      EXECUTE IMMEDIATE delete_command USING v_record_uk_constraint.constraint_id_fk;
      delete_command := 'DELETE FROM md_derivatives WHERE derived_id = :constraint_id' ;
      EXECUTE IMMEDIATE delete_command USING v_record_uk_constraint.constraint_id_fk;
    END IF;
    FETCH v_tableidfk_cur INTO v_record;
  END LOOP; -- v_tableidfk_cur LOOP
  CLOSE v_tableidfk_cur;
  COMMIT;
END remove_unwanted_uniquekeys;

-- create Uniquekeys where Foreign keys has referened table column does not have UniqueKey
PROCEDURE uniquekey_constraint_columns(p_connectionid MD_CONNECTIONS.ID%TYPE) 
IS  
  CURSOR v_reftableidfk_cur
  IS
    SELECT DISTINCT (fk_con.reftable_id_fk)
    FROM md_constraints fk_con
    WHERE fk_con.name NOT IN
      (SELECT fk_con.name
      FROM md_constraints pk_con
      WHERE fk_con.reftable_id_fk = pk_con.table_id_fk
      AND fk_con.constraint_type  = 'FOREIGN KEY'
      AND pk_con.constraint_type  = 'UNIQUE'
      )
  AND fk_con.name NOT IN
    (SELECT fk_con.name
    FROM md_constraints pk_con
    WHERE fk_con.reftable_id_fk = pk_con.table_id_fk
    AND fk_con.constraint_type  = 'FOREIGN KEY'
    AND pk_con.constraint_type  = 'PK'
    )
  AND fk_con.reftable_id_fk != 0
  AND fk_con.TABLE_ID_FK    IN
    (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid
    );

  CURSOR v_uk_columns_cur(reftable_id_fk_id md_constraints.reftable_id_fk%TYPE)
  IS
    SELECT DISTINCT(con_det.column_id_fk)
    FROM md_constraints fk_con,
      md_constraint_details con_det,
      md_columns col
    WHERE fk_con.reftable_id_fk  = reftable_id_fk_id
    AND con_det.constraint_id_fk = fk_con.id
    AND con_det.ref_flag         ='Y'
    AND con_det.column_id_fk     = col.id
    AND fk_con.TABLE_ID_FK    IN
    (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionid
    );

  CURSOR v_md_constraint_cur(reftable_id_fk_id md_constraints.reftable_id_fk%TYPE)
  IS
    SELECT *
    FROM md_constraints
    WHERE MD_CONSTRAINTS.reftable_id_fk = reftable_id_fk_id and rownum = 1;

   CURSOR v_table_name_cur(reftable_id_fk_id md_constraints.reftable_id_fk%TYPE)
  IS
    SELECT TABLE_NAME FROM MGV_ALL_TABLES WHERE MGV_ALL_TABLES.CONNECTION_ID = p_connectionid and table_id = reftable_id_fk_id ;

  v_newid MD_CONSTRAINTS.ID%TYPE;
  v_newrow MD_CONSTRAINTS%ROWTYPE;
  v_uk_column_id md_constraint_details.column_id_fk%TYPE;
  v_reftable_id_fk_id md_constraints.reftable_id_fk%TYPE;
  v_temprow MD_CONSTRAINTS%ROWTYPE;
  v_tableName VARCHAR(4000);
BEGIN
  --  DBMS_OUTPUT.PUT_LINE(' p_connectionid : ' ||p_connectionid);
  OPEN v_reftableidfk_cur;
  FETCH v_reftableidfk_cur INTO v_reftable_id_fk_id;
  LOOP    
    EXIT WHEN v_reftableidfk_cur%NOTFOUND;
--    DBMS_OUTPUT.PUT_LINE(' LOOP1 refTable_id_fk Starts  : REFTABLE_ID_FK = ' || v_reftable_id_fk_id);  
    OPEN v_table_name_cur(v_reftable_id_fk_id);
    FETCH v_table_name_cur INTO v_tableName;
    LOOP
      EXIT WHEN v_table_name_cur%NOTFOUND;
--    DBMS_OUTPUT.PUT_LINE('Table Name = ' || v_tableName);
     FETCH v_table_name_cur INTO v_tableName;
    END LOOP; -- v_reftableidfk_cur LOOP
    CLOSE v_table_name_cur;

    -- create existing temp row of MD_CONSTRAINTS
    OPEN v_md_constraint_cur(v_reftable_id_fk_id);
    FETCH v_md_constraint_cur INTO v_temprow;
    LOOP  
      EXIT WHEN v_md_constraint_cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(' LOOP2 : MD_Constraints Starts');
      v_newrow.ID              := NULL;
      v_newrow.LANGUAGE        := v_temprow.LANGUAGE;
      v_newrow.TABLE_ID_FK     := v_reftable_id_fk_id;
      v_newrow.REFTABLE_ID_FK  := NULL;
      v_newrow.CONSTRAINT_TYPE := 'UNIQUE';
      v_newrow.NAME            := 'UK_' || SUBSTR(v_tableName, 1, 27) ;
      --   INSERT INTO MD_CONSTRAINT values v_newrow RETURNING ID INTO v_newid;
      INSERT INTO MD_CONSTRAINTS ( id,NAME,CONSTRAINT_TYPE,TABLE_ID_FK,REFTABLE_ID_FK, LANGUAGE)
             VALUES (v_newrow.ID,v_newrow.NAME,v_newrow.CONSTRAINT_TYPE,v_newrow.TABLE_ID_FK,v_newrow.REFTABLE_ID_FK, v_newrow.LANGUAGE)
             RETURNING ID INTO v_newid;

--      DBMS_OUTPUT.PUT_LINE('New Constraints Name ' || v_newrow.NAME|| ' v_newid = ' || v_newid);   
      OPEN v_uk_columns_cur(v_reftable_id_fk_id);
      FETCH v_uk_columns_cur INTO v_uk_column_id;
      LOOP
        EXIT WHEN v_uk_columns_cur%NOTFOUND;
--       DBMS_OUTPUT.PUT_LINE(' LOOP3 : MD_Constraints_Details Starts');
--       DBMS_OUTPUT.PUT_LINE('v_uk_column_id = ' || v_uk_column_id);

        INSERT INTO MD_CONSTRAINT_DETAILS (CONSTRAINT_ID_FK,REF_FLAG,COLUMN_ID_FK,DETAIL_ORDER)
               VALUES (v_newid,'N',v_uk_column_id,1);
    FETCH v_uk_columns_cur INTO v_uk_column_id;
--    DBMS_OUTPUT.PUT_LINE(' LOOP3 : MD_Constraints_Details Ends');
      END LOOP;
      CLOSE v_uk_columns_cur;

      INSERT INTO MD_DERIVATIVES (SRC_ID,SRC_TYPE,DERIVED_ID,DERIVED_TYPE,DERIVED_CONNECTION_ID_FK,ORIGINAL_IDENTIFIER,NEW_IDENTIFIER,DERIVED_OBJECT_NAMESPACE,DERIVATIVE_REASON,ENABLED)
             VALUES (v_newid,'MD_CONSTRAINTS',v_newid,'MD_CONSTRAINTS',p_connectionid,v_newrow.NAME, v_newrow.NAME,C_NS_CONSTRAINTS || TO_CHAR(p_connectionid),C_CONNECTIONTYPE_SCRATCH,'Y');

      FETCH v_md_constraint_cur INTO v_temprow;
--      DBMS_OUTPUT.PUT_LINE(' LOOP2 : MD_Constraints Ends');
    END LOOP;
    CLOSE v_md_constraint_cur;
    FETCH v_reftableidfk_cur INTO v_reftable_id_fk_id;
--      DBMS_OUTPUT.PUT_LINE(' LOOP1 refTable_id_fk Ends');
  COMMIT;
  END LOOP; -- v_reftableidfk_cur LOOP
  CLOSE v_reftableidfk_cur;
  COMMIT;
END uniquekey_constraint_columns;


PROCEDURE RefreshLineCountViews(p_connectionId MD_CONNECTIONS.ID%TYPE DEFAULT NULL)
IS
BEGIN
	 	UPDATE (select s.*, ltrim(rtrim(s.native_sql,' ' ||'  '|| chr(10)||chr(13)),' ' ||'  '|| chr(10)||chr(13)) trimmed from md_stored_programs s)  x
	 	SET LINECOUNT = LENGTH(trimmed) -  LENGTH(replace(trimmed,chr(10))) +1
	 	WHERE linecount IS NULL;

	 	UPDATE (select s.*, ltrim(rtrim(s.native_sql,' ' ||'  '|| chr(10)||chr(13)),' ' ||'  '|| chr(10)||chr(13)) trimmed from md_views s)  x
	 	SET LINECOUNT = LENGTH(trimmed) -  LENGTH(replace(trimmed,chr(10))) +1
	 	WHERE linecount IS NULL;

	 	UPDATE (select s.*, ltrim(rtrim(s.native_sql,' ' ||'  '|| chr(10)||chr(13)),' ' ||'  '|| chr(10)||chr(13)) trimmed from md_triggers s)  x
	 	SET LINECOUNT = LENGTH(trimmed) -  LENGTH(replace(trimmed,chr(10))) +1 
	 	WHERE linecount IS NULL;
END;

FUNCTION gatherConnectionStats(p_connectionId MD_CONNECTIONS.ID%TYPE,p_comments MD_CONNECTIONS.COMMENTS%TYPE) RETURN NUMBER
IS
	v_numCatalogs INTEGER := 0;
	v_numColumns INTEGER := 0;
	v_numConstraints INTEGER := 0;
	v_numGroups INTEGER := 0;
	v_numRoles INTEGER := 0;
	v_numIndexes INTEGER := 0;
	v_numOtherObjects INTEGER := 0;
	v_numPackages INTEGER := 0;
	v_numPrivileges INTEGER := 0;
	v_numSchemas INTEGER := 0;
	v_numSequences INTEGER := 0;
	v_numStoredPrograms INTEGER := 0;
	v_numSynonyms INTEGER := 0;
	v_numTables INTEGER := 0;
	v_numTableSpaces INTEGER := 0;
	v_numTriggers INTEGER := 0;
	v_numUserDefinedDataTypes INTEGER := 0;
	v_numUsers INTEGER := 0;
	v_numViews INTEGER := 0;
BEGIN
	SELECT /* APEX684f1a */  COUNT(*) INTO v_numCatalogs FROM MD_CATALOGS  WHERE CONNECTION_ID_FK = p_connectionId;
	SELECT /* APEXbcefbc */  COUNT(*) INTO v_numColumns FROM MD_COLUMNS WHERE TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX904862 */  COUNT(*) INTO v_numConstraints FROM MD_CONSTRAINTS WHERE  TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX4f89b0 */  COUNT(*) INTO v_numGroups FROM MD_GROUPS WHERE GROUP_FLAG = 'G' AND SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId); 
	SELECT /* APEXbfdab1 */  COUNT(*) INTO v_numRoles FROM MD_GROUPS WHERE GROUP_FLAG = 'R' AND SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXba0b46 */  COUNT(*) INTO v_numIndexes FROM MD_INDEXES  WHERE TABLE_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXca8c7c */  COUNT(*) INTO v_numOtherObjects FROM MD_OTHER_OBJECTS WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX7b197e */  COUNT(*) INTO v_numPackages FROM MD_PACKAGES WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);  
	SELECT /* APEX3f3821 */  COUNT(*) INTO v_numPrivileges FROM MD_PRIVILEGES WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXa9bb8b */  COUNT(*) INTO v_numSchemas FROM MD_SCHEMAS WHERE CATALOG_ID_FK IN (SELECT CATALOG_ID FROM MGV_ALL_CATALOGS WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXa0cce3 */  COUNT(*) INTO v_numSequences FROM MD_SEQUENCES WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXa3dbd9 */  COUNT(*) INTO v_numStoredPrograms FROM MD_STORED_PROGRAMS WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXf14b61 */  COUNT(*) INTO v_numSynonyms FROM MD_SYNONYMS WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX552ab8 */  COUNT(*) INTO v_numTables FROM MD_TABLES WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX133fb1 */  COUNT(*) INTO v_numTableSpaces FROM MD_TABLESPACES WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX659902 */  COUNT(*) INTO v_numTriggers FROM MD_TRIGGERS WHERE TABLE_OR_VIEW_ID_FK IN (SELECT TABLE_ID FROM MGV_ALL_TABLES WHERE CONNECTION_ID = p_connectionId
                                                                                          UNION SELECT VIEW_ID FROM MGV_ALL_VIEWS WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX0c1a9d */  COUNT(*) INTO v_numUserDefinedDataTypes FROM MD_USER_DEFINED_DATA_TYPES WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEX1c2846 */  COUNT(*) INTO v_numUsers FROM MD_USERS WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
	SELECT /* APEXcaa4e7 */  COUNT(*) INTO v_numViews FROM MD_VIEWS WHERE SCHEMA_ID_FK IN (SELECT SCHEMA_ID FROM MGV_ALL_SCHEMA WHERE CONNECTION_ID = p_connectionId);
  	UPDATE /* APEX26ec73 */  MD_CONNECTIONS SET  
		NUM_CATALOGS = v_numCatalogs,
		NUM_COLUMNS = v_numColumns,
		NUM_CONSTRAINTS = v_numConstraints,
		NUM_GROUPS = v_numGroups,
		NUM_ROLES = v_numRoles,
		NUM_INDEXES = v_numIndexes,
		NUM_OTHER_OBJECTS = v_numOtherObjects,
		NUM_PACKAGES = v_numPackages,
		NUM_PRIVILEGES = v_numPrivileges,
		NUM_SCHEMAS = v_numSchemas,
		NUM_SEQUENCES = v_numSequences,
		NUM_STORED_PROGRAMS = v_numStoredPrograms,
		NUM_SYNONYMS = v_numSynonyms,
		NUM_TABLES = v_numTables,
		NUM_TABLESPACES = v_numTableSpaces,
		NUM_TRIGGERS = v_numTriggers,
		NUM_USER_DEFINED_DATA_TYPES = v_numUserDefinedDataTypes,
		num_users = v_numusers,
        num_views = v_numviews,
        COMMENTS = COMMENTS || p_comments    
	WHERE ID = p_connectionId;
	COMMIT;
    RefreshLineCountViews(p_connectionId);
	COMMIT;
	RETURN 0;
END gatherConnectionStats;

--
-- Procedures that start with "insert_*" insert a copy of MD_* values into MD_DERIVATIVES table.
-- MD_* are MD_COLUMNS, MD_CONSTRAINTS, MD_TABLES, MD_TRIGGERS, MD_INDEXES, MD_SEQUENCES, MD_STORED_PROGRAMS 
-- AND MD_VIEWS
--
PROCEDURE insert_all_columns(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_tableid MD_TABLES.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_COLUMNS%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_COLUMNS WHERE TABLE_ID_FK = ' || p_tableid;
  v_newName MD_COLUMNS.COLUMN_NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;
BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.COLUMN_NAME);
    if v_row.COLUMN_NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEXabeb00 */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_COLUMNS, v_row.id, C_OBJECTTYPE_COLUMNS, p_connectionid, v_transformed,
                  v_row.COLUMN_NAME, v_newName, C_OBJECTTYPE_COLUMNS || TO_CHAR(p_tableid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;
END insert_all_columns;

PROCEDURE insert_all_indexes(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_tableid MD_TABLES.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_INDEXES%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_INDEXES WHERE MD_INDEXES.TABLE_ID_FK = ' || p_tableid;
  v_newName MD_INDEXES.INDEX_NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;
BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.INDEX_NAME);
    if v_row.INDEX_NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEXb29adb */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_INDEXES, v_row.id, C_OBJECTTYPE_INDEXES, p_connectionid, v_transformed,
                  v_row.INDEX_NAME, v_newName, C_OBJECTTYPE_INDEXES || TO_CHAR(p_tableid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;
END insert_all_indexes;

PROCEDURE insert_all_table_triggers(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                     p_tableid MD_TABLES.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_TRIGGERS%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_TRIGGERS WHERE MD_TRIGGERS.TABLE_OR_VIEW_ID_FK = ' || p_tableid;
  v_newName MD_TRIGGERS.TRIGGER_NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;
BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.TRIGGER_NAME);
    if v_row.TRIGGER_NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEXc6009e */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_TRIGGERS, v_row.id, C_OBJECTTYPE_TRIGGERS, p_connectionid, v_transformed,
                  v_row.TRIGGER_NAME, v_newName, C_NS_DB_TRIGGERS || TO_CHAR(p_tableid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;
END insert_all_table_triggers;

PROCEDURE insert_all_constraints(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                 p_tableid MD_TABLES.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_CONSTRAINTS%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_CONSTRAINTS WHERE MD_CONSTRAINTS.TABLE_ID_FK = ' || p_tableid;
  v_newName MD_CONSTRAINTS.NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;
BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.NAME);
    if v_row.NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEXc6056b */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_CONSTRAINTS, v_row.id, C_OBJECTTYPE_CONSTRAINTS, p_connectionid, v_transformed,
                  v_row.NAME, v_newName, C_NS_CONSTRAINTS || TO_CHAR(p_tableid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;
END insert_all_constraints;


PROCEDURE insert_all_tables_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                    p_schemaid MD_SCHEMAS.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_TABLES%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_TABLES where SCHEMA_ID_FK = ' || p_schemaid;
  v_newName MD_TABLES.TABLE_NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;

BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.TABLE_NAME);
    if v_row.TABLE_NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEXa42d18 */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_TABLES, v_row.id, C_OBJECTTYPE_TABLES, p_connectionid, v_transformed,
                  v_row.TABLE_NAME, v_newName, C_NS_SCHEMA_OBJS || TO_CHAR(p_schemaid), C_CONNECTIONTYPE_SCRATCH);

     insert_all_columns(p_connectionid, v_row.id);
     insert_all_indexes(p_connectionid, v_row.id);
     insert_all_table_triggers(p_connectionid, v_row.id);
     insert_all_constraints(p_connectionid, v_row.id);

  END LOOP;
  close cv_curs;	
END insert_all_tables_cascade;

PROCEDURE insert_all_views(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                    p_schemaid MD_SCHEMAS.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_VIEWS%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_VIEWS WHERE SCHEMA_ID_FK = ' || p_schemaid;
  v_newName MD_VIEWS.VIEW_NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;

BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.VIEW_NAME);
    if v_row.VIEW_NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEX367c5b */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_VIEWS, v_row.id, C_OBJECTTYPE_VIEWS, p_connectionid, v_transformed,
                  v_row.VIEW_NAME, v_newName, C_NS_SCHEMA_OBJS || TO_CHAR(p_schemaid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;	
END insert_all_views;

PROCEDURE insert_all_sequences(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                    p_schemaid MD_SCHEMAS.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_SEQUENCES%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_SEQUENCES WHERE SCHEMA_ID_FK = ' || p_schemaid;
  v_newName MD_SEQUENCES.NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;

BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.NAME);
    if v_row.NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEX898986 */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_SEQUENCES, v_row.id, C_OBJECTTYPE_SEQUENCES, p_connectionid, v_transformed,
                  v_row.NAME, v_newName, C_NS_SCHEMA_OBJS || TO_CHAR(p_schemaid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;	
END insert_all_sequences;

PROCEDURE insert_all_unpackaged_sps(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                    p_schemaid MD_SCHEMAS.ID%TYPE)
IS
  cv_curs REF_CURSOR;
  v_row MD_STORED_PROGRAMS%ROWTYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_STORED_PROGRAMS WHERE SCHEMA_ID_FK = ' || p_schemaid || ' AND PACKAGE_ID_FK IS NULL';
  v_newName MD_STORED_PROGRAMS.NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;

BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.NAME);
    if v_row.NAME <> v_newName then
       v_transformed := C_TRANSFORMED_TRUE;
    end if;

    INSERT /* APEX5765e9 */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_row.id, C_OBJECTTYPE_STORED_PROGRAMS, v_row.id, C_OBJECTTYPE_STORED_PROGRAMS, p_connectionid, v_transformed,
                  v_row.NAME, v_newName, C_NS_SCHEMA_OBJS || TO_CHAR(p_schemaid), C_CONNECTIONTYPE_SCRATCH);

  END LOOP;
  close cv_curs;	
END insert_all_unpackaged_sps;


PROCEDURE insert_all_schobjs_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                            p_schemaid MD_SCHEMAS.ID%TYPE)
IS 
BEGIN
  insert_all_tables_cascade(p_connectionid, p_schemaid);
  insert_all_views(p_connectionid, p_schemaid);
  insert_all_sequences(p_connectionid, p_schemaid);
  insert_all_unpackaged_sps(p_connectionid, p_schemaid);
END insert_all_schobjs_cascade;	  


PROCEDURE insert_catalogs_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE,
                                  p_catalogid MD_CATALOGS.ID%TYPE)
IS
  cv_curs REF_CURSOR; 
  v_selectStmt VARCHAR2(4000) := 'SELECT a.id schema_id, A.name schema_name, b.id catalog_id, B.CATALOG_NAME, B.DUMMY_FLAG, A.type, A.character_set, A.version_tag 
      FROM MD_SCHEMAS A, MD_CATALOGS B
      WHERE 
      	A.CATALOG_ID_FK = B.ID 
        AND B.ID =' || p_catalogid  || 
        ' AND CONNECTION_ID_FK = ' || p_connectionid ;
  v_derivedRec  DERIVATIVE_REC;
  v_newName MD_SCHEMAS.NAME%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;
BEGIN
   OPEN cv_curs FOR v_selectStmt;
   LOOP
     FETCH cv_curs INTO v_derivedRec;
     EXIT WHEN cv_curs%NOTFOUND;

     if v_derivedRec.dummy_flag  <> C_DUMMYFLAG_TRUE then
        v_newName := CREATE_SCHEMANAME(v_derivedRec.schema_name , v_derivedRec.catalog_name);
        v_transformed := C_TRANSFORMED_TRUE;
     else
	    v_newName := v_derivedRec.schema_name;
     end if;

     if v_newName <> MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_newName) then
        v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_newName);
        v_transformed := C_TRANSFORMED_TRUE;
     end if;

     INSERT /* APEXd903b8 */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES (v_derivedRec.schema_id, C_OBJECTTYPE_SCHEMAS, v_derivedRec.schema_id, C_OBJECTTYPE_SCHEMAS, p_connectionid, v_transformed,
                  v_derivedRec.schema_name, v_newName, C_NS_DATABASE, C_CONNECTIONTYPE_SCRATCH);

     INSERT /* APEXaf596d */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                  ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_derivedRec.catalog_id, C_OBJECTTYPE_CATALOGS, v_derivedRec.catalog_id, C_OBJECTTYPE_SCHEMAS, p_connectionid, v_transformed, 
                  v_derivedRec.catalog_name, v_newName, NULL, C_CONNECTIONTYPE_SCRATCH);

     insert_all_schobjs_cascade(p_connectionid, v_derivedRec.schema_id);

   END LOOP;
   close cv_curs;
END insert_catalogs_cascade;


PROCEDURE insert_connection_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE)
IS
  v_connectionsRow MD_CONNECTIONS%ROWTYPE;
  v_origName MD_CONNECTIONS.NAME%TYPE;
  v_newName MD_CONNECTIONS.NAME%TYPE;
  v_id MD_CONNECTIONS.ID%TYPE;
  v_catid MD_CATALOGS.ID%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE := NULL;
  cv_curs REF_CURSOR;

BEGIN
  SELECT /* APEX953cea */  * INTO v_connectionsRow from MD_CONNECTIONS WHERE "ID" = p_connectionid;
      v_origName := v_connectionsRow.NAME;
      v_newName := v_origName;
      v_id := v_connectionsRow.ID;

      if v_newName <> MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_newName) then
        v_newName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_newName);
        v_transformed := C_TRANSFORMED_TRUE;
      end if;

      INSERT /* APEXda2f55 */  INTO 
          MD_DERIVATIVES(SRC_ID, SRC_TYPE, DERIVED_ID, DERIVED_TYPE, DERIVED_CONNECTION_ID_FK, TRANSFORMED,
                      ORIGINAL_IDENTIFIER, NEW_IDENTIFIER, DERIVED_OBJECT_NAMESPACE, DERIVATIVE_REASON)
          VALUES(v_id , C_OBJECTTYPE_CONNECTIONS, v_id, C_OBJECTTYPE_CONNECTIONS, v_id, v_transformed, 
                      v_origName, v_newName, '', C_CONNECTIONTYPE_SCRATCH);

  OPEN cv_curs FOR 'SELECT id from MD_CATALOGS where connection_id_fk ='|| v_connectionsRow.id;
  LOOP
    FETCH cv_curs INTO v_catid;
    EXIT WHEN cv_curs%NOTFOUND;

      insert_catalogs_cascade(v_id, v_catid);
   END LOOP;   
END insert_connection_cascade;

PROCEDURE populate_derivatives_table(p_connectionid MD_CONNECTIONS.ID%TYPE)
IS
BEGIN
  insert_connection_cascade(p_connectionid);
END populate_derivatives_table;

--
-- reverts NEW_IDENTIFIER values back to their default(derived) values in MD_DERIVATIVES table.
--
PROCEDURE revert_derivatives_table(p_connectionid MD_CONNECTIONS.ID%TYPE)
IS
  cv_curs REF_CURSOR;  
  v_row MD_DERIVATIVES%ROWTYPE;
  v_origName MD_DERIVATIVES.ORIGINAL_IDENTIFIER%TYPE;
  v_derivedName MD_DERIVATIVES.NEW_IDENTIFIER%TYPE;
  v_transformed MD_DERIVATIVES.TRANSFORMED%TYPE;
  v_selectStmt VARCHAR2(4000) := 'SELECT * FROM MD_DERIVATIVES 
         WHERE DERIVED_CONNECTION_ID_FK = ' || p_connectionid ;
BEGIN
  OPEN cv_curs FOR v_selectStmt;
  LOOP
    FETCH cv_curs INTO v_row;
    EXIT WHEN cv_curs%NOTFOUND;

    v_transformed := NULL;
    v_derivedName := MIGRATION_TRANSFORMER.TRANSFORM_IDENTIFIER(v_row.ORIGINAL_IDENTIFIER);
    if v_row.NEW_IDENTIFIER <> v_derivedName then
      if v_row.ORIGINAL_IDENTIFIER <> v_derivedName then
         v_transformed := C_TRANSFORMED_TRUE;
      end if;

      UPDATE /* APEX5a1f31 */  MD_DERIVATIVES SET TRANSFORMED = v_transformed, NEW_IDENTIFIER = v_derivedName WHERE 
         SRC_ID = v_row.SRC_ID and DERIVED_CONNECTION_ID_FK = p_connectionid ;
    end if;
  END LOOP;
  CLOSE cv_curs;
END revert_derivatives_table;


-- One time initialisation
begin
NULL;
end;
/