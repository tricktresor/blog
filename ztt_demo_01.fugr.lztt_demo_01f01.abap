*----------------------------------------------------------------------*
***INCLUDE LZTT_DEMO_01F01.
*----------------------------------------------------------------------*
*
*
*CLASS lcl_handler DEFINITION FINAL.
*  PUBLIC SECTION.
*    CLASS-METHODS
*      handle_tree_item FOR EVENT item_double_click OF cl_gui_alv_tree_simple
*        IMPORTING
*            fieldname
*            grouplevel
*            index_outtab
*            sender.
*    CLASS-METHODS
*      handle_tree_node FOR EVENT node_double_click OF cl_gui_alv_tree_simple
*        IMPORTING
*            grouplevel
*            index_outtab
*            sender.
*
*ENDCLASS.
*
*CLASS lcl_handler IMPLEMENTATION.
*  METHOD handle_tree_node.
*    zcl_helper_sm30_nav=>grouplevel   = grouplevel .
*    zcl_helper_sm30_nav=>index_outtab = index_outtab .
**    break-point.
*    RAISE EXCEPTION TYPE zcx_abapchallenge.
*  ENDMETHOD.
*
*  METHOD handle_tree_item.
*    zcl_helper_sm30_nav=>grouplevel   = grouplevel .
*    zcl_helper_sm30_nav=>index_outtab = index_outtab .
**    break-point.
*    RAISE EXCEPTION TYPE zcx_abapchallenge.
*  ENDMETHOD.
*
*ENDCLASS.

FORM ztg_event_19.
*  set handler lcl_handler=>handle_tree_idc for ZCL_HELPER_SM30_NAV=>mo_tree ACTIVATION 'STEFAN'.
*  CHECK zcl_helper_sm30_nav=>mo_tree IS BOUND.
*  SET HANDLER lcl_handler=>handle_tree_item FOR zcl_helper_sm30_nav=>mo_tree.
*  SET HANDLER lcl_handler=>handle_tree_node FOR zcl_helper_sm30_nav=>mo_tree.
ENDFORM.
