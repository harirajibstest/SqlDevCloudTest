CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_distinct_types (design_id,design_ovid,design_name,distinct_type_id,distinct_type_ovid,distinct_type_name,logical_type_id,logical_type_ovid,logical_type_name,t_size,t_precision,t_scale) AS
select  Design_ID, Design_OVID, Design_Name, Distinct_Type_ID, Distinct_Type_OVID, Distinct_Type_Name, Logical_Type_ID, Logical_Type_OVID, Logical_Type_Name, T_Size, T_Precision, T_Scale from DMRS_DISTINCT_TYPES;