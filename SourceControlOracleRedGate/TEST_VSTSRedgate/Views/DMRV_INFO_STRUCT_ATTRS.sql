CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_info_struct_attrs (info_structure_id,info_structure_ovid,info_structure_name,attribute_id,attribute_ovid,attribute_name,entity_id,entity_ovid,entity_name,design_ovid) AS
select  Info_Structure_ID, Info_Structure_OVID, Info_Structure_Name, Attribute_ID, Attribute_OVID, Attribute_Name, Entity_ID, Entity_OVID, Entity_Name, Design_OVID from DMRS_INFO_STRUCT_ATTRS;