CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_contact_res_locators (contact_id,contact_ovid,contact_name,resource_locator_id,resource_locator_ovid,resource_locator_name,design_ovid) AS
select  Contact_ID, Contact_OVID, Contact_Name, Resource_Locator_ID, Resource_Locator_OVID, Resource_Locator_Name, Design_OVID from DMRS_CONTACT_RES_LOCATORS;