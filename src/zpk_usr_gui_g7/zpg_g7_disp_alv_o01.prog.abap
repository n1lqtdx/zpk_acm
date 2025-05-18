*----------------------------------------------------------------------*
***INCLUDE ZPG_G7_DISP_ALV_STATUS_1000O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_1000 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_alv_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.
ENDCLASS.

CLASS lcl_alv_event_handler IMPLEMENTATION.
  METHOD on_double_click.
    PERFORM display_user_details USING e_row.
  ENDMETHOD.
ENDCLASS.


MODULE status_100 OUTPUT.
  SET PF-STATUS 'SALV_STANDARD' EXCLUDING gt_ucomm.
ENDMODULE.

MODULE init_100 OUTPUT.
  PERFORM init_100.
  PERFORM beautify_alv.
  PERFORM build_fieldcat.
  PERFORM header_100.
  PERFORM display_100.
ENDMODULE.

FORM init_100.
  IF go_container IS INITIAL.
    go_container = NEW cl_gui_custom_container( container_name = 'CONTAINER_ALV' ).
    go_grid = NEW cl_gui_alv_grid( i_parent = go_container ).

*    AUTHORITY-CHECK OBJECT 'ZAUTH_G7' ID 'ACTVT' FIELD '05'.
    SELECT * FROM ztb_admin
    WHERE bname = @sy-uname
    INTO @DATA(lt_users).
    ENDSELECT.

    IF lt_users IS INITIAL.
*    IF sy-uname NE 'LEARN-286'.
      APPEND '&LOCK' TO gt_ucomm.
      APPEND '&UNLOCK' TO gt_ucomm.
    ENDIF.

    gc_logger = NEW zcl_log_utils_g7( ).
  ENDIF.
ENDFORM.

FORM build_fieldcat.
  REFRESH gt_fieldcat[].
  " Define field properties
  gt_fieldcat = VALUE #(
*    ( fieldname = 'sel'         reptext = 'X'       col_pos = 1   outputlen = 6   just = 'C' edit = 'X' tabname = 'I_DATA' seltext = 'Checkbox' checkbox = 'X' )
    ( fieldname = 'user_status' ref_field = ''          reptext = 'Status'                              col_pos = 2             outputlen = 6   just = 'C' edit = ''  icon = 'X')
    ( fieldname = 'BNAME'       ref_field = 'BNAME'     reptext = 'User'        ref_table = 'usr02'     col_pos = 3             outputlen = 18  just = 'L' edit = ''  key = 'X' )
    ( fieldname = 'GLTGV'       ref_field = 'GLTGV'     reptext = 'Valid from'                          col_pos = 4             outputlen = 10  just = 'L' edit = '')
    ( fieldname = 'GLTGB'       ref_field = 'GLTGB'     reptext = 'Valid to'                            col_pos = 5             outputlen = 10  just = 'L' edit = '')
    ( fieldname = 'USTYP'       ref_field = 'USTYP'     reptext = 'Type'        ref_table = 'usr02'     col_pos = 6       convexit = 'USTYP'    just = 'L' edit = '')
*    ( fieldname = 'ACCNT'       ref_field = 'ACCNT'     reptext = 'ID'          ref_table = 'usr02'     col_pos = 7             outputlen = 15  just = 'L' edit = '')
    ( fieldname = 'TRDAT'       ref_field = 'TRDAT'     reptext = 'Logon Date'                          col_pos = 8             outputlen = 10  just = 'R' edit = '')
    ( fieldname = 'LTIME'       ref_field = 'LTIME'     reptext = 'Logon Time'                          col_pos = 9             outputlen = 10  just = 'R' edit = '')
    ( fieldname = 'TZONE'       ref_field = 'TZONE'     reptext = 'Timezone'    ref_table = 'usr02'     col_pos = 10            outputlen = 3   just = 'L' edit = '')
    ( fieldname = 'lock_reason' ref_field = ''          reptext = 'Lock Reason'                         col_pos = 11            outputlen = 14  just = 'L' edit = '')
    ( fieldname = 'LOCNT'       ref_field = 'LOCNT'     reptext = 'Failed'      ref_table = 'usr02'     col_pos = 12            outputlen = 4   just = 'R' edit = '')
    ( fieldname = 'inactive_date'   ref_field = 'inactive_date' reptext = 'Lock Date'       ref_table = 'zuser'    col_pos = 13   no_zero = 'X'         outputlen = 10  just = 'R' edit = '')
    ( fieldname = 'SMTP_ADDR'   ref_field = 'SMTP_ADDR' reptext = 'Email'       ref_table = 'p_user002'    col_pos = 14            outputlen = 30  just = 'L' edit = '')
  ).
ENDFORM.

FORM beautify_alv.
  LOOP AT gt_usr_alv INTO DATA(ls_usr).
    " User status icon.
    CASE ls_usr-user_status.
      WHEN 'NL'.
        ls_usr-user_status = |@08\\QUser is unlocked@|.
      WHEN 'L'.
        ls_usr-user_status = |@0A\\QUser is locked@|.
    ENDCASE.

    CLEAR gs_color.
    " Colorize no. failed attempts.
    gs_color-fname = 'LOCNT'.
    IF ls_usr-locnt > 0 AND ls_usr-locnt <= 2.
      ls_usr-c_color = 'YLW'.
      gs_color-color-col = 3. "Yellow
    ELSEIF ls_usr-locnt >= 3.
      ls_usr-c_color = 'RED'.
      gs_color-color-col = 6. "Red
    ELSE.
      ls_usr-c_color = 'NONE'.
    ENDIF.

    APPEND gs_color TO ls_usr-t_color.

    MODIFY gt_usr_alv FROM ls_usr.
  ENDLOOP.
ENDFORM.

FORM display_100.

  DATA: ls_variant TYPE disvariant
        , lo_handler TYPE REF TO lcl_alv_event_handler.

  gs_layout-sel_mode    = 'A'.
*  gs_layout-no_rowmark  = 'X'.
  gs_layout-ctab_fname  = 't_color'.

  lo_handler = NEW lcl_alv_event_handler(  ).
  SET HANDLER lo_handler->on_double_click FOR go_grid.

  PERFORM exclude_tb_functions CHANGING gt_exclude.

  go_grid->set_table_for_first_display(
EXPORTING
  is_variant           = ls_variant
  it_toolbar_excluding = gt_exclude
  is_layout            = gs_layout
  i_save               = 'A'
  i_bypassing_buffer   = 'X'
CHANGING
  it_outtab            = gt_usr_alv                " Output Table
  it_fieldcatalog      = gt_fieldcat               " Field Catalog
EXCEPTIONS
  invalid_parameter_combination = 1                " Wrong Parameter
  program_error                 = 2                " Program Errors
  too_many_lines                = 3                " Too many Rows in Ready for Input Grid
  OTHERS                        = 4
).

  PERFORM refresh_header_100.

ENDFORM.

FORM header_100.

  IF go_docking_container IS INITIAL
      AND go_document IS INITIAL.
    CREATE OBJECT go_docking_container
      EXPORTING
        repid = sy-repid
        dynnr = '0100'
        ratio = 35
        side  = go_docking_container->dock_at_top.

    CREATE OBJECT go_document.

    PERFORM add_normal_header USING 'User List Report' '' cl_dd_document=>large cl_dd_document=>strong.
    go_document->new_line(  ).
    PERFORM add_normal_header USING 'Overview' space cl_dd_document=>large cl_dd_document=>strong.

    PERFORM process_header_data_100.

    go_document->display_document(
        parent             = go_docking_container
    ).

  ENDIF.

ENDFORM.

FORM process_header_data_100.

  DATA: lv_count                      TYPE i,
        lv_count_unlock               TYPE i,
        lv_count_lock                 TYPE i,
        lv_count_admin_lock           TYPE i,
        lv_count_inactive_lock        TYPE i,
        lv_count_incorrect_login_lock TYPE i,
        lv_count_green_failed_login   TYPE i,
        lv_count_yellow_failed_login  TYPE i,
        lv_count_red_failed_login     TYPE i
        .


  "Unlocked user
  lv_count_unlock = REDUCE i( INIT count = 0
                              FOR user_status IN gt_usr_alv
                              WHERE ( user_status = '@08\QUser is unlocked@' )
                              NEXT count = count + 1 ).

  "Locked user
  lv_count_incorrect_login_lock = REDUCE i( INIT count = 0
                                            FOR uflag IN gt_usr_alv
                                            WHERE ( uflag = 32 )
                                            NEXT count = count + 1 ).

  lv_count_admin_lock = REDUCE i( INIT count = 0
                                  FOR uflag IN gt_usr_alv
                                  WHERE ( uflag = 64 )
                                  NEXT count = count + 1 ).

  lv_count_inactive_lock = REDUCE i( INIT count = 0
                                     FOR uflag IN gt_usr_alv
                                     WHERE ( uflag = 128 )
                                     NEXT count = count + 1 ).

  PERFORM add_normal_header USING 'User Lock Summary:' space cl_dd_document=>medium cl_dd_document=>strong.

  PERFORM add_normal_header
    USING
      'Locked due to incorrect login: '
      lv_count_incorrect_login_lock
      cl_dd_document=>medium
      cl_dd_document=>standard
    .

  PERFORM add_normal_header
    USING
      'Locked by administrator: '
      lv_count_admin_lock
      cl_dd_document=>medium
      cl_dd_document=>standard
    .

  PERFORM add_normal_header
    USING
      'Locked due to inactive: '
      lv_count_inactive_lock
      cl_dd_document=>medium
      cl_dd_document=>standard
    .


  "Login failed attempt
  lv_count_green_failed_login = REDUCE i( INIT count = 0
                                          FOR c_color IN gt_usr_alv
                                          WHERE ( c_color = 'NONE' )
                                          NEXT count = count + 1 ).

  lv_count_yellow_failed_login = REDUCE i( INIT count = 0
                                           FOR c_color IN gt_usr_alv
                                           WHERE ( c_color = 'YLW' )
                                           NEXT count = count + 1 ).

  lv_count_red_failed_login = REDUCE i( INIT count = 0
                                        FOR c_color IN gt_usr_alv
                                        WHERE ( c_color = 'RED' )
                                        NEXT count = count + 1 ).

  "Manually create header for this particular section
  go_document->new_line( ).
  PERFORM add_normal_header USING 'Login Activity:' space cl_dd_document=>medium cl_dd_document=>strong.
  go_document->add_text(
    EXPORTING
      text          = 'Login attempts: '
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>standard
  ).

  go_document->add_text(
    EXPORTING
      text          = |{ lv_count_green_failed_login }|
      sap_color     = cl_dd_area=>list_positive_inv
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>strong
  ).

  go_document->add_text(
    EXPORTING
      text          = ' | '
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>standard
  ).

  go_document->add_text(
    EXPORTING
      text          = |{ lv_count_yellow_failed_login }|
      sap_color     = cl_dd_area=>list_total_inv
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>strong
  ).

  go_document->add_text(
    EXPORTING
      text          = ' | '
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>standard
  ).

  go_document->add_text(
    EXPORTING
      text          = |{ lv_count_red_failed_login }|
      sap_color     = cl_dd_area=>list_negative_inv
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>strong
  ).

  go_document->new_line(  ).
  go_document->new_line(  ).

  "Total
  DESCRIBE TABLE gt_usr_alv LINES lv_count.
  lv_count_lock = lv_count - lv_count_unlock.
  PERFORM add_normal_header USING 'Search Summary:' space cl_dd_document=>medium cl_dd_document=>strong.
  go_document->add_text(
    EXPORTING
      text          = 'Total user searched: '
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>standard
  ).

  "Unlock
  go_document->add_icon(
    sap_icon         = 'ICON_UNLOCKED'
  ).
  go_document->add_text(
    EXPORTING
      text          = |{ lv_count_unlock }|
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>strong
  ).

  go_document->add_text(
    EXPORTING
      text          = ' | '
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>standard
  ).

  "Lock
  go_document->add_icon(
      sap_icon         = 'ICON_LOCKED'
    ).
  go_document->add_text(
    EXPORTING
      text          = |{ lv_count_lock }|
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>strong
  ).

  go_document->add_text(
    EXPORTING
      text          = ' | '
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>standard
  ).
  go_document->add_text(
    EXPORTING
      text          = |{ lv_count }|
      sap_fontsize  = cl_dd_document=>medium
      sap_emphasis  = cl_dd_document=>strong
  ).

ENDFORM.

FORM add_normal_header USING text1 text2 fontsize emphasis.

  DATA: line_header TYPE sdydo_text_element,
        iv_text1    TYPE string,
        iv_text2    TYPE string.

  iv_text1 = CONV string( text1 ).
  iv_text2 = CONV string( text2 ).

  line_header = |{ iv_text1 } { iv_text2 }|.

  CALL METHOD go_document->add_text
    EXPORTING
      text         = line_header
      sap_fontsize = fontsize
      sap_emphasis = emphasis.

  CALL METHOD go_document->new_line.

ENDFORM.

FORM exclude_tb_functions CHANGING pt_exclude TYPE ui_functions.

  DATA ls_exclude TYPE ui_func.

  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_copy_row.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_delete_row.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_append_row.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_insert_row.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_move_row.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_copy.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_cut.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_paste.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_paste_new_row.
  APPEND ls_exclude TO pt_exclude.
  ls_exclude = cl_gui_alv_grid=>mc_fc_loc_undo.
  APPEND ls_exclude TO pt_exclude.

ENDFORM.

FORM refresh_header_100.

  go_document->initialize_document(  ).

  PERFORM add_normal_header USING 'User List Report - Overview' '' cl_dd_document=>large cl_dd_document=>strong.
  go_document->new_line(  ).

  PERFORM process_header_data_100.

  go_document->display_document(
*      EXPORTING
      reuse_control      = 'X'
*        reuse_registration =
*        container          =
      parent             =  go_docking_container
  ).
ENDFORM.
