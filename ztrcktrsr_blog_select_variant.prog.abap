*&---------------------------------------------------------------------*
*& Report ZTRCKTRSR_BLOG_SELECT_VARIANT
*&---------------------------------------------------------------------*
REPORT ZTRCKTRSR_BLOG_SELECT_VARIANT.


PARAMETERS p1 TYPE char10.
PARAMETERS p2 TYPE char10.

*--------------------------------------------------------------------*
* Listbox zur Auswahl der Sel.bild-Variante
*--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK var WITH FRAME TITLE text-var.
PARAMETERS pa_selva TYPE raldb_vari AS LISTBOX
                                    VISIBLE LENGTH 40
                                    USER-COMMAND variant.
SELECTION-SCREEN END OF BLOCK var.

INITIALIZATION.
  PERFORM set_values.

AT SELECTION-SCREEN.
  PERFORM set_variant.


*&---------------------------------------------------------------------*
*&      Form  set_values
*&---------------------------------------------------------------------*
FORM set_values.

  DATA lt_varit         TYPE vrm_values.

* Listbox mit Varianten füllen
  SELECT variant vtext
    FROM varit INTO TABLE lt_varit
   WHERE langu  = sy-langu
     AND report = sy-repid.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id              = 'PA_SELVA'
      values          = lt_varit
    EXCEPTIONS
      id_illegal_name = 1
      OTHERS          = 2.
ENDFORM.                    "set_values

*&---------------------------------------------------------------------*
*&      Form  set_variant
*&---------------------------------------------------------------------*
FORM set_variant.

  DATA lv_selva         TYPE raldb_vari.
  DATA ls_rkey          TYPE rsvarkey.

  CASE sy-ucomm.
    WHEN 'VARIANT'.
      lv_selva        = pa_selva.
      ls_rkey-report  = sy-repid.
      ls_rkey-variant = lv_selva.
      IF pa_selva IS INITIAL.
*** An dieser Stelle kann man das Selektionsbild zurücksetzen, wenn man mag
      ENDIF.
      PERFORM %_import_vari_clnt
        USING    ls_rkey sy-subrc sy-mandt
        CHANGING sy-subrc.
      pa_selva = lv_selva.
  ENDCASE.

ENDFORM.                    "set_variant
