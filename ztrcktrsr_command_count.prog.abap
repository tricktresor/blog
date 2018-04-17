REPORT.

"Counts the number of commands in methods or forms of a report/ class.

CLASS lcl_rinfo DEFINITION.
  PUBLIC SECTION.
    METHODS analyze_prog IMPORTING object TYPE clike.
    METHODS analyze_clas IMPORTING object TYPE clike.
    METHODS display IMPORTING min TYPE i..
    METHODS constructor.

  PROTECTED SECTION.
    TYPES: BEGIN OF ts_data,
             repid TYPE syrepid,
             type  TYPE c LENGTH 10,
             name  TYPE c LENGTH 80,
             len   TYPE i,
           END OF ts_data,
           tt_data TYPE STANDARD TABLE OF ts_data WITH EMPTY KEY.
    METHODS get_prog_includes IMPORTING reportname TYPE clike RETURNING VALUE(includes) TYPE programt.
    METHODS get_clas_includes IMPORTING classname TYPE clike RETURNING VALUE(includes) TYPE seoincl_t.
    METHODS analyze IMPORTING object TYPE clike.

    DATA keywords   TYPE STANDARD TABLE OF char30.
    DATA mt_data    TYPE tt_data.

ENDCLASS.

DATA h_name TYPE trdir-name.
DATA h_devc TYPE devclass.
SELECT-OPTIONS s_name FOR h_name OBLIGATORY.
SELECT-OPTIONS s_devc FOR h_devc OBLIGATORY.
PARAMETERS     p_min  TYPE i DEFAULT 50.

START-OF-SELECTION.

  DATA(rinfo) = NEW lcl_rinfo( ).
  SELECT object AS obj_type, obj_name
    FROM tadir
    INTO TABLE @data(objects)
   WHERE obj_name     IN @s_name
     AND devclass IN @s_devc
     AND pgmid     = 'R3TR'
     AND object   IN ( 'PROG','CLAS' ).

  LOOP AT objects INTO DATA(object).
    CASE object-obj_type.
      WHEN 'PROG'.
        rinfo->analyze_prog( object-obj_name ).
      WHEN 'CLAS'.
        rinfo->analyze_clas( object-obj_name ).
    ENDCASE.
  ENDLOOP.

  rinfo->display( p_min ).

CLASS lcl_rinfo IMPLEMENTATION.

  METHOD constructor.

    keywords = VALUE #(
                        ( 'FORM' )   ( 'ENDFORM' )
                        ( 'METHOD' ) ( 'ENDMETHOD' )
                        ( 'MODULE' ) ( 'ENDMODULE' )
                        ).

  ENDMETHOD.

  METHOD get_prog_includes.
    DATA include_names TYPE programt.
    DATA include_name  TYPE program.
    CALL FUNCTION 'RS_GET_ALL_INCLUDES'
      EXPORTING
        program    = CONV syrepid( reportname )
      TABLES
        includetab = include_names
      EXCEPTIONS
        OTHERS     = 3.
    IF sy-subrc = 0.

      LOOP AT include_names INTO include_name.
        analyze( include_name ).
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD get_clas_includes.

    includes = cl_oo_classname_service=>get_all_class_includes( CONV #( classname ) ).

  ENDMETHOD.

  METHOD analyze_prog.
    rinfo->analyze( object ).
    LOOP AT get_prog_includes( object ) INTO DATA(prog_include).
      analyze_prog( prog_include ).
    ENDLOOP.

  ENDMETHOD.

  METHOD analyze_clas.
    rinfo->analyze( object ).
    LOOP AT get_clas_includes( object ) INTO DATA(clas_include).
      analyze( clas_include ).
    ENDLOOP.

  ENDMETHOD.



  METHOD analyze.

    DATA source     TYPE STANDARD TABLE OF string.
    DATA tokens     TYPE STANDARD TABLE OF stokes.
    DATA statements TYPE STANDARD TABLE OF sstmnt.
    DATA message    TYPE string.

    READ REPORT object INTO source.

    DATA ls_data TYPE ts_data.

    SCAN ABAP-SOURCE source
         TOKENS INTO tokens
         MESSAGE INTO message
         KEYWORDS FROM keywords
         STATEMENTS INTO statements.
*break-point.
    LOOP AT statements INTO DATA(statement).
      DATA(command) = tokens[ statement-from ]-str.

      CASE command.
        WHEN 'FORM'
          OR 'METHOD'
          OR 'MODULE'.
          CLEAR ls_data.
          ls_data-repid = object.
          ls_data-type  = command.
          ls_data-name  = tokens[ statement-from + 1 ]-str.
          ls_data-len   = statement-number.
        WHEN OTHERS.
          ls_data-len  = statement-number - ls_data-len.
          APPEND ls_data TO mt_data.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD display.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table   = DATA(o_table)
          CHANGING
            t_table        = mt_data
        ).
        o_table->get_functions( )->set_all( ).
        o_table->get_sorts( )->add_sort(
            columnname         = 'LEN'
            position           = 1
            sequence           = if_salv_c_sort=>sort_down ).

        o_table->get_filters( )->add_filter( columnname = 'LEN'
                                             sign       = 'I'
                                             option     = 'GE'
                                             low        = CONV #( min ) ).
        o_table->display( ).
      CATCH cx_salv_error.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
