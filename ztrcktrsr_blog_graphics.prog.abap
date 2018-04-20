*&---------------------------------------------------------------------*
*& Report ZTRCKTRSR_BLOG_GRAPHICS
*&---------------------------------------------------------------------*
REPORT ZTRCKTRSR_BLOG_GRAPHICS.


DEFINE html.
  ls_html = &1. "HTML schreiben
  APPEND ls_html TO lt_html. "An HTML Ausgabetabelle hängen
END-OF-DEFINITION.

TABLES: s032.
TYPES: BEGIN OF ty_s032,
         werks   TYPE werks_d,
         wbwbest TYPE wbwbest,
       END OF ty_s032.
"Daten
DATA: gt_data TYPE TABLE OF ty_s032.
"Für HTML ausgabe
DATA: lt_html         TYPE TABLE OF char255, "hier landet der HTMl Code drin
      ls_html         LIKE LINE OF lt_html, "eine zeile HTML Code
      lo_container    TYPE REF TO cl_gui_custom_container, "für die Ausgabe
      lo_html_control TYPE REF TO cl_gui_html_viewer, "für die Ausgabe
      lf_url(1024),
      lf_lines        TYPE i, " Anzahl Zeilen
      lf_komma(1). "letzter Datensatz darf kein Komma haben
FIELD-SYMBOLS: <fs_data> TYPE ty_s032.
SELECT-OPTIONS: s_werks FOR s032-werks.

INITIALIZATION.

  DATA(docker) = NEW cl_gui_docking_container( ratio = 90 side = cl_gui_docking_container=>dock_at_bottom ).
  CREATE OBJECT lo_html_control
    EXPORTING
      parent = docker.

AT SELECTION-SCREEN.
  "Alle Bestände je Werk aus der S032 summieren
  SELECT werks SUM( wbwbest ) AS wbwbest
    FROM s032
    INTO CORRESPONDING FIELDS OF TABLE gt_data
   WHERE werks IN s_werks
     AND vrsio = '000'
     GROUP BY werks .
  "Sodele, itab gt_data ist gefüllt --> Ausgabe als Kuchendiagramm.
  "Das folgende Coding füllt den HTML Code in eine interne Tabelle.
  "per ABAP macro wird der Code deutlich leserlicher
  html `<html>`. "HTML schreiben
  html ` <head>`. "HTML schreiben
  html ` <script type="text/javascript" src="https://www.google.com/jsapi"></script>`.
  html ` <script type="text/javascript">`.
  html ` google.load("visualization", "1", {packages:["corechart"]});`.
  html ` google.setOnLoadCallback(drawChart);`.
  html ` function drawChart() {`.
  html ` var data = google.visualization.arrayToDataTable([`.
  "Hier kommt der spannende Teil, in dem die "Nutzdaten" gefüllt werden
  html ` ['Werk', 'Bestand'],`.
  lf_lines = lines( gt_data ).
  "jetzt per Loop die itab in JavaScript "umbauen"
  "Der letzte Datensatz darf nicht mit Komma abgeschlossen werden, daher lf_komma
  lf_komma = ','.
  LOOP AT gt_data ASSIGNING <fs_data>.
    IF sy-tabix = lf_lines. "letzter Datensatz? Dann kein Komma
      FREE: lf_komma.
    ENDIF.
    ls_html = ` ['` && <fs_data>-werks && `', ` && <fs_data>-wbwbest && `] ` && lf_komma.
    APPEND ls_html TO lt_html.
  ENDLOOP.
  html ` ]);`.
  html ` var options = {`.
  html ` title: 'Hier kann ein Titel eingegeben werden'`.
  html ` };`.
  html ` var chart = new google.visualization.PieChart(document.getElementById('piechart'));`.
  html ` chart.draw(data, options);`.
  html ` }`.
  html ` </script>`.
  html ` </head>`.
  "Ab hier kommt der BODY des HTML Dokuments. Wenn man keinen TITLE an die Grafik schickt, kann man dies hier im HTML machen
  html ` <body>`.
  html ` <div id="piechart" style="width: 900px; height: 500px;"></div>`.
  html ` </body>`.
  html `</html>`.

  lf_url = 'AWI.html'.
  CALL METHOD lo_html_control->load_data
    EXPORTING
      url          = lf_url
    IMPORTING
      assigned_url = lf_url
    CHANGING
      data_table   = lt_html[].

* HTML im VIEWER anzeigen
  lo_html_control->show_url( lf_url ).
