REPORT ztrcktrsr_sm30_navigation.

PARAMETERS p_table TYPE tabname DEFAULT 'ZTT_DEMO1'.

CLASS lcl_tree DEFINITION.
  PUBLIC SECTION.
    TYPES tt_sellist TYPE STANDARD TABLE OF vimsellist.

    DATA mo_tree               TYPE REF TO cl_gui_alv_tree_simple.
    DATA mt_sort               TYPE lvc_t_sort. "Sortiertabelle
    DATA mr_data               TYPE REF TO data.
    DATA ms_tvdir              TYPE tvdir.
    DATA mv_callstack_counter  TYPE i.

    DATA mt_sellist               TYPE STANDARD TABLE OF vimsellist.
    DATA mt_x_header              TYPE STANDARD TABLE OF vimdesc.
    DATA mt_x_namtab              TYPE STANDARD TABLE OF vimnamtab.



    METHODS handle_node_double_click
                  FOR EVENT node_double_click OF cl_gui_alv_tree_simple
      IMPORTING grouplevel index_outtab.
    METHODS handle_item_double_click
                  FOR EVENT item_double_click OF cl_gui_alv_tree_simple
      IMPORTING grouplevel index_outtab fieldname.
    METHODS build_sort_table.
    METHODS register_events.
    METHODS set_view IMPORTING viewname TYPE clike RAISING cx_axt.
    METHODS get_view_data.
    METHODS init_tree.
    METHODS constructor.
    METHODS view_maintenance_call IMPORTING it_sellist TYPE tt_sellist.

ENDCLASS.

DATA main TYPE REF TO lcl_tree.

CLASS lcl_tree IMPLEMENTATION.
  METHOD constructor.
  ENDMETHOD.

  METHOD set_view.
    SELECT SINGLE * FROM tvdir INTO ms_tvdir WHERE tabname = viewname.
    IF sy-subrc > 0.
      RAISE EXCEPTION TYPE cx_axt.
    ENDIF.
  ENDMETHOD.

  METHOD handle_item_double_click.

    handle_node_double_click(
      grouplevel   = grouplevel
      index_outtab = index_outtab ).

  ENDMETHOD.

  METHOD handle_node_double_click.

    FIELD-SYMBOLS <lt_data>            TYPE STANDARD TABLE.
    ASSIGN mr_data->* TO <lt_data>.
    DATA lt_dba_sellist                TYPE STANDARD TABLE OF vimsellist.
    DATA ls_dbasellist                 TYPE  vimsellist.

    "Get current hierarchy
    mo_tree->get_hierarchy( IMPORTING et_sort = DATA(lt_sort) ).

    IF grouplevel = space.
      "clicked on entry
      ASSIGN <lt_data>[ index_outtab ] TO FIELD-SYMBOL(<ls_data>).
      CHECK sy-subrc = 0.

      LOOP AT lt_sort INTO DATA(ls_sort).
        ASSIGN COMPONENT ls_sort-fieldname OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<lv_value>).
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        APPEND INITIAL LINE TO lt_dba_sellist ASSIGNING FIELD-SYMBOL(<ls_sellist>).
        <ls_sellist>-viewfield = ls_sort-fieldname.
        <ls_sellist>-operator  = 'EQ'.
        <ls_sellist>-value     = <lv_value>.
        <ls_sellist>-and_or    = 'AND'.
        READ TABLE mt_x_namtab TRANSPORTING NO FIELDS WITH KEY viewfield = ls_sort-fieldname.
        <ls_sellist>-tabix     = sy-tabix.
      ENDLOOP.

    ELSE.
      "Clicked on hierarchy node
      ASSIGN <lt_data>[ index_outtab ] TO <ls_data>.
      IF sy-subrc = 0.
        LOOP AT lt_sort INTO ls_sort.
          "Fill up all field from start of hierarchy to clicked node
          ASSIGN COMPONENT ls_sort-fieldname OF STRUCTURE <ls_data> TO <lv_value>.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.
          APPEND INITIAL LINE TO lt_dba_sellist ASSIGNING <ls_sellist>.
          <ls_sellist>-viewfield = ls_sort-fieldname.
          <ls_sellist>-operator  = 'EQ'.
          <ls_sellist>-value     = <lv_value>.
          <ls_sellist>-and_or    = 'AND'.
          READ TABLE mt_x_namtab TRANSPORTING NO FIELDS WITH KEY viewfield = ls_sort-fieldname.
          <ls_sellist>-tabix     = sy-tabix.
          IF ls_sort-fieldname = grouplevel.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    CHECK <ls_data> IS ASSIGNED.

    IF mv_callstack_counter > 50.
      MESSAGE 'Navigation not possible anymore. Sorry' TYPE 'I'.
      RETURN. "handle_double_click
    ENDIF.

    ADD 1 TO mv_callstack_counter.

    view_maintenance_call( lt_dba_sellist ).

  ENDMETHOD.


  METHOD get_view_data.

    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    CREATE DATA mr_data TYPE STANDARD TABLE OF (ms_tvdir-tabname).
    ASSIGN mr_data->* TO <lt_data>.


    "Get info about table/ view
    CALL FUNCTION 'VIEW_GET_DDIC_INFO'
      EXPORTING
        viewname        = ms_tvdir-tabname
      TABLES
        sellist         = mt_sellist
        x_header        = mt_x_header
        x_namtab        = mt_x_namtab
      EXCEPTIONS
        no_tvdir_entry  = 1
        table_not_found = 2
        OTHERS          = 3.
    IF sy-subrc = 0.
      "Get data of view
      CALL FUNCTION 'VIEW_GET_DATA'
        EXPORTING
          view_name = ms_tvdir-tabname
        TABLES
          data      = <lt_data>
        EXCEPTIONS
          OTHERS    = 6.
    ENDIF.

  ENDMETHOD.                               " BUILD_OUTTAB

  METHOD build_sort_table.

    DATA ls_sort TYPE lvc_s_sort.
    DATA lv_idx  TYPE i.

    LOOP AT mt_x_namtab INTO DATA(ls_namtab)
    WHERE keyflag   = abap_true
      AND datatype <> 'CLNT'.
      ADD 1 TO lv_idx.
      ls_sort-fieldname = ls_namtab-viewfield.
      ls_sort-seltext   = ls_namtab-scrtext_l.
      ls_sort-spos      = lv_idx.
      ls_sort-up        = abap_true.
      APPEND ls_sort TO mt_sort.
    ENDLOOP.

  ENDMETHOD.                               " BUILD_SORT_TABLE


  METHOD register_events.

    mo_tree->set_registered_events( VALUE #(
          "Used here for applying current data selection
          ( eventid = cl_gui_column_tree=>eventid_node_double_click )
          ( eventid = cl_gui_column_tree=>eventid_item_double_click )
          "Important! If not registered nodes will not expand ->No data
          ( eventid = cl_gui_column_tree=>eventid_expand_no_children ) ) ).

    SET HANDLER handle_node_double_click FOR mo_tree.
    SET HANDLER handle_item_double_click FOR mo_tree.

  ENDMETHOD.                               " register_events


  METHOD init_tree.

    get_view_data( ).
    build_sort_table( ).

    DATA(docker) = NEW cl_gui_docking_container(
                            ratio = 25
                            side  = cl_gui_docking_container=>dock_at_left
                            dynnr = CONV #( ms_tvdir-liste )
                            repid = |SAPL{ ms_tvdir-area }| "'SAPLSVIM'
                            no_autodef_progid_dynnr = abap_false ).

* create tree control
    CREATE OBJECT mo_tree
      EXPORTING
        i_parent              = docker
        i_node_selection_mode = cl_gui_column_tree=>node_sel_mode_multiple
        i_item_selection      = 'X'
        i_no_html_header      = ''
        i_no_toolbar          = ''.


* repid for saving variants
    DATA: ls_variant TYPE disvariant.
    ls_variant-report = sy-repid.

* register events
    register_events( ).


    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN mr_data->* TO <lt_data>.

    DATA lt_grouplevel        TYPE lvc_t_fimg.
    DATA ls_grouplevel        TYPE lvc_s_fimg.
    DATA lv_field_description TYPE text50.
    DATA lt_dba_sellist       TYPE STANDARD TABLE OF vimsellist.

    LOOP AT mt_sort INTO DATA(ls_sort).
      ls_grouplevel-grouplevel = ls_sort-fieldname.
      lv_field_description = mt_x_namtab[ viewfield = ls_sort-fieldname ]-scrtext_l.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          name       = 'ICON_OPEN_FOLDER'
          text       = ls_sort-fieldname
          info       = lv_field_description
          add_stdinf = ' '
        IMPORTING
          result     = ls_grouplevel-exp_image.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          name       = 'ICON_CLOSED_FOLDER'
          text       = ls_sort-fieldname
          info       = lv_field_description
          add_stdinf = ' '
        IMPORTING
          result     = ls_grouplevel-n_image.
      APPEND ls_grouplevel TO lt_grouplevel.
    ENDLOOP.
*    mo_tree->set_grouplevel_layout( lt_grouplevel ).


* create hierarchy
    CALL METHOD mo_tree->set_table_for_first_display
      EXPORTING
        i_save               = 'A'
        is_variant           = ls_variant
        i_structure_name     = ms_tvdir-tabname
        it_grouplevel_layout = lt_grouplevel
      CHANGING
        it_sort              = mt_sort
        it_outtab            = <lt_data>.

    "expand first level
    mo_tree->expand_tree( 1 ).

    " optimize column-width
    CALL METHOD mo_tree->column_optimize
      EXPORTING
        i_start_column = mt_sort[ 1 ]-fieldname
        i_end_column   = mt_sort[ lines( mt_sort ) ]-fieldname.

    view_maintenance_call( lt_dba_sellist ).

  ENDMETHOD.

  METHOD view_maintenance_call.

    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING
        action      = 'S'
        view_name   = ms_tvdir-tabname
      TABLES
        dba_sellist = it_sellist
      EXCEPTIONS
        OTHERS      = 15.

  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  CHECK main IS INITIAL.
  main = NEW #( ).
  TRY.
      main->set_view( viewname = p_table ).
      main->init_tree( ).
    CATCH cx_axt.
  ENDTRY.
