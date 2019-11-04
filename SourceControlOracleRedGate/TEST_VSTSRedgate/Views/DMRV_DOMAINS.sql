CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_domains (domain_id,domain_name,ovid,synonyms,logical_type_id,logical_type_ovid,t_size,t_precision,t_scale,native_type,lt_name,design_id,design_ovid,design_name,default_value,unit_of_measure,char_units) AS
select  Domain_ID, Domain_Name, OVID, Synonyms, Logical_Type_ID, Logical_Type_OVID, T_Size, T_Precision, T_Scale, Native_Type, LT_Name, Design_ID, Design_OVID, Design_Name, Default_Value, Unit_Of_Measure, Char_Units from DMRS_DOMAINS;