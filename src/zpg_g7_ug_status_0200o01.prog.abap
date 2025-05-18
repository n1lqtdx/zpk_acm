*----------------------------------------------------------------------*
***INCLUDE ZPG_G7_UG_STATUS_0200O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
* SET PF-STATUS 'xxxxxxxx'.
* SET TITLEBAR 'xxx'.
ENDMODULE.

MODULE init_0200 OUTPUT.
  PERFORM init_0200.
  PERFORM display_0200.
ENDMODULE.

FORM init_0200.
  go_container = NEW cl_gui_custom_container( container_name = 'CONTAINER_ALV' ).
  go_grid = NEW cl_gui_alv_grid( i_parent = go_container ).
ENDFORM.

FORM display_0200.
  REFRESH gt_fieldcat[].
  " Define field properties
  gt_fieldcat = VALUE #(
*    ( fieldname = 'sel'         reptext = 'X'       col_pos = 1   outputlen = 6   just = 'C' edit = 'X' tabname = 'I_DATA' seltext = 'Checkbox' checkbox = 'X' )
    ( fieldname = 'user_status'           reptext = 'Locked'                 outputlen = 4   just = 'C' edit = '' )
    ( fieldname = 'bname'          reptext = 'User name'             outputlen = 18  just = 'L' edit = ''  key = 'X' )
    ( fieldname = 'lock_date'            reptext = 'Lock date'             outputlen = 10  just = 'L' edit = '')
    ( fieldname = 'gname'               reptext = 'Group name'             outputlen = 10  just = 'L' edit = '')
    ( fieldname = 'gst'            reptext = 'Group Schedule Time'  outputlen = 10   just = 'C' edit = '')
    ( fieldname = 'mid'                  reptext = 'Max Inactive Day'      outputlen = 15  just = 'L' edit = '')
    ( fieldname = 'ad'            reptext = 'Logon Time'             outputlen = 10  just = 'R' edit = '')
    ( fieldname = 'iad'           reptext = 'Timezone'              outputlen = 3   just = 'L' edit = '')

  ).

  go_grid->set_table_for_first_display(
  EXPORTING
      i_structure_name = 'User Job Group'
      i_save           = 'A'
      i_default        = 'X'
  CHANGING
    it_outtab            = ujg_t_01              " Output Table
    it_fieldcatalog      = gt_fieldcat               " Field Catalog
  EXCEPTIONS
    invalid_parameter_combination = 1                " Wrong Parameter
    program_error                 = 2                " Program Errors
    too_many_lines                = 3                " Too many Rows in Ready for Input Grid
    OTHERS                        = 4
    ).
ENDFORM.
