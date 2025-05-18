*&---------------------------------------------------------------------*
*& Include zpg_g7_disp_alv_f01
*&---------------------------------------------------------------------*

FORM get_data.
  DATA: lt_date  TYPE dats,
        lt_bname TYPE RANGE OF xubname WITH HEADER LINE.
  lt_date = sy-datum + 1.


*  IF s_lock = 'X'.
*    SELECT u02~bname, u02~gltgv, u02~gltgb, u02~ustyp, u02~accnt, u02~trdat, u02~ltime, u02~tzone, u02~uflag,
*    CASE u02~uflag
*        WHEN 0 THEN 'NL'
*        ELSE 'L'
*        END AS user_status,
*    CASE u02~uflag
*        WHEN 32  THEN 'Incorrect logins'
*        WHEN 64  THEN 'Administrator'
*        WHEN 128 THEN 'Inactive'
*        END AS lock_reason,
*    u02~locnt, pu002~smtp_addr, zu~inactive_date
*    FROM usr02 AS u02
*    LEFT JOIN p_user002 AS pu002
*    ON u02~bname = pu002~bname
*    LEFT JOIN ztb_user AS zu
*    ON u02~bname = zu~bname
*    WHERE u02~bname IN @s_bname
*      AND u02~trdat IN @s_trdat
*      AND u02~trdat LT @lt_date
*      AND u02~uflag NE 0
*      AND zu~inactive_date IN @s_ldat
*    INTO TABLE @DATA(lt_users).
*  ELSE.
*    SELECT u02~bname, u02~gltgv, u02~gltgb, u02~ustyp, u02~accnt, u02~trdat, u02~ltime, u02~tzone, u02~uflag,
*    CASE u02~uflag
*        WHEN 0 THEN 'NL'
*        ELSE 'L'
*        END AS user_status,
*    CASE u02~uflag
*        WHEN 32  THEN 'Incorrect logins'
*        WHEN 64  THEN 'Administrator'
*        WHEN 128 THEN 'Inactive'
*        END AS lock_reason,
*    u02~locnt, pu002~smtp_addr, zu~inactive_date
*    FROM usr02 AS u02
*    LEFT JOIN p_user002 AS pu002
*    ON u02~bname = pu002~bname
*        LEFT JOIN ztb_user AS zu
*    ON u02~bname = zu~bname
*    WHERE u02~bname IN @s_bname
*      AND u02~trdat IN @s_trdat
*      AND u02~trdat LT @lt_date
*      AND zu~inactive_date IN @s_ldat
*    INTO TABLE @lt_users.
*  ENDIF.

    SELECT u02~bname, u02~gltgv, u02~gltgb, u02~ustyp, u02~accnt, u02~trdat, u02~ltime, u02~tzone, u02~uflag,
    CASE u02~uflag
        WHEN 0 THEN 'NL'
        ELSE 'L'
    END AS user_status,
    CASE u02~uflag
        WHEN 32  THEN 'Administrator'
        WHEN 64  THEN 'Administrator'
        WHEN 128 THEN 'Incorrect logins'
        WHEN 192 THEN 'Administrator'
    END AS lock_reason,
    u02~locnt, pu002~smtp_addr, zu~inactive_date
    FROM usr02 AS u02
    LEFT JOIN p_user002 AS pu002
    ON u02~bname = pu002~bname
    LEFT JOIN ztb_user AS zu
    ON u02~bname = zu~bname
    WHERE u02~bname IN @s_bname
    AND u02~trdat IN @s_trdat
    AND u02~trdat LT @lt_date
    AND zu~inactive_date IN @s_ldat
    AND ( @s_lock = '' OR u02~uflag NE 0 )
*    AND ( @s_onl_zu = '' OR zu~bname IS NOT NULL )
*    AND zu~bname IS NOT NULL
    INTO TABLE @DATA(lt_users).

  gt_usr_alv = CORRESPONDING #( lt_users ).

ENDFORM.

FORM display_usr_alv.
  IF gt_usr_alv IS NOT INITIAL.
    CALL SCREEN '100'.
  ELSE.
    MESSAGE 'Data does not exist' TYPE 'I' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM smartform_preview.

  CALL FUNCTION '/1BCDWB/SF00000049'
    EXPORTING
*     ARCHIVE_INDEX    =
*     ARCHIVE_INDEX_TAB          =
*     ARCHIVE_PARAMETERS         =
*     CONTROL_PARAMETERS         =
*     MAIL_APPL_OBJ    =
*     MAIL_RECIPIENT   =
*     MAIL_SENDER      =
*     OUTPUT_OPTIONS   =
*     USER_SETTINGS    = 'X'
      it_user_status   = gt_usr_alv
*     IMPORTING
*     DOCUMENT_OUTPUT_INFO       =
*     JOB_OUTPUT_INFO  =
*     JOB_OUTPUT_OPTIONS         =
    EXCEPTIONS
      formatting_error = 1
      internal_error   = 2
      send_error       = 3
      user_canceled    = 4
      OTHERS           = 5.

ENDFORM.

FORM export_alv_xlsx.
  DATA: lo_excel        TYPE REF TO zcl_excel
      , lo_xl_converter TYPE REF TO zcl_excel_converter
      , l_file          TYPE xstring
      , lt_file         TYPE solix_tab
      , l_bytecount     TYPE i
      , ls_seoclass     TYPE seoclass
      , row             TYPE zexcel_cell_row VALUE 7
      , lo_style_header TYPE REF TO   zcl_excel_style
      , lo_style_line1  TYPE REF TO   zcl_excel_style
      , lo_style_line2  TYPE REF TO   zcl_excel_style
      , lo_style_line   TYPE REF TO   zcl_excel_style.


  " Get path
  DATA: lo_error          TYPE REF TO zcx_excel
      , lv_message        TYPE string
      , l_path            TYPE string
      , lv_workdir        TYPE string
      , lv_file_separator TYPE c.

* get save file path
  cl_gui_frontend_services=>get_sapgui_workdir( CHANGING sapworkdir = l_path ).
  cl_gui_cfw=>flush( ).
  cl_gui_frontend_services=>directory_browse(
    EXPORTING initial_folder = l_path
    CHANGING selected_folder = l_path ).

  IF l_path IS INITIAL.
    cl_gui_frontend_services=>get_sapgui_workdir(
      CHANGING sapworkdir = lv_workdir ).
    l_path = lv_workdir.
  ENDIF.

  cl_gui_frontend_services=>get_file_separator(
    CHANGING file_separator = lv_file_separator ).

  CONCATENATE l_path lv_file_separator 'export_usr_' sy-datum '.xlsx'
                      INTO l_path.

  TRY.
      lo_xl_converter = NEW zcl_excel_converter(  ).
      CREATE OBJECT lo_excel.

      DATA(lo_worksheet) = lo_excel->get_active_worksheet(  ).
*      lo_worksheet->freeze_panes( ip_num_rows = 1 ).

      " Header
      lo_style_header = lo_excel->add_new_style(  ).
      lo_style_header->font->name  = 'Calibri'.
      lo_style_header->font->size  = 11.
      lo_style_header->font->bold  = abap_true.
      lo_style_header->font->color-rgb = zcl_excel_style_color=>c_white.
      lo_style_header->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
      lo_style_header->fill->fgcolor-rgb = zcl_excel_style_color=>create_new_arbg_int(
                                               iv_red   = 31
                                               iv_green = 78
                                               iv_blue  = 120
                                             ).

      lo_style_line1 = lo_excel->add_new_style(  ).
      lo_style_header->font->name  = 'Calibri'.
      lo_style_header->font->size  = 11.
      lo_style_line1->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
      lo_style_line1->fill->fgcolor-rgb = zcl_excel_style_color=>create_new_arbg_int(
                                               iv_red   = 217
                                               iv_green = 217
                                               iv_blue  = 217
                                             ).

      lo_style_line2 = lo_excel->add_new_style(  ).
      lo_style_header->font->name  = 'Calibri'.
      lo_style_header->font->size  = 11.
      lo_style_line2->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
      lo_style_line2->fill->fgcolor-rgb = zcl_excel_style_color=>create_new_arbg_int(
                                               iv_red   = 242
                                               iv_green = 242
                                               iv_blue  = 242
                                             ).

      PERFORM eax_set_header
        USING
          lo_worksheet
          lo_excel
        .

      PERFORM eax_set_column_headers USING lo_worksheet
        'User Name;Valid from;Valid to;Type;ID;Logon Date;Logon Time;Timezone;Lock Reason;Failed;Email'
        lo_style_header.

      " Set column type
      lo_worksheet->set_default_excel_date_format( ip_default_excel_date_format = 'dd/mm/yyyy' ).
*      CATCH zcx_excel.

      DATA: lv_ustyp_conv TYPE string.

      LOOP AT gt_usr_alv INTO DATA(lv_data).

        IF row MOD 2 = 0.
          lo_style_line = lo_style_line1.
        ELSE.
          lo_style_line = lo_style_line2.
        ENDIF.

        lo_worksheet->set_cell_style(
          ip_column    = 1
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 1
          ip_row       = row
          ip_value     = lv_data-bname
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 2
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 2
          ip_row       = row
          ip_value     = lv_data-gltgb
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 3
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 3
          ip_row       = row
          ip_value     = lv_data-gltgv
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 4
          ip_row       = row
          ip_style     = lo_style_line
        ).
        CALL FUNCTION 'CONVERSION_EXIT_USTYP_OUTPUT'
          EXPORTING
            input           = lv_data-ustyp
          IMPORTING
            output          = lv_ustyp_conv
          EXCEPTIONS
            input_not_valid = 1
            OTHERS          = 2.
        lo_worksheet->set_cell(
          ip_column    = 4
          ip_row       = row
          ip_value     = lv_ustyp_conv
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 5
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 5
          ip_row       = row
          ip_value     = lv_data-accnt
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 6
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 6
          ip_row       = row
          ip_value     = lv_data-trdat
          ip_abap_type = cl_abap_typedescr=>typekind_date
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 7
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 7
          ip_row       = row
          ip_value     = lv_data-ltime
          ip_abap_type = cl_abap_typedescr=>typekind_time
        ).

        lo_worksheet->set_cell(
          ip_column    = 8
          ip_row       = row
          ip_value     = lv_data-tzone
        ).
        lo_worksheet->set_cell_style(
          ip_column    = 8
          ip_row       = row
          ip_style     = lo_style_line
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 9
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 9
          ip_row       = row
          ip_value     = lv_data-lock_reason
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 10
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 10
          ip_row       = row
          ip_value     = lv_data-locnt
        ).

        lo_worksheet->set_cell_style(
          ip_column    = 11
          ip_row       = row
          ip_style     = lo_style_line
        ).
        lo_worksheet->set_cell(
          ip_column    = 11
          ip_row       = row
          ip_value     = lv_data-smtp_addr
        ).


        row = row + 1.
      ENDLOOP.

      " Set style
      PERFORM eax_set_style USING lo_worksheet.

      " Footer
*      PERFORM eax_set_footer
*        USING
*          lo_excel
*          lo_worksheet
*          row
*          row
*        .

      DATA(lo_excel_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007(  ) ).
      l_file = lo_excel_writer->write_file( lo_excel ).

      SELECT SINGLE * INTO ls_seoclass
          FROM seoclass
          WHERE clsname = 'CL_BCS_CONVERT'.

      IF sy-subrc = 0.
        CALL METHOD (ls_seoclass-clsname)=>xstring_to_solix
          EXPORTING
            iv_xstring = l_file
          RECEIVING
            et_solix   = lt_file.

        l_bytecount = xstrlen( l_file ).
      ELSE.
        " Convert to binary
        CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
          EXPORTING
            buffer        = l_file
          IMPORTING
            output_length = l_bytecount
          TABLES
            binary_tab    = lt_file.
      ENDIF.

      cl_gui_frontend_services=>gui_download( EXPORTING bin_filesize = l_bytecount
                                                        filename     = l_path
                                                        filetype     = 'BIN'
                                               CHANGING data_tab     = lt_file ).

    CATCH zcx_excel INTO DATA(zlx_excel).
      WRITE:/ 'Abap2Xlsx failed: ', zlx_excel->get_text(  ).
  ENDTRY.
ENDFORM.

FORM eax_set_header
    USING lo_worksheet TYPE REF TO zcl_excel_worksheet
          lo_excel     TYPE REF TO zcl_excel
    RAISING zcx_excel.

  DATA: lv_author     TYPE string,
        lv_created_on TYPE string,
        ls_key        TYPE wwwdatatab,
        lo_drawing    TYPE REF TO zcl_excel_drawing.


  " Set style.
  DATA: lo_style_title     TYPE REF TO zcl_excel_style
      , lo_style_sub       TYPE REF TO zcl_excel_style
      , lo_style_page      TYPE REF TO zcl_excel_style
      , lo_style_page_guid TYPE zexcel_cell_style.

  " Define Title Style
  lo_style_title = lo_excel->add_new_style( ).
  lo_style_title->font->bold = abap_true.
  lo_style_title->font->size = 24.
  lo_style_title->alignment->vertical = zcl_excel_style_alignment=>c_vertical_center.
  lo_style_title->alignment->horizontal =  zcl_excel_style_alignment=>c_horizontal_center.

  " Define Subtext Style (Author, Created On)
  lo_style_sub = lo_excel->add_new_style( ).
  lo_style_sub->font->italic = abap_true.
  lo_style_sub->font->size = 10.
  lo_style_sub->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_left.

  lo_style_page = lo_excel->add_new_style(  ).
  lo_style_page->fill->fgcolor-rgb = zcl_excel_style_color=>c_white.
  lo_style_page->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
  lo_style_page_guid = lo_style_page->get_guid( ).

  " Set Author & Created Date
  lv_author = sy-uname.
  CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum(4) INTO lv_created_on SEPARATED BY '.'.

  lo_excel->set_default_style( ip_style = lo_style_page_guid ).
*  CATCH zcx_excel.

*  " Create drawing object
*  lo_drawing = lo_excel->add_new_drawing(  ).
*  lo_drawing->set_position(
*    ip_from_row = 1
*    ip_from_col = 'A'
**    ip_rowoff   =
**    ip_coloff   =
*  ).
**  CATCH zcx_excel.
*  " Load Image (Replace with actual image retrieval logic)
*  ls_key-relid = 'MI'.
*  ls_key-objid = 'ZOBJ_MASAN_LOGO'.
*  lo_drawing->set_media_www(
*    ip_key    = ls_key
*    ip_width  = 166
*    ip_height = 75
*  ).
*  lo_worksheet->add_drawing( lo_drawing ).

  " Merge cells for Title
  lo_worksheet->set_merge(
*    ip_range        =
    ip_column_start = 'C'
    ip_column_end   = 'I'
    ip_row          = 2
    ip_row_to       = 3
*    ip_style        =
*    ip_value        =
*    ip_formula      =
  ).
*  CATCH zcx_excel.

  " Insert Title with Style
  lo_worksheet->set_cell( ip_column = 'C' ip_row = 2 ip_value = 'USER LIST REPORT' ).
  lo_worksheet->set_cell_style( ip_column = 'C' ip_row = 2 ip_style = lo_style_title->get_guid( ) ).

  " Insert Author
  lo_worksheet->set_cell( ip_column = 'K' ip_row = 2 ip_value = |Author: { lv_author }| ).
  lo_worksheet->set_cell_style( ip_column = 'B' ip_row = 2 ip_style = lo_style_sub->get_guid( ) ).

  " Insert Created Date
  lo_worksheet->set_cell( ip_column = 'K' ip_row = 3 ip_value = |Created On: { lv_created_on }| ).
  lo_worksheet->set_cell_style( ip_column = 'B' ip_row = 3 ip_style = lo_style_sub->get_guid( ) ).
ENDFORM.

FORM eax_set_footer
    USING lo_excel      TYPE REF TO zcl_excel
          lo_worksheet  TYPE REF TO zcl_excel_worksheet
          ip_row        TYPE zexcel_cell_row
          ip_row_to     TYPE  zexcel_cell_row
     RAISING zcx_excel.

  DATA: lv_today        TYPE        string
        , lo_style_footer  TYPE REF TO zcl_excel_style.

  " Define Footer Style
  lo_style_footer = lo_excel->add_new_style( ).
  lo_style_footer->font->bold = abap_true.
  lo_style_footer->font->size = 12.
  lo_style_footer->font->color-rgb = zcl_excel_style_color=>c_gray.
  lo_style_footer->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_center.

  " Set Today’s Date
  lv_today = sy-datum.

  " Merge cells for footer signature
  lo_worksheet->set_merge(
*    ip_range        =
    ip_column_start = 'B'
    ip_column_end   = 'E'
    ip_row          = ip_row
    ip_row_to       = ip_row_to
*    ip_style        =
*    ip_value        =
*    ip_formula      =
  ).
*  CATCH zcx_excel.

  " Insert Today's Date in Footer
  lo_worksheet->set_cell( ip_column = 'A' ip_row = ip_row ip_value = |Date: { lv_today }| ).
  lo_worksheet->set_cell_style( ip_column = 'A' ip_row = ip_row ip_style = lo_style_footer ).

  " Insert Signature Placeholder
  lo_worksheet->set_cell( ip_column = 'B' ip_row = ip_row ip_value = 'Signature: ____________________' ).
  lo_worksheet->set_cell_style( ip_column = 'B' ip_row = ip_row ip_style = lo_style_footer ).
ENDFORM.

FORM eax_set_column_headers
    USING io_worksheet TYPE REF TO zcl_excel_worksheet
          iv_headers   TYPE        csequence
          iv_style     TYPE        any
    RAISING zcx_excel.

  DATA: lt_headers      TYPE TABLE OF string
      , lv_header       TYPE          string
      , lv_tabix        TYPE          i.


  SPLIT iv_headers AT ';' INTO TABLE lt_headers.
  LOOP AT lt_headers INTO lv_header.
    lv_tabix = sy-tabix.
    io_worksheet->set_cell( ip_row = 6 ip_column = lv_tabix ip_value = lv_header ).
    io_worksheet->set_cell_style(
      ip_column    = lv_tabix
      ip_row       = 6
      ip_style     = iv_style
    ).
  ENDLOOP.

ENDFORM.

FORM eax_set_style
    USING io_worksheet TYPE REF TO zcl_excel_worksheet
    RAISING zcx_excel.

  DATA(o_col_iterator) = io_worksheet->get_columns_iterator( ).
  IF o_col_iterator IS BOUND.
    WHILE o_col_iterator->has_next( ).
      DATA(o_col) = CAST zcl_excel_column( o_col_iterator->get_next( ) ).
      o_col->set_auto_size( abap_true ).
    ENDWHILE.
  ENDIF.

  io_worksheet->calculate_column_widths(  ).

ENDFORM.

FORM process_users
  USING
        i_process_type TYPE char01.

  "Get selected rows data.
  DATA: lt_return      TYPE TABLE OF bapiret2,
        lt_idx_sel_row TYPE lvc_t_roid,
        ls_status      TYPE string,
        lv_username    TYPE string,
        li_tbl_count   TYPE int4,
        lv_counter     TYPE int4,
        lv_id          TYPE icon-id.

  SELECT SINGLE id
FROM icon
INTO lv_id
WHERE name = 'ICON_MESSAGE_WARNING'.

  CLEAR lv_counter.

  go_grid->check_changed_data(  ).

  go_grid->get_selected_rows(
    IMPORTING
*        et_index_rows =
      et_row_no     = lt_idx_sel_row
  ).
  DESCRIBE TABLE lt_idx_sel_row LINES li_tbl_count.

  LOOP AT lt_idx_sel_row INTO DATA(ls_sel_row).
    lv_counter = lv_counter + 1.
    DATA(lv_sel_row) = gt_usr_alv[ ls_sel_row-row_id ].
    CLEAR ls_status.

    ls_status = 'LOCKED'.
    IF i_process_type = 'L'.
      "Check if user recently locked?
      SELECT *
        FROM ztb_log_acm
        WHERE bname = @lv_sel_row-bname
        ORDER BY timestamp DESCENDING
        INTO @DATA(lt_data)
        UP TO 1 ROWS.
      ENDSELECT.

      IF NOT lt_data IS INITIAL.
        DATA: lv_date   TYPE xudate,
              lv_answer TYPE string.
        CONVERT TIME STAMP lt_data-timestamp TIME ZONE sy-zonlo INTO DATE lv_date.
        IF ( sy-datum - lv_date ) < 7.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
*             titlebar              = space
*             diagnose_object       = space
              text_question         = |User { lt_data-bname } has been recently locked. Are you sure about re-locking this user?{ cl_abap_char_utilities=>newline }({ lv_counter }/{ li_tbl_count })|
              text_button_1         = 'Yes'
*             icon_button_1         = space
              text_button_2         = 'No'
*             icon_button_2         = space
              default_button        = '2'
              display_cancel_button = ''
*             userdefined_f1_help   = space
*             start_column          = 25
*             start_row             = 6
*             popup_type            =
*             iv_quickinfo_button_1 = space
*             iv_quickinfo_button_2 = space
            IMPORTING
              answer                = lv_answer
*              TABLES
*             parameter             =
*              EXCEPTIONS
*             text_not_found        = 1
*             others                = 2
            .

          CASE lv_answer.
            WHEN '2'.
              "Return early if user click no.
              CONTINUE.
          ENDCASE.
        ENDIF.
      ENDIF.

      IF lv_sel_row-user_status = '@0A\QUser is locked@'.
        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            titel = 'Information'
            txt1  = lv_id
            txt2  = |{ lv_sel_row-bname } already locked.|
*           txt3  = space
*           txt4  = space
          .
        RETURN.
      ENDIF.

      "Lock user
      CALL FUNCTION 'BAPI_USER_LOCK'
        EXPORTING
          username = lv_sel_row-bname
        TABLES
          return   = lt_return.

      LOOP AT lt_return INTO DATA(lv_return).
        IF lv_return-type = 'S'.
          CLEAR lv_username.
          lv_username = lv_sel_row-bname.

          gc_logger->log_message(
            iv_locked_target = lv_username
            iv_action        = 'LOCK'
          ).

          PERFORM send_email
              USING lv_sel_row-bname
                    lv_sel_row-smtp_addr
                    lv_sel_row-trdat
                    lv_sel_row-ltime
                    ls_status
                    'ZTEMPLATE_EMAIL_LOCK_NOTIF'.
        ENDIF.
      ENDLOOP.

    ELSEIF i_process_type = 'U'.
      IF lv_sel_row-user_status = '@08\QUser is unlocked@'.
        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            titel = 'Information'
            txt1  = lv_id
            txt2  = |{ lv_sel_row-bname } already unlocked.|
*           txt3  = space
*           txt4  = space
          .
        RETURN.
      ENDIF.

      CALL FUNCTION 'BAPI_USER_UNLOCK'
        EXPORTING
          username = gt_usr_alv[ ls_sel_row-row_id ]-bname
        TABLES
          return   = lt_return.
    ENDIF.
  ENDLOOP.

  PERFORM reset_data_alv.

ENDFORM.

FORM display_user_details
    USING i_row TYPE lvc_s_row.

  IF i_row IS INITIAL.
    RETURN.
  ENDIF.

  DATA:lt_return TYPE TABLE OF bapiret2
       , lt_detm TYPE lvc_t_detm.

  READ TABLE gt_usr_alv INTO DATA(ls_data) INDEX i_row.

*  SET PARAMETER ID 'XUS' FIELD ls_data-bname.
*  CALL TRANSACTION 'SU01' WITHOUT AUTHORITY-CHECK AND SKIP FIRST SCREEN.


  CALL FUNCTION 'SUID_IDENTITY_MAINT'
    EXPORTING
      i_username   = ls_data-bname
      i_tcode_mode = 6
*     i_su01_display =
    .

ENDFORM.

FORM send_email
    USING iv_user          TYPE xubname
          iv_email         TYPE adr6-smtp_addr
          iv_last_log_date TYPE xuldate
          iv_last_log_time TYPE xultime
          iv_status        TYPE string
          iv_template_name TYPE smtg_tmpl_id.

* Send email
  DATA: lo_send_request     TYPE REF TO    cl_bcs
      , lo_document         TYPE REF TO    cl_document_bcs
      , lo_recipient_sap    TYPE REF TO    if_recipient_bcs
      , lo_recipient_ext    TYPE REF TO    if_recipient_bcs
      , lt_text             TYPE TABLE OF  solisti1
      , lt_attachment       TYPE TABLE OF  solisti1
      , lv_date_lock        TYPE           sy-datum
      , lv_logon_timestamp  TYPE           timestamp
      , lv_timestamp_str    TYPE           string.

  lv_date_lock = sy-datum + 2.
  DATA(lv_date_lock_str) = |{ lv_date_lock DATE = ISO }|.


  TRY.
      lo_send_request = cl_bcs=>create_persistent( ).

      lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).

* Determine recipient
      lo_recipient_sap = cl_sapuser_bcs=>create( iv_user ).
      CALL METHOD lo_send_request->add_recipient
        EXPORTING
          i_recipient = lo_recipient_sap
          i_express   = 'X'.

*      IF p_email IS NOT INITIAL.
      lo_recipient_ext = cl_cam_address_bcs=>create_internet_address('n1lqtdx@gmail.com' ).
      CALL METHOD lo_send_request->add_recipient
        EXPORTING
          i_recipient = lo_recipient_ext
          i_express   = 'X'.
*      ENDIF.

      DATA(lo_email_api_ref) = cl_smtg_email_api=>get_instance( iv_template_id = iv_template_name ).
      DATA(i_cds_key) = VALUE if_smtg_email_template=>ty_gt_data_key(  ).
      CONVERT DATE iv_last_log_date
              TIME iv_last_log_time
              INTO TIME STAMP lv_logon_timestamp TIME ZONE 'UTC'.
      CALL FUNCTION 'RRBA_CONVERT_TIMESTAMP_TO_STR'
        EXPORTING
          i_timestamp = lv_logon_timestamp
        IMPORTING
          e_output    = lv_timestamp_str.
      .

      " Body
      lo_email_api_ref->render(
          EXPORTING
              iv_language = sy-langu
              it_data_key = i_cds_key
          IMPORTING
              ev_subject = DATA(lv_subject)
              ev_body_html = DATA(lv_body_html) ).
      CASE iv_template_name.
        WHEN 'ZTEMPLATE_EMAIL_LOCK_NOTIF'.
          CONDENSE iv_user.
          REPLACE ALL OCCURRENCES OF '{{ ID }}' IN lv_body_html WITH iv_user.
          REPLACE ALL OCCURRENCES OF '{{ inactiveDate }}' IN lv_body_html WITH lv_date_lock_str.
          REPLACE ALL OCCURRENCES OF '{{ longReason }}' IN lv_body_html WITH 'manually locked by admin'.
          REPLACE ALL OCCURRENCES OF '{{ shortReason }}' IN lv_body_html WITH 'MNL'.
          REPLACE ALL OCCURRENCES OF '{{ lastLogonTime }}' IN lv_body_html WITH lv_timestamp_str.
          REPLACE ALL OCCURRENCES OF '{{ session }}' IN lv_body_html WITH sy-mandt.
          REPLACE ALL OCCURRENCES OF '{{ status }}' IN lv_body_html WITH iv_status.
        WHEN 'ZTEMPLATE_EMAIL_LOCK_WARNING'.
          CONDENSE iv_user.
          REPLACE ALL OCCURRENCES OF '{{ ID }}' IN lv_body_html WITH iv_user.
          REPLACE ALL OCCURRENCES OF '{{ inactiveDate }}' IN lv_body_html WITH lv_date_lock_str.
          REPLACE ALL OCCURRENCES OF '{{ longReason }}' IN lv_body_html WITH 'inactive for 30 days'.
          REPLACE ALL OCCURRENCES OF '{{ shortReason }}' IN lv_body_html WITH 'I30Ds'.
          REPLACE ALL OCCURRENCES OF '{{ lastLogonTime }}' IN lv_body_html WITH lv_timestamp_str.
          REPLACE ALL OCCURRENCES OF '{{ session }}' IN lv_body_html WITH sy-mandt.
          REPLACE ALL OCCURRENCES OF '{{ status }}' IN lv_body_html WITH iv_status.
      ENDCASE.

      DATA(lv_body_html_soli) = cl_bcs_convert=>string_to_soli( lv_body_html ). " Build HTML for Sending
      DATA(lo_multipart_ref) = NEW cl_gbt_multirelated_service( ).

      lo_multipart_ref->set_main_html(
          EXPORTING
              content      = lv_body_html_soli
              description  = 'GIs Not Posted' ).

* Create & Set the Email Document
      lo_document = cl_document_bcs=>create_document(
          EXPORTING
              i_subject        = CONV so_obj_des( lv_subject )  " Set the Email Subject
              i_text           = lv_body_html_soli
              i_type = 'HTM' ).

      lo_send_request->set_document( i_document = lo_document ).
*      CATCH cx_send_req_bcs.

* Send mail
      lo_send_request->send( i_with_error_screen = 'X' ).
    CATCH cx_send_req_bcs INTO DATA(lx_send_req_bcs).
      WRITE: 'Email sending failed: ', lx_send_req_bcs->get_text( ).

    CATCH cx_document_bcs INTO DATA(lx_document_bcs).
      WRITE: 'Creating document failed: ', lx_document_bcs->get_text( ).

    CATCH cx_address_bcs INTO DATA(lx_address_bcs).
      WRITE: 'Assigning address failed: ',  lx_address_bcs->get_text( ).

    CATCH cx_smtg_email_common INTO DATA(lx_smth_email_common).
      WRITE: 'Email template failed: ', lx_smth_email_common->get_text(  ).

    CATCH cx_bcom_mime INTO DATA(lx_bcom_mime).
      WRITE: 'MIME failed: ', lx_bcom_mime->get_text(  ).

    CATCH cx_gbt_mime INTO DATA(lx_gbt_mime).
      WRITE: 'GBT framework failed: ', lx_gbt_mime->get_text(  ).

  ENDTRY.

  COMMIT WORK.
  WRITE:/ 'Email with attachment sent!'.
ENDFORM.

FORM reset_data_alv.
  CLEAR gt_usr_alv.
  PERFORM get_data.
  go_grid->refresh_table_display(  ).
ENDFORM.
