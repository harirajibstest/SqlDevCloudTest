CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_cubes (cube_id,cube_name,cube_ovid,model_id,model_name,model_ovid,part_dimension_id,part_dimension_name,part_dimension_ovid,part_hierarchy_id,part_hierarchy_name,part_hierarchy_ovid,part_level_id,part_level_name,part_level_ovid,full_cube_slice_id,full_cube_slice_name,full_cube_slice_ovid,oracle_long_name,oracle_plural_name,oracle_short_name,is_compressed_composites,is_global_composites,is_partitioned,is_virtual,part_description,description,design_ovid) AS
select  Cube_ID, Cube_Name, Cube_OVID, Model_ID, Model_Name, Model_OVID, Part_Dimension_ID, Part_Dimension_Name, Part_Dimension_OVID, Part_Hierarchy_ID, Part_Hierarchy_Name, Part_Hierarchy_OVID, Part_Level_ID, Part_Level_Name, Part_Level_OVID, Full_Cube_Slice_ID, Full_Cube_Slice_Name, Full_Cube_Slice_OVID, Oracle_Long_Name, Oracle_Plural_Name, Oracle_Short_Name, Is_Compressed_Composites, Is_Global_Composites, Is_Partitioned, Is_Virtual, Part_Description, Description, Design_OVID from DMRS_CUBES;