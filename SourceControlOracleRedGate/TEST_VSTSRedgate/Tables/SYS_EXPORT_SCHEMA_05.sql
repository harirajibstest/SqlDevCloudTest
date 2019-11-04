CREATE TABLE "TEST_VSTSRedgate".sys_export_schema_05 (
  abort_step NUMBER,
  ancestor_process_order NUMBER,
  base_object_name VARCHAR2(30 BYTE),
  base_object_schema VARCHAR2(30 BYTE),
  base_object_type VARCHAR2(30 BYTE),
  base_process_order NUMBER,
  block_size NUMBER,
  cluster_ok NUMBER,
  completed_bytes NUMBER,
  completed_rows NUMBER,
  completion_time DATE,
  control_queue VARCHAR2(30 BYTE),
  creation_level NUMBER,
  cumulative_time NUMBER,
  data_buffer_size NUMBER,
  data_io NUMBER,
  dataobj_num NUMBER,
  "DB_VERSION" VARCHAR2(60 BYTE),
  "DEGREE" NUMBER,
  domain_process_order NUMBER,
  dump_allocation NUMBER,
  dump_fileid NUMBER,
  dump_length NUMBER,
  dump_orig_length NUMBER,
  dump_position NUMBER,
  "DUPLICATE" NUMBER,
  elapsed_time NUMBER,
  error_count NUMBER,
  extend_size NUMBER,
  file_max_size NUMBER,
  file_name VARCHAR2(4000 BYTE),
  file_type NUMBER,
  flags NUMBER,
  grantor VARCHAR2(30 BYTE),
  granules NUMBER,
  guid RAW(16),
  in_progress CHAR,
  "INSTANCE" VARCHAR2(60 BYTE),
  instance_id NUMBER,
  is_default NUMBER,
  job_mode VARCHAR2(21 BYTE),
  job_version VARCHAR2(60 BYTE),
  last_file NUMBER,
  last_update DATE,
  load_method NUMBER,
  metadata_buffer_size NUMBER,
  metadata_io NUMBER,
  "NAME" VARCHAR2(30 BYTE),
  object_int_oid VARCHAR2(32 BYTE),
  object_long_name VARCHAR2(4000 BYTE),
  object_name VARCHAR2(200 BYTE),
  object_number NUMBER,
  object_path_seqno NUMBER,
  object_row NUMBER,
  object_schema VARCHAR2(30 BYTE),
  object_tablespace VARCHAR2(30 BYTE),
  object_type VARCHAR2(30 BYTE),
  object_type_path VARCHAR2(200 BYTE),
  old_value VARCHAR2(4000 BYTE),
  operation VARCHAR2(8 BYTE),
  option_tag VARCHAR2(30 BYTE),
  orig_base_object_schema VARCHAR2(30 BYTE),
  original_object_name VARCHAR2(128 BYTE),
  original_object_schema VARCHAR2(30 BYTE),
  packet_number NUMBER,
  parallelization NUMBER,
  parent_process_order NUMBER,
  partition_name VARCHAR2(30 BYTE),
  phase NUMBER,
  platform VARCHAR2(101 BYTE),
  process_name VARCHAR2(30 BYTE),
  process_order NUMBER,
  processing_state CHAR,
  processing_status CHAR,
  property NUMBER,
  queue_tabnum NUMBER,
  remote_link VARCHAR2(128 BYTE),
  "SCN" NUMBER,
  "SEED" NUMBER,
  service_name VARCHAR2(64 BYTE),
  size_estimate NUMBER,
  start_time DATE,
  "STATE" VARCHAR2(12 BYTE),
  status_queue VARCHAR2(30 BYTE),
  subpartition_name VARCHAR2(30 BYTE),
  target_xml_clob CLOB,
  tde_rewrapped_key RAW(2000),
  template_table VARCHAR2(30 BYTE),
  timezone VARCHAR2(64 BYTE),
  total_bytes NUMBER,
  trigflag NUMBER,
  unload_method NUMBER,
  user_directory VARCHAR2(4000 BYTE),
  user_file_name VARCHAR2(4000 BYTE),
  user_name VARCHAR2(30 BYTE),
  value_n NUMBER,
  value_t VARCHAR2(4000 BYTE),
  "VERSION" NUMBER,
  work_item VARCHAR2(21 BYTE),
  xml_clob CLOB
);
COMMENT ON TABLE "TEST_VSTSRedgate".sys_export_schema_05 IS 'Data Pump Master Table EXPORT                         SCHEMA                        ';