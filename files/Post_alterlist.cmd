:!:alterlist.cmd
:!:+---------------------------------------------------------------------------+
:!:| Dit script is om te bepalen welke alterscripts nog geladen moeten worden  |
:!:| Nadat de Sp's ingeladen zijn											   |
:!:+---------------------------------------------------------------------------+
:!:|                                                                           |
:!:| Parameter: geen                                                           |
:!:|                                                                           |
:!:| Stappen:                                                                  |
:!:| 1. bepaal alle scripts                                                    |
:!:| 2. bepaal reeds geladen scripts                                           |
:!:| 3. filter reeds geladen scripts                                           |
:!:|                                                                           |
:!:+---------------------------------------------------------------------------+
:!:|                                                                           |
:!:+---------------------------------------------------------------------------+

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  BEGIN SCRIPT
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Stap 1. bepaal alle scripts
::

dir /b Post_alterscripts\*.sql > allPostalterscripts.txt


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Stap 2. bepaal reeds geladen scripts
::

echo if exists (select 1 from  sysobjects where  id = object_id('alterscriptlist') and   type = 'U') > loadedPostscripts.sql
echo begin >> loadedPostscripts.sql
echo select convert(varchar,alterscriptname) from alterscriptlist >> loadedPostscripts.sql
echo end >> loadedPostscripts.sql
echo go >> loadedPostscripts.sql

:: Voer inhoud van sql-bestand uit
sqlcmd %account% -i loadedPostscripts.sql -osqlcmd.out -w256
If %errorlevel% GTR 0 (
    Echo [FOUT] sqlcmd-fout opgetreden in Pre_alterlist.cmd, proces afgebroken. >> laadscript_objects.log
    Exit /b 1
)

if exist sqlcmd.txt del sqlcmd.txt

for /F " " %%i in (sqlcmd.out) do (
       echo %%i>>sqlcmd.txt
)

echo leeg>>sqlcmd.txt

if exist sqlcmd.out del sqlcmd.out

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Stap 3. filter reeds geladen scripts
::

grep -v -f sqlcmd.txt allPostalterscripts.txt > foundPostalterscripts.txt

if exist sqlcmd.txt del sqlcmd.txt
if exist allPostalterscripts.txt del allPostalterscripts.txt

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  EINDE SCRIPT
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Goto :EOF

