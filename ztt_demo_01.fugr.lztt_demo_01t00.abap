*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 18.04.2018 at 21:46:59
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZTT_DEMO1.......................................*
DATA:  BEGIN OF STATUS_ZTT_DEMO1                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTT_DEMO1                     .
CONTROLS: TCTRL_ZTT_DEMO1
            TYPE TABLEVIEW USING SCREEN '0600'.
*.........table declarations:.................................*
TABLES: *ZTT_DEMO1                     .
TABLES: ZTT_DEMO1                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
