CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_logical_types (design_id,design_ovid,design_name,logical_type_id,ovid,lt_name) AS
select  Design_ID, Design_OVID, Design_Name, Logical_Type_ID, OVID, LT_Name from DMRS_LOGICAL_TYPES;