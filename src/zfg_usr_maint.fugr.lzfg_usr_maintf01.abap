*----------------------------------------------------------------------*
***INCLUDE LZFG_USR_MAINTF01.
*----------------------------------------------------------------------*
FORM create.

  IF ztb_user-bname IS INITIAL.
    MESSAGE 'bname cannot be null' TYPE 'E'.
  ENDIF.

* Auto-insert lock date
  IF ztb_user-available_days IS NOT INITIAL
  AND ztb_user-inactive_date IS INITIAL.
    ztb_user-inactive_date = sy-datum + ztb_user-available_days.
  ENDIF.

ENDFORM.

FORM validate.

  DATA: it_total_zdata TYPE TABLE OF ztb_user WITH HEADER LINE.
  DATA: lt_index   TYPE STANDARD TABLE OF sy-tabix,
        lv_index   TYPE sy-tabix,
        lv_counter TYPE sy-tabix.

  LOOP AT total.
    lv_counter = lv_counter + 1.
    IF <action> EQ 'N' OR <action> EQ 'U'.
      APPEND <vim_total_struc> TO it_total_zdata.
      APPEND lv_counter TO lt_index.
    ENDIF.
  ENDLOOP.

  IF it_total_zdata[] IS NOT INITIAL.
* Perform validation
    LOOP AT it_total_zdata.
      IF it_total_zdata-available_days IS NOT INITIAL
      AND it_total_zdata-inactive_date IS INITIAL.
        it_total_zdata-inactive_date = sy-datum + it_total_zdata-available_days.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Write changes back to <vim_total_struc>
  LOOP AT it_total_zdata.
    READ TABLE lt_index INTO lv_index INDEX sy-tabix.
    IF sy-subrc = 0.
      READ TABLE total INDEX lv_index.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING it_total_zdata TO <vim_total_struc>.
        MODIFY total INDEX lv_index FROM <vim_total_struc>.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  CHECK_ATTR_BNAME  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_attr_bname INPUT.
  IF *ztb_user-bname IS INITIAL AND ztb_user-bname IS INITIAL.
    MESSAGE 'bname cannot be null' TYPE 'E'.
    sy-subrc = 4.
    RETURN.
  ENDIF.
ENDMODULE.

FORM authorize_check.
  SELECT * FROM ztb_admin WHERE bname = @sy-uname INTO @DATA(lt_data).
  ENDSELECT.
  IF lt_data IS INITIAL.
*    MESSAGE 'You are not authorized to maintain this table' TYPE 'E'.
    vim_auth_rc = 8.
    vim_auth_msgid = 'ZMSG_ZTB_ADMIN'.      " Custom or standard message class
    vim_auth_msgno = '000'.       " Message number in that class
    vim_auth_msgv1 = sy-uname.    " Optional message variables
    vim_auth_msgv2 = 'ZTB_USER'.
  ENDIF.
ENDFORM.
