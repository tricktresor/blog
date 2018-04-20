REPORT ztrcktrsr_blog_maint_nav.


CLASS lcl_view_maint_tree_navi DEFINITION.

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        io_container TYPE REF TO cl_gui_container .
    METHODS init
      IMPORTING
        iv_viewname TYPE clike
        iv_action   TYPE char01
        it_sellist  TYPE scprvimsellist OPTIONAL .
  PROTECTED SECTION.

    DATA mt_sort TYPE lvc_t_sort .
    DATA mo_container TYPE REF TO cl_gui_container .
    DATA mv_viewname TYPE tabname .
    DATA mo_tree TYPE REF TO cl_gui_alv_tree_simple .
    DATA mo_data TYPE REF TO data .
    DATA mo_struc TYPE REF TO cl_abap_structdescr .
    DATA mo_table TYPE REF TO cl_abap_tabledescr .
    DATA mt_group_level TYPE lvc_t_fimg .
    DATA mv_callstack_counter TYPE i .
    DATA mv_action TYPE char01 .
    DATA mt_sellist TYPE scprvimsellist .

    METHODS handle_node_doubleclick
          FOR EVENT node_double_click OF cl_gui_alv_tree_simple
      IMPORTING
          grouplevel
          index_outtab .
    METHODS create_data_table .
    METHODS build_sort .
    METHODS read_data .
    METHODS init_data .
    METHODS tree_init .
    METHODS tree_register_events .
    METHODS handle_item_doubleclick
          FOR EVENT item_double_click OF cl_gui_alv_tree_simple
      IMPORTING
          fieldname
          index_outtab
          grouplevel .
  PRIVATE SECTION.
ENDCLASS.



PARAMETERS pa_view TYPE tabname DEFAULT 'V_T001L'.
"V_T028P

PARAMETERS pa_show RADIOBUTTON GROUP mnt DEFAULT 'X'.
PARAMETERS pa_edit RADIOBUTTON GROUP mnt.


AT SELECTION-SCREEN.
  SELECT SINGLE * FROM tvdir INTO @DATA(gs_tvdir)
   WHERE tabname = @pa_view.
  IF sy-subrc > 0.
    MESSAGE s000(oo) WITH 'Kein Pflegedialog vorhanden!'.
    STOP.
  ENDIF.

START-OF-SELECTION.



  DATA(go_dock) = NEW cl_gui_docking_container(
                           ratio                   = 25
                           side                    = cl_gui_docking_container=>dock_at_left
                           no_autodef_progid_dynnr = 'X' ).
  DATA(go_nmv_tree) = NEW lcl_view_maint_tree_navi( go_dock ).
  DATA(gv_action) = COND char01( WHEN pa_show = abap_true THEN 'S' ELSE 'U' ).
  go_nmv_tree->init( iv_viewname = pa_view iv_action = gv_action ).



  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
    EXPORTING
      action                       = gv_action
      view_name                    = pa_view
    EXCEPTIONS
      client_reference             = 1
      foreign_lock                 = 2
      invalid_action               = 3
      no_clientindependent_auth    = 4
      no_database_function         = 5
      no_editor_function           = 6
      no_show_auth                 = 7
      no_tvdir_entry               = 8
      no_upd_auth                  = 9
      only_show_allowed            = 10
      system_failure               = 11
      unknown_field_in_dba_sellist = 12
      view_not_found               = 13
      maintenance_prohibited       = 14
      OTHERS                       = 15.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid
          TYPE sy-msgty
        NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


CLASS lcl_view_maint_tree_navi IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->BUILD_SORT
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD build_sort.


    DATA ls_sort     TYPE lvc_s_sort.
    DATA ls_group    TYPE lvc_s_fimg.
    DATA lv_position TYPE i.

    CLEAR mt_sort.
    CLEAR mt_group_level.

    DATA(lt_fields) = mo_struc->get_ddic_field_list( ).

    SORT lt_fields BY position.
*      "create sort-table
    LOOP AT lt_fields INTO DATA(ls_field)
       WHERE keyflag = abap_true.
      CHECK ls_field-fieldname <> 'MANDT'.
      ADD 1 TO lv_position.
      ls_sort-spos      = lv_position.
      ls_sort-fieldname = ls_field-fieldname.
      ls_sort-down      = abap_true.
      ls_sort-subtot    = abap_false.
      APPEND ls_sort TO mt_sort.
      ls_group-grouplevel = ls_sort-spos.
*      ls_group-n_image    = ycl_icon=>create( iv_icon = icon_okay iv_info = ls_field-scrtext_m ).
*      ls_group-exp_image  = ycl_icon=>create( iv_icon = icon_okay iv_info = ls_field-scrtext_m ).
*      APPEND ls_group TO mt_group_level.
    ENDLOOP.


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method LCL_VIEW_MAINT_TREE_NAVI->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_CONTAINER                   TYPE REF TO CL_GUI_CONTAINER
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.

    mo_container = io_container.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->CREATE_DATA_TABLE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD create_data_table.


    DATA lo_element           TYPE REF TO cl_abap_elemdescr.
    DATA lt_comp              TYPE cl_abap_structdescr=>component_table.
    DATA ls_comp              LIKE LINE OF lt_comp.
    DATA hf_fieldname         TYPE fieldname.

    mo_struc ?= cl_abap_elemdescr=>describe_by_name( mv_viewname ).

    "create table by structure reference
    mo_table = cl_abap_tabledescr=>create(
                     p_line_type  = mo_struc
                     p_table_kind = cl_abap_tabledescr=>tablekind_std
                     p_unique     = abap_false ).

    "create data handle for table
    CREATE DATA mo_data TYPE HANDLE mo_table.


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->HANDLE_ITEM_DOUBLECLICK
* +-------------------------------------------------------------------------------------------------+
* | [--->] FIELDNAME                      LIKE
* | [--->] INDEX_OUTTAB                   LIKE
* | [--->] GROUPLEVEL                     LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD handle_item_doubleclick.

    handle_node_doubleclick( index_outtab = index_outtab grouplevel = grouplevel ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->HANDLE_NODE_DOUBLECLICK
* +-------------------------------------------------------------------------------------------------+
* | [--->] GROUPLEVEL                     LIKE
* | [--->] INDEX_OUTTAB                   LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD handle_node_doubleclick.

    FIELD-SYMBOLS <flt_data>       TYPE STANDARD TABLE.
    FIELD-SYMBOLS <flt_data_local> TYPE STANDARD TABLE.

    DATA lt_sellist                TYPE STANDARD TABLE OF vimsellist.
    DATA ls_sellist                TYPE  vimsellist.

    mo_tree->get_hierarchy( IMPORTING et_sort = DATA(lt_sort) ).
    "assign data to table-pointer
    ASSIGN mo_data->* TO <flt_data>.

    IF mv_callstack_counter > 0.
      SUBTRACT 1 FROM mv_callstack_counter.
*      leave to screen 0.
    ENDIF.

*    SORT <flt_data> BY CORRESPONDING #( lt_sort MAPPING name = fieldname descending = down ).

    IF grouplevel = space.
      ASSIGN <flt_data>[ index_outtab ] TO FIELD-SYMBOL(<fls_data>).
      CHECK sy-subrc = 0.
      DATA(lt_fieldlist) = mo_struc->get_ddic_field_list( ).
      LOOP AT lt_fieldlist INTO DATA(ls_field) WHERE keyflag = abap_true.
        ASSIGN COMPONENT ls_field-fieldname OF STRUCTURE <fls_data> TO FIELD-SYMBOL(<lfv_value>).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        APPEND INITIAL LINE TO lt_sellist ASSIGNING FIELD-SYMBOL(<lfs_sellist>).
        <lfs_sellist>-viewfield = ls_field-fieldname.
        <lfs_sellist>-operator  = 'EQ'.
        <lfs_sellist>-value     = <lfv_value>.
        <lfs_sellist>-and_or    = 'AND'.
      ENDLOOP.

    ELSE.

      ASSIGN <flt_data>[ index_outtab ] TO <fls_data>.
      IF sy-subrc = 0.
        LOOP AT lt_sort INTO DATA(ls_sort).
          ASSIGN COMPONENT ls_sort-fieldname OF STRUCTURE <fls_data> TO <lfv_value>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.
          APPEND INITIAL LINE TO lt_sellist ASSIGNING <lfs_sellist>.
          <lfs_sellist>-viewfield = ls_sort-fieldname.
          <lfs_sellist>-operator  = 'EQ'.
          <lfs_sellist>-value     = <lfv_value>.
          <lfs_sellist>-and_or    = 'AND'.

          IF ls_sort-fieldname = grouplevel.
            EXIT.
          ENDIF.
        ENDLOOP.

      ENDIF.
    ENDIF.

    CHECK <fls_data> IS ASSIGNED.

    ADD 1 TO mv_callstack_counter.

    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING
        action                       = mv_action
        view_name                    = mv_viewname
        no_warning_for_clientindep   = ' '
        complex_selconds_used        = 'X'
      TABLES
        dba_sellist                  = lt_sellist
      EXCEPTIONS
        client_reference             = 1
        foreign_lock                 = 2
        invalid_action               = 3
        no_clientindependent_auth    = 4
        no_database_function         = 5
        no_editor_function           = 6
        no_show_auth                 = 7
        no_tvdir_entry               = 8
        no_upd_auth                  = 9
        only_show_allowed            = 10
        system_failure               = 11
        unknown_field_in_dba_sellist = 12
        view_not_found               = 13
        maintenance_prohibited       = 14
        OTHERS                       = 15.
    IF sy-subrc = 0.
      MESSAGE s000(oo) WITH grouplevel.
* Implement suitable error handling here
    ELSE.
      MESSAGE e000(oo) WITH 'Fehler bei Aufruf View_Maintenance_Call'.
    ENDIF.


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method LCL_VIEW_MAINT_TREE_NAVI->INIT
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_VIEWNAME                    TYPE        CLIKE
* | [--->] IV_ACTION                      TYPE        CHAR01
* | [--->] IT_SELLIST                     TYPE        SCPRVIMSELLIST(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD init.

    mv_viewname = iv_viewname.
    mv_action   = iv_action.
    mt_sellist  = it_sellist.

    init_data( ).
    tree_init( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->INIT_DATA
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD init_data.

    create_data_table( ).
    read_data( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->READ_DATA
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD read_data.


    FIELD-SYMBOLS <flt_data> TYPE STANDARD TABLE.
    "assign data to table-pointer
    ASSIGN mo_data->* TO <flt_data>.


    CALL FUNCTION 'VIEW_GET_DATA'
      EXPORTING
        view_name              = mv_viewname
        without_exits          = 'X'
        with_authority_check   = ' '
        data_cont_type_x       = 'X'
        complex_selconds_used  = COND #( WHEN mt_sellist IS INITIAL THEN space ELSE 'X' )
      TABLES
        dba_sellist            = mt_sellist
        data                   = <flt_data>
      EXCEPTIONS
        no_viewmaint_tool      = 1
        no_authority           = 2
        no_auth_for_sel        = 3
        data_access_restricted = 4
        no_functiongroup       = 5
        OTHERS                 = 6.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid
            TYPE sy-msgty
          NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.



  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->TREE_INIT
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD tree_init.


    FIELD-SYMBOLS <flt_data> TYPE STANDARD TABLE.
    "assign data to table-pointer
    ASSIGN mo_data->* TO <flt_data>.

    CHECK <flt_data> IS NOT INITIAL.

    build_sort( ).

* create tree control
    CREATE OBJECT mo_tree
      EXPORTING
        i_parent              = mo_container
        i_node_selection_mode =
                                cl_gui_column_tree=>node_sel_mode_multiple
        i_item_selection      = 'X'
        i_no_html_header      = ''
        i_no_toolbar          = ''.

* repid for saving variants
    DATA: ls_variant TYPE disvariant.
    ls_variant-report = sy-repid.

* register events
    tree_register_events( ).

* create hierarchy
    CALL METHOD mo_tree->set_table_for_first_display
      EXPORTING
        i_structure_name     = mv_viewname
        i_save               = 'A'
        is_variant           = ls_variant
        it_grouplevel_layout = mt_group_level
      CHANGING
        it_sort              = mt_sort
        it_outtab            = <flt_data>.

    "GEHT NICHT :(
    "Deswegen Klasse cl_gui_simple_tree_alv kopieren und in Methode ??? anpassen
    LOOP AT <flt_data> ASSIGNING FIELD-SYMBOL(<fls_data>).
      DATA(lv_idx) = sy-tabix.
      mo_tree->change_layout(
        EXPORTING
          i_outtab_index = CONV #( lv_idx )
          it_item_layout = VALUE #( ( fieldname = 'WERKS' style = 5 u_style = abap_true ) )
          is_node_layout = VALUE #( style = lv_idx          u_style    = abap_true
                                    n_image = icon_okay     u_n_image  = abap_true
                                    exp_image = icon_cancel u_exp_imag = abap_true
                                    hidden    = abap_true   u_hidden   = abap_true )
        EXCEPTIONS
          node_not_found = 1
          OTHERS         = 2 ).
      IF sy-subrc <> 0.
      ENDIF.

    ENDLOOP.

    mo_tree->refresh_table_display( ).


* expand first level
*    mo_tree->expand_tree( 1 ).
    mo_tree->set_top( 1 ).

* optimize column-width
    mo_tree->column_optimize(
        i_start_column = mt_sort[ 1 ]-fieldname
        i_end_column   = mt_sort[ lines( mt_sort ) ]-fieldname ).


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method LCL_VIEW_MAINT_TREE_NAVI->TREE_REGISTER_EVENTS
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD tree_register_events.


* define the events which will be passed to the backend
    mo_tree->set_registered_events( VALUE #(
                           ( eventid = cl_gui_column_tree=>eventid_node_context_menu_req )
                           ( eventid = cl_gui_column_tree=>eventid_item_context_menu_req )
                           ( eventid = cl_gui_column_tree=>eventid_header_context_men_req )
                           ( eventid = cl_gui_column_tree=>eventid_expand_no_children )
                           ( eventid = cl_gui_column_tree=>eventid_header_click )
                           ( eventid = cl_gui_column_tree=>eventid_node_double_click )
                           ( eventid = cl_gui_column_tree=>eventid_item_double_click )
                           ( eventid = cl_gui_column_tree=>eventid_item_keypress )
                        ) ).

    SET HANDLER handle_node_doubleclick FOR mo_tree.
    SET HANDLER handle_item_doubleclick FOR mo_tree.


  ENDMETHOD.
ENDCLASS.
