*&---------------------------------------------------------------------*
*& Report ZPG_G7_UG
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpg_g7_ug.

DATA: go_grid                TYPE REF TO cl_gui_alv_grid
    , go_container           TYPE REF TO cl_gui_custom_container
    , gt_fieldcat            TYPE TABLE OF lvc_s_fcat.

  TYPES: BEGIN OF usr_jg,
           bname       TYPE xubname,
           user_status TYPE c LENGTH 3,
           lock_date   TYPE c LENGTH 10,
           gname       TYPE c LENGTH 8,
           gst         TYPE xultime,
           mid         TYPE int2,
           ad          TYPE xuldate,
           iad         TYPE xuldate,
         END OF usr_jg.

  DATA: ujg_01   TYPE usr_jg,
        ujg_t_01 TYPE TABLE OF usr_jg.


INCLUDE zpg_g7_ug_status_0200o01.

FORM get_data.

  SELECT u~bname,
         CASE u~il
            WHEN 'X' THEN 'YES'
            ELSE 'NO'
            END AS user_status,
         CASE u~ld
            WHEN '00000000' THEN ' '
            ELSE u~ld
         END AS lock_date,
         g~gname,
         g~gst, g~mid, g~ad, g~iad

  FROM zusr_g7_ujg AS u
  LEFT JOIN zusr_g7_jobgroup AS g
  ON u~gname = g~gname
  INTO TABLE @DATA(ujg).

  ujg_t_01 = CORRESPONDING #( ujg ).
ENDFORM.

FORM display.
  IF ujg_t_01 IS NOT INITIAL.
    CALL SCREEN '200'.
  ELSE.
    MESSAGE 'No data available' TYPE 'I'.
    EXIT.
  ENDIF.
ENDFORM.


START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display.
*cl_demo_output=>display_data( ujg_t_01 ).
