CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."MIGRATION"
AS

-- Public functions
FUNCTION copy_connection_cascade(p_connectionid MD_CONNECTIONS.ID%TYPE, p_filter_set MIGR_FILTER_SET := NULL,p_scratchModel BOOLEAN := FALSE) RETURN NUMBER;
FUNCTION transform_all_identifiers(p_connectionid MD_CONNECTIONS.ID%TYPE, p_prefixName VARCHAR2, p_scratchModel BOOLEAN := FALSE) RETURN NAME_AND_COUNT_ARRAY;
FUNCTION transform_datatypes(p_connectionid MD_CONNECTIONS.ID%TYPE, p_mapid MIGR_DATATYPE_TRANSFORM_MAP.ID%TYPE, p_numbytesperchar INTEGER,  p_is12c VARCHAR2 := 'N') RETURN NUMBER;
FUNCTION transform_identity_columns(p_connectionid MD_CONNECTIONS.ID%TYPE, p_is12c VARCHAR2 := 'N') RETURN NUMBER;
FUNCTION transform_rewrite_trigger(p_connectionid MD_CONNECTIONS.ID%TYPE) RETURN NUMBER;
FUNCTION gatherConnectionStats(p_connectionId MD_CONNECTIONS.ID%TYPE,p_comments MD_CONNECTIONS.COMMENTS%TYPE) RETURN NUMBER;
PROCEDURE transform_clashes(p_connectionid MD_CONNECTIONS.ID%TYPE, p_scratchModel BOOLEAN := FALSE);
PROCEDURE populate_derivatives_table(p_connectionid MD_CONNECTIONS.ID%TYPE);
PROCEDURE revert_derivatives_table(p_connectionid MD_CONNECTIONS.ID%TYPE);
PROCEDURE remove_duplicate_foreignkeys(p_connectionid MD_CONNECTIONS.ID%TYPE);
PROCEDURE remove_unwanted_uniquekeys(p_connectionid MD_CONNECTIONS.ID%TYPE);
PROCEDURE uniquekey_constraint_columns(p_connectionid MD_CONNECTIONS.ID%TYPE);
END;
/