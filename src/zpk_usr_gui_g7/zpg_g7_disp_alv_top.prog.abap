*&---------------------------------------------------------------------*
*& Include          ZPG_G7_DISP_ALV_TOP
*&---------------------------------------------------------------------*
TABLES: usr02, ztb_user.

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_bname FOR usr02-bname,
                  s_trdat FOR usr02-trdat DEFAULT sy-datum TO sy-datum.
  PARAMETERS: s_lock AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN: BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  SELECT-OPTIONS: s_ldat FOR ztb_user-inactive_date.
*  PARAMETERS: s_onl_zu AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: END OF BLOCK b2.

DATA: go_grid               TYPE REF TO cl_gui_alv_grid,
      go_container          TYPE REF TO cl_gui_custom_container,
      go_docking_container  TYPE REF TO cl_gui_docking_container,
      go_document           TYPE REF TO cl_dd_document,
      gt_fieldcat           TYPE TABLE OF lvc_s_fcat,
      go_alv_toolbarmanager TYPE REF TO cl_alv_grid_toolbar_manager,

      gt_exclude            TYPE ui_functions,
      gs_fieldcat           TYPE lvc_s_fcat,
      gs_color              TYPE lvc_s_scol,
      gs_layout             TYPE lvc_s_layo,
      gt_ucomm              TYPE slis_t_extab,

      gc_logger             TYPE REF TO zcl_log_utils_g7.

DATA: gt_usr_alv TYPE TABLE OF zusr_g7_alv.
