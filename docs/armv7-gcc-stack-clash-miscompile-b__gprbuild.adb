pragma Warnings (Off);
pragma Ada_95;
pragma Source_File_Name (ada_main, Spec_File_Name => "b__gprbuild.ads");
pragma Source_File_Name (ada_main, Body_File_Name => "b__gprbuild.adb");
pragma Suppress (Overflow_Check);

with System.Restrictions;
with Ada.Exceptions;

package body ada_main is

   E075 : Short_Integer; pragma Import (Ada, E075, "system__os_lib_E");
   E008 : Short_Integer; pragma Import (Ada, E008, "ada__exceptions_E");
   E013 : Short_Integer; pragma Import (Ada, E013, "system__soft_links_E");
   E024 : Short_Integer; pragma Import (Ada, E024, "system__exception_table_E");
   E040 : Short_Integer; pragma Import (Ada, E040, "ada__containers_E");
   E070 : Short_Integer; pragma Import (Ada, E070, "ada__io_exceptions_E");
   E031 : Short_Integer; pragma Import (Ada, E031, "ada__numerics_E");
   E055 : Short_Integer; pragma Import (Ada, E055, "ada__strings_E");
   E057 : Short_Integer; pragma Import (Ada, E057, "ada__strings__maps_E");
   E060 : Short_Integer; pragma Import (Ada, E060, "ada__strings__maps__constants_E");
   E045 : Short_Integer; pragma Import (Ada, E045, "interfaces__c_E");
   E025 : Short_Integer; pragma Import (Ada, E025, "system__exceptions_E");
   E086 : Short_Integer; pragma Import (Ada, E086, "system__object_reader_E");
   E050 : Short_Integer; pragma Import (Ada, E050, "system__dwarf_lines_E");
   E020 : Short_Integer; pragma Import (Ada, E020, "system__soft_links__initialize_E");
   E039 : Short_Integer; pragma Import (Ada, E039, "system__traceback__symbolic_E");
   E006 : Short_Integer; pragma Import (Ada, E006, "ada__assertions_E");
   E114 : Short_Integer; pragma Import (Ada, E114, "ada__strings__utf_encoding_E");
   E184 : Short_Integer; pragma Import (Ada, E184, "gnat_E");
   E194 : Short_Integer; pragma Import (Ada, E194, "interfaces__c__strings_E");
   E318 : Short_Integer; pragma Import (Ada, E318, "system__task_info_E");
   E312 : Short_Integer; pragma Import (Ada, E312, "system__task_primitives__operations_E");
   E122 : Short_Integer; pragma Import (Ada, E122, "ada__tags_E");
   E112 : Short_Integer; pragma Import (Ada, E112, "ada__strings__text_buffers_E");
   E110 : Short_Integer; pragma Import (Ada, E110, "ada__streams_E");
   E177 : Short_Integer; pragma Import (Ada, E177, "system__file_control_block_E");
   E133 : Short_Integer; pragma Import (Ada, E133, "system__finalization_root_E");
   E108 : Short_Integer; pragma Import (Ada, E108, "ada__finalization_E");
   E174 : Short_Integer; pragma Import (Ada, E174, "system__file_io_E");
   E257 : Short_Integer; pragma Import (Ada, E257, "ada__streams__stream_io_E");
   E181 : Short_Integer; pragma Import (Ada, E181, "system__storage_pools_E");
   E222 : Short_Integer; pragma Import (Ada, E222, "system__storage_pools__subpools_E");
   E159 : Short_Integer; pragma Import (Ada, E159, "ada__strings__unbounded_E");
   E450 : Short_Integer; pragma Import (Ada, E450, "system__regpat_E");
   E139 : Short_Integer; pragma Import (Ada, E139, "ada__calendar_E");
   E274 : Short_Integer; pragma Import (Ada, E274, "ada__calendar__delays_E");
   E145 : Short_Integer; pragma Import (Ada, E145, "ada__calendar__time_zones_E");
   E356 : Short_Integer; pragma Import (Ada, E356, "ada__real_time_E");
   E183 : Short_Integer; pragma Import (Ada, E183, "ada__text_io_E");
   E415 : Short_Integer; pragma Import (Ada, E415, "ada__text_io__text_streams_E");
   E218 : Short_Integer; pragma Import (Ada, E218, "gnat__byte_order_mark_E");
   E261 : Short_Integer; pragma Import (Ada, E261, "gnat__calendar_E");
   E187 : Short_Integer; pragma Import (Ada, E187, "gnat__directory_operations_E");
   E237 : Short_Integer; pragma Import (Ada, E237, "gnat__dynamic_htables_E");
   E524 : Short_Integer; pragma Import (Ada, E524, "gnat__rewrite_data_E");
   E364 : Short_Integer; pragma Import (Ada, E364, "gnat__secure_hashes_E");
   E366 : Short_Integer; pragma Import (Ada, E366, "gnat__secure_hashes__md5_E");
   E362 : Short_Integer; pragma Import (Ada, E362, "gnat__md5_E");
   E253 : Short_Integer; pragma Import (Ada, E253, "gnat__string_split_E");
   E264 : Short_Integer; pragma Import (Ada, E264, "gnat__calendar__time_io_E");
   E239 : Short_Integer; pragma Import (Ada, E239, "system__pool_global_E");
   E445 : Short_Integer; pragma Import (Ada, E445, "gnat__expect_E");
   E267 : Short_Integer; pragma Import (Ada, E267, "gnat__sockets_E");
   E270 : Short_Integer; pragma Import (Ada, E270, "gnat__sockets__poll_E");
   E279 : Short_Integer; pragma Import (Ada, E279, "gnat__sockets__thin_common_E");
   E272 : Short_Integer; pragma Import (Ada, E272, "gnat__sockets__thin_E");
   E518 : Short_Integer; pragma Import (Ada, E518, "system__random_seed_E");
   E179 : Short_Integer; pragma Import (Ada, E179, "system__regexp_E");
   E137 : Short_Integer; pragma Import (Ada, E137, "ada__directories_E");
   E338 : Short_Integer; pragma Import (Ada, E338, "system__tasking__initialization_E");
   E328 : Short_Integer; pragma Import (Ada, E328, "system__tasking__protected_objects_E");
   E334 : Short_Integer; pragma Import (Ada, E334, "system__tasking__protected_objects__entries_E");
   E346 : Short_Integer; pragma Import (Ada, E346, "system__tasking__queuing_E");
   E352 : Short_Integer; pragma Import (Ada, E352, "system__tasking__stages_E");
   E382 : Short_Integer; pragma Import (Ada, E382, "unicode_E");
   E540 : Short_Integer; pragma Import (Ada, E540, "gprexch_E");
   E399 : Short_Integer; pragma Import (Ada, E399, "sax__htable_E");
   E403 : Short_Integer; pragma Import (Ada, E403, "sax__pointers_E");
   E499 : Short_Integer; pragma Import (Ada, E499, "sax__state_machines_E");
   E470 : Short_Integer; pragma Import (Ada, E470, "schema_E");
   E395 : Short_Integer; pragma Import (Ada, E395, "unicode__ccs_E");
   E419 : Short_Integer; pragma Import (Ada, E419, "unicode__ccs__iso_8859_1_E");
   E421 : Short_Integer; pragma Import (Ada, E421, "unicode__ccs__iso_8859_15_E");
   E426 : Short_Integer; pragma Import (Ada, E426, "unicode__ccs__iso_8859_2_E");
   E429 : Short_Integer; pragma Import (Ada, E429, "unicode__ccs__iso_8859_3_E");
   E431 : Short_Integer; pragma Import (Ada, E431, "unicode__ccs__iso_8859_4_E");
   E433 : Short_Integer; pragma Import (Ada, E433, "unicode__ccs__windows_1251_E");
   E438 : Short_Integer; pragma Import (Ada, E438, "unicode__ccs__windows_1252_E");
   E391 : Short_Integer; pragma Import (Ada, E391, "unicode__ces_E");
   E401 : Short_Integer; pragma Import (Ada, E401, "sax__symbols_E");
   E468 : Short_Integer; pragma Import (Ada, E468, "sax__locators_E");
   E466 : Short_Integer; pragma Import (Ada, E466, "sax__exceptions_E");
   E393 : Short_Integer; pragma Import (Ada, E393, "unicode__ces__utf32_E");
   E441 : Short_Integer; pragma Import (Ada, E441, "unicode__ces__basic_8bit_E");
   E443 : Short_Integer; pragma Import (Ada, E443, "unicode__ces__utf16_E");
   E397 : Short_Integer; pragma Import (Ada, E397, "unicode__ces__utf8_E");
   E464 : Short_Integer; pragma Import (Ada, E464, "sax__models_E");
   E462 : Short_Integer; pragma Import (Ada, E462, "sax__attributes_E");
   E405 : Short_Integer; pragma Import (Ada, E405, "sax__utils_E");
   E378 : Short_Integer; pragma Import (Ada, E378, "dom__core_E");
   E482 : Short_Integer; pragma Import (Ada, E482, "schema__date_time_E");
   E488 : Short_Integer; pragma Import (Ada, E488, "schema__decimal_E");
   E480 : Short_Integer; pragma Import (Ada, E480, "schema__simple_types_E");
   E417 : Short_Integer; pragma Import (Ada, E417, "unicode__encodings_E");
   E413 : Short_Integer; pragma Import (Ada, E413, "dom__core__nodes_E");
   E411 : Short_Integer; pragma Import (Ada, E411, "dom__core__attrs_E");
   E474 : Short_Integer; pragma Import (Ada, E474, "dom__core__character_datas_E");
   E407 : Short_Integer; pragma Import (Ada, E407, "dom__core__documents_E");
   E409 : Short_Integer; pragma Import (Ada, E409, "dom__core__elements_E");
   E454 : Short_Integer; pragma Import (Ada, E454, "input_sources_E");
   E456 : Short_Integer; pragma Import (Ada, E456, "input_sources__file_E");
   E460 : Short_Integer; pragma Import (Ada, E460, "input_sources__strings_E");
   E458 : Short_Integer; pragma Import (Ada, E458, "sax__readers_E");
   E497 : Short_Integer; pragma Import (Ada, E497, "schema__validators_E");
   E476 : Short_Integer; pragma Import (Ada, E476, "schema__readers_E");
   E478 : Short_Integer; pragma Import (Ada, E478, "schema__schema_readers_E");
   E501 : Short_Integer; pragma Import (Ada, E501, "schema__validators__xsd_grammar_E");
   E472 : Short_Integer; pragma Import (Ada, E472, "schema__dom_readers_E");
   E190 : Short_Integer; pragma Import (Ada, E190, "gpr_E");
   E196 : Short_Integer; pragma Import (Ada, E196, "gpr__attr_E");
   E296 : Short_Integer; pragma Import (Ada, E296, "gpr__attr__pm_E");
   E200 : Short_Integer; pragma Import (Ada, E200, "gpr__cset_E");
   E206 : Short_Integer; pragma Import (Ada, E206, "gpr__debug_E");
   E198 : Short_Integer; pragma Import (Ada, E198, "gpr__err_E");
   E234 : Short_Integer; pragma Import (Ada, E234, "gpr__ext_E");
   E373 : Short_Integer; pragma Import (Ada, E373, "gpr__knowledge_E");
   E204 : Short_Integer; pragma Import (Ada, E204, "gpr__names_E");
   E226 : Short_Integer; pragma Import (Ada, E226, "gpr__osint_E");
   E244 : Short_Integer; pragma Import (Ada, E244, "gpr__ali_E");
   E202 : Short_Integer; pragma Import (Ada, E202, "gpr__erroutc_E");
   E208 : Short_Integer; pragma Import (Ada, E208, "gpr__output_E");
   E298 : Short_Integer; pragma Import (Ada, E298, "gpr__scans_E");
   E452 : Short_Integer; pragma Import (Ada, E452, "gpr__sdefault_E");
   E213 : Short_Integer; pragma Import (Ada, E213, "gpr__sinput_E");
   E246 : Short_Integer; pragma Import (Ada, E246, "gpr__snames_E");
   E300 : Short_Integer; pragma Import (Ada, E300, "gpr__strt_E");
   E241 : Short_Integer; pragma Import (Ada, E241, "gpr__tempdir_E");
   E255 : Short_Integer; pragma Import (Ada, E255, "gpr__util_E");
   E360 : Short_Integer; pragma Import (Ada, E360, "gpr__compilation_E");
   E251 : Short_Integer; pragma Import (Ada, E251, "gpr__env_E");
   E304 : Short_Integer; pragma Import (Ada, E304, "gpr__jobserver_E");
   E249 : Short_Integer; pragma Import (Ada, E249, "gpr__tree_E");
   E294 : Short_Integer; pragma Import (Ada, E294, "gpr__dect_E");
   E283 : Short_Integer; pragma Import (Ada, E283, "gpr__nmsc_E");
   E292 : Short_Integer; pragma Import (Ada, E292, "gpr__part_E");
   E302 : Short_Integer; pragma Import (Ada, E302, "gpr__proc_E");
   E281 : Short_Integer; pragma Import (Ada, E281, "gpr__conf_E");
   E503 : Short_Integer; pragma Import (Ada, E503, "gpr__version_E");
   E228 : Short_Integer; pragma Import (Ada, E228, "gpr_build_util_E");
   E520 : Short_Integer; pragma Import (Ada, E520, "gpr__compilation__protocol_E");
   E526 : Short_Integer; pragma Import (Ada, E526, "gpr__compilation__sync_E");
   E528 : Short_Integer; pragma Import (Ada, E528, "gpr__script_E");
   E510 : Short_Integer; pragma Import (Ada, E510, "gpr__compilation__process_E");
   E512 : Short_Integer; pragma Import (Ada, E512, "gpr__compilation__slave_E");
   E530 : Short_Integer; pragma Import (Ada, E530, "gpr__compilation__process__waiter_E");
   E532 : Short_Integer; pragma Import (Ada, E532, "gpr__util__aux_E");
   E534 : Short_Integer; pragma Import (Ada, E534, "gprbuild_E");
   E536 : Short_Integer; pragma Import (Ada, E536, "gprbuild__compile_E");
   E538 : Short_Integer; pragma Import (Ada, E538, "gprbuild__link_E");
   E542 : Short_Integer; pragma Import (Ada, E542, "gprbuild__post_compile_E");

   Sec_Default_Sized_Stacks : array (1 .. 1) of aliased System.Secondary_Stack.SS_Stack (System.Parameters.Runtime_Default_Sec_Stack_Size);

   Local_Priority_Specific_Dispatching : constant String := "";
   Local_Interrupt_States : constant String := "";

   Is_Elaborated : Boolean := False;

   procedure finalize_library is
   begin
      declare
         procedure F1;
         pragma Import (Ada, F1, "gprbuild__post_compile__finalize_body");
      begin
         E542 := E542 - 1;
         F1;
      end;
      declare
         procedure F2;
         pragma Import (Ada, F2, "gprbuild__link__finalize_body");
      begin
         E538 := E538 - 1;
         F2;
      end;
      declare
         procedure F3;
         pragma Import (Ada, F3, "gprbuild__compile__finalize_body");
      begin
         E536 := E536 - 1;
         F3;
      end;
      E534 := E534 - 1;
      declare
         procedure F4;
         pragma Import (Ada, F4, "gprbuild__finalize_spec");
      begin
         F4;
      end;
      declare
         procedure F5;
         pragma Import (Ada, F5, "gpr__compilation__process__finalize_body");
      begin
         E510 := E510 - 1;
         F5;
      end;
      declare
         procedure F6;
         pragma Import (Ada, F6, "gpr__compilation__slave__finalize_body");
      begin
         E512 := E512 - 1;
         F6;
      end;
      declare
         procedure F7;
         pragma Import (Ada, F7, "gpr__compilation__slave__finalize_spec");
      begin
         F7;
      end;
      declare
         procedure F8;
         pragma Import (Ada, F8, "gpr__compilation__process__finalize_spec");
      begin
         F8;
      end;
      declare
         procedure F9;
         pragma Import (Ada, F9, "gpr__compilation__sync__finalize_body");
      begin
         E526 := E526 - 1;
         F9;
      end;
      declare
         procedure F10;
         pragma Import (Ada, F10, "gpr__compilation__sync__finalize_spec");
      begin
         F10;
      end;
      E520 := E520 - 1;
      declare
         procedure F11;
         pragma Import (Ada, F11, "gpr__compilation__protocol__finalize_spec");
      begin
         F11;
      end;
      declare
         procedure F12;
         pragma Import (Ada, F12, "gpr__util__finalize_body");
      begin
         E255 := E255 - 1;
         F12;
      end;
      declare
         procedure F13;
         pragma Import (Ada, F13, "gpr_build_util__finalize_body");
      begin
         E228 := E228 - 1;
         F13;
      end;
      declare
         procedure F14;
         pragma Import (Ada, F14, "gpr_build_util__finalize_spec");
      begin
         F14;
      end;
      declare
         procedure F15;
         pragma Import (Ada, F15, "gpr__conf__finalize_body");
      begin
         E281 := E281 - 1;
         F15;
      end;
      declare
         procedure F16;
         pragma Import (Ada, F16, "gpr__proc__finalize_body");
      begin
         E302 := E302 - 1;
         F16;
      end;
      declare
         procedure F17;
         pragma Import (Ada, F17, "gpr__nmsc__finalize_body");
      begin
         E283 := E283 - 1;
         F17;
      end;
      declare
         procedure F18;
         pragma Import (Ada, F18, "gpr__knowledge__finalize_body");
      begin
         E373 := E373 - 1;
         F18;
      end;
      E304 := E304 - 1;
      declare
         procedure F19;
         pragma Import (Ada, F19, "gpr__jobserver__finalize_spec");
      begin
         F19;
      end;
      E251 := E251 - 1;
      declare
         procedure F20;
         pragma Import (Ada, F20, "gpr__env__finalize_spec");
      begin
         F20;
      end;
      E360 := E360 - 1;
      declare
         procedure F21;
         pragma Import (Ada, F21, "gpr__compilation__finalize_spec");
      begin
         F21;
      end;
      declare
         procedure F22;
         pragma Import (Ada, F22, "gpr__util__finalize_spec");
      begin
         F22;
      end;
      E190 := E190 - 1;
      declare
         procedure F23;
         pragma Import (Ada, F23, "gpr__sinput__finalize_body");
      begin
         E213 := E213 - 1;
         F23;
      end;
      declare
         procedure F24;
         pragma Import (Ada, F24, "gpr__names__finalize_body");
      begin
         E204 := E204 - 1;
         F24;
      end;
      E234 := E234 - 1;
      declare
         procedure F25;
         pragma Import (Ada, F25, "gpr__knowledge__finalize_spec");
      begin
         F25;
      end;
      declare
         procedure F26;
         pragma Import (Ada, F26, "gpr__ext__finalize_spec");
      begin
         F26;
      end;
      declare
         procedure F27;
         pragma Import (Ada, F27, "gpr__finalize_spec");
      begin
         F27;
      end;
      E472 := E472 - 1;
      declare
         procedure F28;
         pragma Import (Ada, F28, "schema__dom_readers__finalize_spec");
      begin
         F28;
      end;
      E497 := E497 - 1;
      E476 := E476 - 1;
      E478 := E478 - 1;
      declare
         procedure F29;
         pragma Import (Ada, F29, "schema__schema_readers__finalize_spec");
      begin
         F29;
      end;
      declare
         procedure F30;
         pragma Import (Ada, F30, "schema__readers__finalize_spec");
      begin
         F30;
      end;
      declare
         procedure F31;
         pragma Import (Ada, F31, "schema__validators__finalize_spec");
      begin
         F31;
      end;
      E458 := E458 - 1;
      declare
         procedure F32;
         pragma Import (Ada, F32, "sax__readers__finalize_spec");
      begin
         F32;
      end;
      E460 := E460 - 1;
      declare
         procedure F33;
         pragma Import (Ada, F33, "input_sources__strings__finalize_spec");
      begin
         F33;
      end;
      E456 := E456 - 1;
      declare
         procedure F34;
         pragma Import (Ada, F34, "input_sources__file__finalize_spec");
      begin
         F34;
      end;
      E454 := E454 - 1;
      declare
         procedure F35;
         pragma Import (Ada, F35, "input_sources__finalize_spec");
      begin
         F35;
      end;
      E378 := E378 - 1;
      declare
         procedure F36;
         pragma Import (Ada, F36, "dom__core__finalize_spec");
      begin
         F36;
      end;
      E405 := E405 - 1;
      declare
         procedure F37;
         pragma Import (Ada, F37, "sax__utils__finalize_spec");
      begin
         F37;
      end;
      E462 := E462 - 1;
      declare
         procedure F38;
         pragma Import (Ada, F38, "sax__attributes__finalize_spec");
      begin
         F38;
      end;
      E466 := E466 - 1;
      declare
         procedure F39;
         pragma Import (Ada, F39, "sax__exceptions__finalize_spec");
      begin
         F39;
      end;
      E401 := E401 - 1;
      declare
         procedure F40;
         pragma Import (Ada, F40, "sax__symbols__finalize_spec");
      begin
         F40;
      end;
      E403 := E403 - 1;
      declare
         procedure F41;
         pragma Import (Ada, F41, "sax__pointers__finalize_spec");
      begin
         F41;
      end;
      E334 := E334 - 1;
      declare
         procedure F42;
         pragma Import (Ada, F42, "system__tasking__protected_objects__entries__finalize_spec");
      begin
         F42;
      end;
      declare
         procedure F43;
         pragma Import (Ada, F43, "ada__directories__finalize_body");
      begin
         E137 := E137 - 1;
         F43;
      end;
      declare
         procedure F44;
         pragma Import (Ada, F44, "ada__directories__finalize_spec");
      begin
         F44;
      end;
      E179 := E179 - 1;
      declare
         procedure F45;
         pragma Import (Ada, F45, "system__regexp__finalize_spec");
      begin
         F45;
      end;
      declare
         procedure F46;
         pragma Import (Ada, F46, "gnat__sockets__finalize_body");
      begin
         E267 := E267 - 1;
         F46;
      end;
      declare
         procedure F47;
         pragma Import (Ada, F47, "gnat__sockets__finalize_spec");
      begin
         F47;
      end;
      E445 := E445 - 1;
      declare
         procedure F48;
         pragma Import (Ada, F48, "gnat__expect__finalize_spec");
      begin
         F48;
      end;
      E239 := E239 - 1;
      declare
         procedure F49;
         pragma Import (Ada, F49, "system__pool_global__finalize_spec");
      begin
         F49;
      end;
      E253 := E253 - 1;
      declare
         procedure F50;
         pragma Import (Ada, F50, "gnat__string_split__finalize_spec");
      begin
         F50;
      end;
      E362 := E362 - 1;
      declare
         procedure F51;
         pragma Import (Ada, F51, "gnat__md5__finalize_spec");
      begin
         F51;
      end;
      E183 := E183 - 1;
      declare
         procedure F52;
         pragma Import (Ada, F52, "ada__text_io__finalize_spec");
      begin
         F52;
      end;
      E159 := E159 - 1;
      declare
         procedure F53;
         pragma Import (Ada, F53, "ada__strings__unbounded__finalize_spec");
      begin
         F53;
      end;
      E222 := E222 - 1;
      declare
         procedure F54;
         pragma Import (Ada, F54, "system__storage_pools__subpools__finalize_spec");
      begin
         F54;
      end;
      E257 := E257 - 1;
      declare
         procedure F55;
         pragma Import (Ada, F55, "ada__streams__stream_io__finalize_spec");
      begin
         F55;
      end;
      declare
         procedure F56;
         pragma Import (Ada, F56, "system__file_io__finalize_body");
      begin
         E174 := E174 - 1;
         F56;
      end;
      declare
         procedure Reraise_Library_Exception_If_Any;
            pragma Import (Ada, Reraise_Library_Exception_If_Any, "__gnat_reraise_library_exception_if_any");
      begin
         Reraise_Library_Exception_If_Any;
      end;
   end finalize_library;

   procedure adafinal is
      procedure s_stalib_adafinal;
      pragma Import (Ada, s_stalib_adafinal, "system__standard_library__adafinal");

      procedure Runtime_Finalize;
      pragma Import (C, Runtime_Finalize, "__gnat_runtime_finalize");

   begin
      if not Is_Elaborated then
         return;
      end if;
      Is_Elaborated := False;
      Runtime_Finalize;
      s_stalib_adafinal;
   end adafinal;

   type No_Param_Proc is access procedure;
   pragma Favor_Top_Level (No_Param_Proc);

   procedure adainit is
      Main_Priority : Integer;
      pragma Import (C, Main_Priority, "__gl_main_priority");
      Time_Slice_Value : Integer;
      pragma Import (C, Time_Slice_Value, "__gl_time_slice_val");
      WC_Encoding : Character;
      pragma Import (C, WC_Encoding, "__gl_wc_encoding");
      Locking_Policy : Character;
      pragma Import (C, Locking_Policy, "__gl_locking_policy");
      Queuing_Policy : Character;
      pragma Import (C, Queuing_Policy, "__gl_queuing_policy");
      Task_Dispatching_Policy : Character;
      pragma Import (C, Task_Dispatching_Policy, "__gl_task_dispatching_policy");
      Priority_Specific_Dispatching : System.Address;
      pragma Import (C, Priority_Specific_Dispatching, "__gl_priority_specific_dispatching");
      Num_Specific_Dispatching : Integer;
      pragma Import (C, Num_Specific_Dispatching, "__gl_num_specific_dispatching");
      Main_CPU : Integer;
      pragma Import (C, Main_CPU, "__gl_main_cpu");
      Interrupt_States : System.Address;
      pragma Import (C, Interrupt_States, "__gl_interrupt_states");
      Num_Interrupt_States : Integer;
      pragma Import (C, Num_Interrupt_States, "__gl_num_interrupt_states");
      Unreserve_All_Interrupts : Integer;
      pragma Import (C, Unreserve_All_Interrupts, "__gl_unreserve_all_interrupts");
      Detect_Blocking : Integer;
      pragma Import (C, Detect_Blocking, "__gl_detect_blocking");
      Default_Stack_Size : Integer;
      pragma Import (C, Default_Stack_Size, "__gl_default_stack_size");
      Default_Secondary_Stack_Size : System.Parameters.Size_Type;
      pragma Import (C, Default_Secondary_Stack_Size, "__gnat_default_ss_size");
      Bind_Env_Addr : System.Address;
      pragma Import (C, Bind_Env_Addr, "__gl_bind_env_addr");
      Interrupts_Default_To_System : Integer;
      pragma Import (C, Interrupts_Default_To_System, "__gl_interrupts_default_to_system");

      procedure Runtime_Initialize (Install_Handler : Integer);
      pragma Import (C, Runtime_Initialize, "__gnat_runtime_initialize");

      procedure Tasking_Runtime_Initialize;
      pragma Import (C, Tasking_Runtime_Initialize, "__gnat_tasking_runtime_initialize");

      Finalize_Library_Objects : No_Param_Proc;
      pragma Import (C, Finalize_Library_Objects, "__gnat_finalize_library_objects");
      Binder_Sec_Stacks_Count : Natural;
      pragma Import (Ada, Binder_Sec_Stacks_Count, "__gnat_binder_ss_count");
      Default_Sized_SS_Pool : System.Address;
      pragma Import (Ada, Default_Sized_SS_Pool, "__gnat_default_ss_pool");

   begin
      if Is_Elaborated then
         return;
      end if;
      Is_Elaborated := True;
      Main_Priority := -1;
      Time_Slice_Value := -1;
      WC_Encoding := 'b';
      Locking_Policy := ' ';
      Queuing_Policy := ' ';
      Task_Dispatching_Policy := ' ';
      System.Restrictions.Run_Time_Restrictions :=
        (Set =>
          (False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, True, False, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False),
         Value => (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
         Violated =>
          (True, True, False, False, True, True, True, False, 
           True, False, False, True, True, True, True, False, 
           False, False, False, True, True, False, True, True, 
           False, True, True, False, True, True, True, True, 
           False, True, False, False, False, True, True, False, 
           True, True, False, True, True, True, True, False, 
           True, False, True, False, False, True, True, False, 
           True, False, True, False, False, False, False, False, 
           False, True, False, True, True, True, False, False, 
           True, False, True, True, True, False, True, True, 
           False, True, True, True, True, False, False, False, 
           True, False, False, False, False, True, False, True, 
           True, False, True, False),
         Count => (0, 0, 0, 1, 0, 1, 4, 0, 6, 0),
         Unknown => (False, False, False, False, False, False, True, False, True, False));
      Priority_Specific_Dispatching :=
        Local_Priority_Specific_Dispatching'Address;
      Num_Specific_Dispatching := 0;
      Main_CPU := -1;
      Interrupt_States := Local_Interrupt_States'Address;
      Num_Interrupt_States := 0;
      Unreserve_All_Interrupts := 0;
      Detect_Blocking := 0;
      Default_Stack_Size := -1;

      ada_main'Elab_Body;
      Default_Secondary_Stack_Size := System.Parameters.Runtime_Default_Sec_Stack_Size;
      Binder_Sec_Stacks_Count := 1;
      Default_Sized_SS_Pool := Sec_Default_Sized_Stacks'Address;

      Runtime_Initialize (1);
      Tasking_Runtime_Initialize;

      Finalize_Library_Objects := finalize_library'access;

      Ada.Exceptions'Elab_Spec;
      System.Soft_Links'Elab_Spec;
      System.Exception_Table'Elab_Body;
      E024 := E024 + 1;
      Ada.Containers'Elab_Spec;
      E040 := E040 + 1;
      Ada.Io_Exceptions'Elab_Spec;
      E070 := E070 + 1;
      Ada.Numerics'Elab_Spec;
      E031 := E031 + 1;
      Ada.Strings'Elab_Spec;
      E055 := E055 + 1;
      Ada.Strings.Maps'Elab_Spec;
      E057 := E057 + 1;
      Ada.Strings.Maps.Constants'Elab_Spec;
      E060 := E060 + 1;
      Interfaces.C'Elab_Spec;
      E045 := E045 + 1;
      System.Exceptions'Elab_Spec;
      E025 := E025 + 1;
      System.Object_Reader'Elab_Spec;
      E086 := E086 + 1;
      System.Dwarf_Lines'Elab_Spec;
      E050 := E050 + 1;
      System.Os_Lib'Elab_Body;
      E075 := E075 + 1;
      System.Soft_Links.Initialize'Elab_Body;
      E020 := E020 + 1;
      E013 := E013 + 1;
      System.Traceback.Symbolic'Elab_Body;
      E039 := E039 + 1;
      E008 := E008 + 1;
      Ada.Assertions'Elab_Spec;
      E006 := E006 + 1;
      Ada.Strings.Utf_Encoding'Elab_Spec;
      E114 := E114 + 1;
      Gnat'Elab_Spec;
      E184 := E184 + 1;
      Interfaces.C.Strings'Elab_Spec;
      E194 := E194 + 1;
      System.Task_Info'Elab_Spec;
      E318 := E318 + 1;
      System.Task_Primitives.Operations'Elab_Body;
      E312 := E312 + 1;
      Ada.Tags'Elab_Spec;
      Ada.Tags'Elab_Body;
      E122 := E122 + 1;
      Ada.Strings.Text_Buffers'Elab_Spec;
      E112 := E112 + 1;
      Ada.Streams'Elab_Spec;
      E110 := E110 + 1;
      System.File_Control_Block'Elab_Spec;
      E177 := E177 + 1;
      System.Finalization_Root'Elab_Spec;
      E133 := E133 + 1;
      Ada.Finalization'Elab_Spec;
      E108 := E108 + 1;
      System.File_Io'Elab_Body;
      E174 := E174 + 1;
      Ada.Streams.Stream_Io'Elab_Spec;
      E257 := E257 + 1;
      System.Storage_Pools'Elab_Spec;
      E181 := E181 + 1;
      System.Storage_Pools.Subpools'Elab_Spec;
      E222 := E222 + 1;
      Ada.Strings.Unbounded'Elab_Spec;
      E159 := E159 + 1;
      System.Regpat'Elab_Spec;
      E450 := E450 + 1;
      Ada.Calendar'Elab_Spec;
      Ada.Calendar'Elab_Body;
      E139 := E139 + 1;
      Ada.Calendar.Delays'Elab_Body;
      E274 := E274 + 1;
      Ada.Calendar.Time_Zones'Elab_Spec;
      E145 := E145 + 1;
      Ada.Real_Time'Elab_Spec;
      Ada.Real_Time'Elab_Body;
      E356 := E356 + 1;
      Ada.Text_Io'Elab_Spec;
      Ada.Text_Io'Elab_Body;
      E183 := E183 + 1;
      Ada.Text_Io.Text_Streams'Elab_Spec;
      E415 := E415 + 1;
      E218 := E218 + 1;
      Gnat.Calendar'Elab_Spec;
      E261 := E261 + 1;
      Gnat.Directory_Operations'Elab_Spec;
      Gnat.Directory_Operations'Elab_Body;
      E187 := E187 + 1;
      E237 := E237 + 1;
      E524 := E524 + 1;
      E364 := E364 + 1;
      E366 := E366 + 1;
      Gnat.Md5'Elab_Spec;
      E362 := E362 + 1;
      Gnat.String_Split'Elab_Spec;
      E253 := E253 + 1;
      Gnat.Calendar.Time_Io'Elab_Spec;
      E264 := E264 + 1;
      System.Pool_Global'Elab_Spec;
      E239 := E239 + 1;
      Gnat.Expect'Elab_Spec;
      E445 := E445 + 1;
      Gnat.Sockets'Elab_Spec;
      Gnat.Sockets.Thin_Common'Elab_Spec;
      E279 := E279 + 1;
      E272 := E272 + 1;
      Gnat.Sockets'Elab_Body;
      E267 := E267 + 1;
      E270 := E270 + 1;
      System.Random_Seed'Elab_Body;
      E518 := E518 + 1;
      System.Regexp'Elab_Spec;
      E179 := E179 + 1;
      Ada.Directories'Elab_Spec;
      Ada.Directories'Elab_Body;
      E137 := E137 + 1;
      System.Tasking.Initialization'Elab_Body;
      E338 := E338 + 1;
      System.Tasking.Protected_Objects'Elab_Body;
      E328 := E328 + 1;
      System.Tasking.Protected_Objects.Entries'Elab_Spec;
      E334 := E334 + 1;
      System.Tasking.Queuing'Elab_Body;
      E346 := E346 + 1;
      System.Tasking.Stages'Elab_Body;
      E352 := E352 + 1;
      Unicode'Elab_Body;
      E382 := E382 + 1;
      Gprexch'Elab_Body;
      E540 := E540 + 1;
      E399 := E399 + 1;
      Sax.Pointers'Elab_Spec;
      Sax.Pointers'Elab_Body;
      E403 := E403 + 1;
      E499 := E499 + 1;
      Schema'Elab_Spec;
      E470 := E470 + 1;
      Unicode.Ccs'Elab_Spec;
      E395 := E395 + 1;
      E419 := E419 + 1;
      E421 := E421 + 1;
      E426 := E426 + 1;
      E429 := E429 + 1;
      E431 := E431 + 1;
      E433 := E433 + 1;
      E438 := E438 + 1;
      Unicode.Ces'Elab_Spec;
      E391 := E391 + 1;
      Sax.Symbols'Elab_Spec;
      Sax.Symbols'Elab_Body;
      E401 := E401 + 1;
      E468 := E468 + 1;
      Sax.Exceptions'Elab_Spec;
      Sax.Exceptions'Elab_Body;
      E466 := E466 + 1;
      E393 := E393 + 1;
      E441 := E441 + 1;
      E443 := E443 + 1;
      E397 := E397 + 1;
      Sax.Models'Elab_Spec;
      E464 := E464 + 1;
      Sax.Attributes'Elab_Spec;
      Sax.Attributes'Elab_Body;
      E462 := E462 + 1;
      Sax.Utils'Elab_Spec;
      Sax.Utils'Elab_Body;
      E405 := E405 + 1;
      DOM.CORE'ELAB_SPEC;
      E378 := E378 + 1;
      Schema.Date_Time'Elab_Spec;
      E482 := E482 + 1;
      E488 := E488 + 1;
      Schema.Simple_Types'Elab_Spec;
      E480 := E480 + 1;
      E417 := E417 + 1;
      E413 := E413 + 1;
      E411 := E411 + 1;
      E474 := E474 + 1;
      E409 := E409 + 1;
      E407 := E407 + 1;
      Input_Sources'Elab_Spec;
      Input_Sources'Elab_Body;
      E454 := E454 + 1;
      Input_Sources.File'Elab_Spec;
      Input_Sources.File'Elab_Body;
      E456 := E456 + 1;
      Input_Sources.Strings'Elab_Spec;
      Input_Sources.Strings'Elab_Body;
      E460 := E460 + 1;
      Sax.Readers'Elab_Spec;
      Sax.Readers'Elab_Body;
      E458 := E458 + 1;
      Schema.Validators'Elab_Spec;
      Schema.Readers'Elab_Spec;
      Schema.Schema_Readers'Elab_Spec;
      Schema.Schema_Readers'Elab_Body;
      E478 := E478 + 1;
      Schema.Readers'Elab_Body;
      E476 := E476 + 1;
      E501 := E501 + 1;
      Schema.Validators'Elab_Body;
      E497 := E497 + 1;
      Schema.Dom_Readers'Elab_Spec;
      Schema.Dom_Readers'Elab_Body;
      E472 := E472 + 1;
      GPR'ELAB_SPEC;
      GPR.ATTR'ELAB_SPEC;
      E296 := E296 + 1;
      GPR.CSET'ELAB_BODY;
      E200 := E200 + 1;
      E206 := E206 + 1;
      GPR.EXT'ELAB_SPEC;
      GPR.KNOWLEDGE'ELAB_SPEC;
      GPR.OSINT'ELAB_SPEC;
      GPR.ALI'ELAB_SPEC;
      GPR.ERROUTC'ELAB_SPEC;
      E234 := E234 + 1;
      GPR.OUTPUT'ELAB_BODY;
      E208 := E208 + 1;
      E244 := E244 + 1;
      GPR.NAMES'ELAB_BODY;
      E204 := E204 + 1;
      E298 := E298 + 1;
      GPR.SINPUT'ELAB_SPEC;
      GPR.SINPUT'ELAB_BODY;
      E213 := E213 + 1;
      E202 := E202 + 1;
      E246 := E246 + 1;
      GPR.ATTR'ELAB_BODY;
      E196 := E196 + 1;
      E198 := E198 + 1;
      GPR.TEMPDIR'ELAB_BODY;
      E241 := E241 + 1;
      GPR'ELAB_BODY;
      E190 := E190 + 1;
      GPR.UTIL'ELAB_SPEC;
      GPR.COMPILATION'ELAB_SPEC;
      E360 := E360 + 1;
      GPR.ENV'ELAB_SPEC;
      GPR.ENV'ELAB_BODY;
      E251 := E251 + 1;
      GPR.JOBSERVER'ELAB_SPEC;
      GPR.JOBSERVER'ELAB_BODY;
      E304 := E304 + 1;
      GPR.KNOWLEDGE'ELAB_BODY;
      E373 := E373 + 1;
      GPR.SDEFAULT'ELAB_BODY;
      E452 := E452 + 1;
      GPR.TREE'ELAB_SPEC;
      GPR.TREE'ELAB_BODY;
      E249 := E249 + 1;
      E294 := E294 + 1;
      GPR.NMSC'ELAB_BODY;
      E283 := E283 + 1;
      GPR.PART'ELAB_BODY;
      E292 := E292 + 1;
      GPR.PROC'ELAB_BODY;
      E302 := E302 + 1;
      GPR.CONF'ELAB_SPEC;
      GPR.CONF'ELAB_BODY;
      E281 := E281 + 1;
      GPR.STRT'ELAB_BODY;
      E300 := E300 + 1;
      E503 := E503 + 1;
      Gpr_Build_Util'Elab_Spec;
      Gpr_Build_Util'Elab_Body;
      E228 := E228 + 1;
      GPR.OSINT'ELAB_BODY;
      E226 := E226 + 1;
      GPR.UTIL'ELAB_BODY;
      E255 := E255 + 1;
      GPR.COMPILATION.PROTOCOL'ELAB_SPEC;
      GPR.COMPILATION.PROTOCOL'ELAB_BODY;
      E520 := E520 + 1;
      GPR.COMPILATION.SYNC'ELAB_SPEC;
      GPR.COMPILATION.SYNC'ELAB_BODY;
      E526 := E526 + 1;
      E528 := E528 + 1;
      GPR.COMPILATION.PROCESS'ELAB_SPEC;
      GPR.COMPILATION.SLAVE'ELAB_SPEC;
      GPR.COMPILATION.SLAVE'ELAB_BODY;
      E512 := E512 + 1;
      GPR.COMPILATION.PROCESS'ELAB_BODY;
      E510 := E510 + 1;
      GPR.COMPILATION.PROCESS.WAITER'ELAB_BODY;
      E530 := E530 + 1;
      E532 := E532 + 1;
      Gprbuild'Elab_Spec;
      Gprbuild'Elab_Body;
      E534 := E534 + 1;
      Gprbuild.Compile'Elab_Body;
      E536 := E536 + 1;
      Gprbuild.Link'Elab_Body;
      E538 := E538 + 1;
      Gprbuild.Post_Compile'Elab_Body;
      E542 := E542 + 1;
   end adainit;

   procedure Ada_Main_Program;
   pragma Import (Ada, Ada_Main_Program, "_ada_gprbuild__main");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer
   is
      procedure Initialize (Addr : System.Address);
      pragma Import (C, Initialize, "__gnat_initialize");

      procedure Finalize;
      pragma Import (C, Finalize, "__gnat_finalize");
      SEH : aliased array (1 .. 2) of Integer;

      Ensure_Reference : aliased System.Address := Ada_Main_Program_Name'Address;
      pragma Volatile (Ensure_Reference);

   begin
      if gnat_argc = 0 then
         gnat_argc := argc;
         gnat_argv := argv;
      end if;
      gnat_envp := envp;

      Initialize (SEH'Address);
      adainit;
      Ada_Main_Program;
      adafinal;
      Finalize;
      return (gnat_exit_status);
   end;

--  BEGIN Object file/option list
   --   ./unicode-names.o
   --   ./unicode-names-basic_latin.o
   --   ./unicode.o
   --   ./unicode-names-currency_symbols.o
   --   ./unicode-names-cyrillic.o
   --   ./unicode-names-general_punctuation.o
   --   ./unicode-names-latin_1_supplement.o
   --   ./unicode-names-latin_extended_a.o
   --   ./unicode-names-latin_extended_b.o
   --   ./unicode-names-letterlike_symbols.o
   --   ./unicode-names-spacing_modifier_letters.o
   --   ./dom.o
   --   ./gprexch.o
   --   ./sax.o
   --   ./sax-htable.o
   --   ./sax-pointers.o
   --   ./sax-state_machines.o
   --   ./schema.o
   --   ./unicode-ccs.o
   --   ./unicode-ccs-iso_8859_1.o
   --   ./unicode-ccs-iso_8859_15.o
   --   ./unicode-ccs-iso_8859_2.o
   --   ./unicode-ccs-iso_8859_3.o
   --   ./unicode-ccs-iso_8859_4.o
   --   ./unicode-ccs-windows_1251.o
   --   ./unicode-ccs-windows_1252.o
   --   ./unicode-ces.o
   --   ./sax-symbols.o
   --   ./sax-locators.o
   --   ./sax-exceptions.o
   --   ./unicode-ces-utf32.o
   --   ./unicode-ces-basic_8bit.o
   --   ./unicode-ces-utf16.o
   --   ./unicode-ces-utf8.o
   --   ./sax-encodings.o
   --   ./sax-models.o
   --   ./sax-attributes.o
   --   ./sax-utils.o
   --   ./dom-core.o
   --   ./schema-date_time.o
   --   ./schema-decimal.o
   --   ./schema-simple_types.o
   --   ./unicode-encodings.o
   --   ./dom-core-nodes.o
   --   ./dom-core-attrs.o
   --   ./dom-core-character_datas.o
   --   ./dom-core-elements.o
   --   ./dom-core-documents.o
   --   ./input_sources.o
   --   ./input_sources-file.o
   --   ./input_sources-strings.o
   --   ./sax-readers.o
   --   ./schema-schema_readers.o
   --   ./schema-readers.o
   --   ./schema-validators-xsd_grammar.o
   --   ./schema-validators.o
   --   ./schema-dom_readers.o
   --   ./gpr-attr-pm.o
   --   ./gpr-cset.o
   --   ./gpr-debug.o
   --   ./gpr-opt.o
   --   ./gpr-com.o
   --   ./gpr-ext.o
   --   ./gpr-output.o
   --   ./gpr-ali.o
   --   ./gpr-names.o
   --   ./gpr-scans.o
   --   ./gpr-sinput.o
   --   ./gpr-erroutc.o
   --   ./gpr-snames.o
   --   ./gpr-attr.o
   --   ./gpr-err.o
   --   ./gpr-tempdir.o
   --   ./gpr.o
   --   ./gpr-compilation.o
   --   ./gpr-env.o
   --   ./gpr-jobserver.o
   --   ./gpr-knowledge.o
   --   ./gpr-sdefault.o
   --   ./gpr-tree.o
   --   ./gpr-dect.o
   --   ./gpr-nmsc.o
   --   ./gpr-part.o
   --   ./gpr-proc.o
   --   ./gpr-conf.o
   --   ./gpr-strt.o
   --   ./gpr-version.o
   --   ./gpr_build_util.o
   --   ./gpr-osint.o
   --   ./gpr-util.o
   --   ./gpr-compilation-protocol.o
   --   ./gpr-compilation-sync.o
   --   ./gpr-script.o
   --   ./gpr-compilation-slave.o
   --   ./gpr-compilation-process.o
   --   ./gpr-compilation-process-waiter.o
   --   ./gpr-util-aux.o
   --   ./gprbuild.o
   --   ./gprbuild-compile.o
   --   ./gprbuild-link.o
   --   ./gprbuild-post_compile.o
   --   ./gprbuild-main.o
   --   -L./
   --   -L/usr/lib/gcc/armv7-alpine-linux-musleabihf/15.2.0/adalib/
   --   -shared
   --   -lgnarl-15
   --   -lgnat-15
   --   -lrt
   --   -lpthread
--  END Object file/option list   

end ada_main;
