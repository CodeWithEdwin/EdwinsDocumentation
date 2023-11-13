:!:laadscript_database.cmd
:!:+---------------------------------------------------------------------------+
:!:| Dit is het script voor het laden van de databaseobjecten                  |
:!:+---------------------------------------------------------------------------+
:!:|                                                                           |
:!:| Parameter: geen                                                           |
:!:|                                                                           |
:!:| Omschrijving:                                                             |
:!:| Runt sql-scripts tegen een op te geven database                           |
:!:|                                                                           |
:!:+---------------------------------------------------------------------------+
@Echo OFF&SetLocal ENABLEEXTENSIONS

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  bestand kan extern aangeroepen worden, dus moet de current folder juist
::  ingesteld worden, anders kan het script de bestanden niet vinden.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET drive=%~d0
%drive%
cd %~dp0



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  BEGIN SCRIPT
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  Bestanden verwijderen als deze bestaan
::
:: Bij opnieuw uitvoeren van dit script moeten deze bestanden leeg of niet
:: aanwezig zijn, anders gaat het script fout
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET FileToDelete="foundPrealterscripts.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundSPobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundAOPSPobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundspecialSPobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundspecialFNobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundFNobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundAOPFNobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundspecialVWobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundVWobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundAOPVWobjects.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%
SET FileToDelete="foundPostalterscripts.txt"
IF EXIST %FileToDelete% del /F %FileToDelete%



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  Initialiseren variabelen
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set server=%1
set database=%2
set userid=%3
SET suffix=%4
::Parameter 5 is de locatie van de root van de installatie. deze moet meegegeven worden
SET folder=%5

if [%folder%] EQU [] (
    Echo ***************************************************************************
    Echo ** Installatie root folder niet opgegeven!                               **
    Echo ***************************************************************************
    pause
    exit
)

::current directory opslaan
set currentDir=%CD%
if exist "%folder%settings_%suffix%.cmd" (
	:: indirect wordt hier de directory ook gewijzigd
    CALL "%folder%settings_%suffix%.cmd"
	
	:: restore directory
	cd %currentDir%
) else (
    Echo ***************************************************************************
    Echo ** Settings file niet gevonden!                                          **
    Echo ***************************************************************************
    pause
    exit
)

ECHO ***************************************************************************
ECHO ** Onderstaande database wordt bijgewerkt:                               **
ECHO **
ECHO ** Server   : %server%
ECHO ** Database : %database%
ECHO ***************************************************************************
CALL SetSqlcmdAccount.cmd %userid% "%DBPassword%" "%Auto_Continue_Database%" %suffix% %folder%

::voor omgevingafhankelijke SP's en functies in te laden
:: test is gelijk aan development om zo alle functies te testen
set omgevingspecial="nietingevuldeomgeving"
if "%DatabaseOmgeving%" equ "test" (
	set omgevingspecial="_D_"
)
if "%DatabaseOmgeving%" equ "development" (
	set omgevingspecial="_D_"
)
if "%DatabaseOmgeving%" equ "opleiding" (
	set omgevingspecial="_O_"
)
if "%DatabaseOmgeving%" equ "acceptatie" (
	set omgevingspecial="_A_"
)
if "%DatabaseOmgeving%" equ "productie" (
	set omgevingspecial="_P_"
)

::terug zetten in current directory, zodat installatie verder kan
cd %currentDir%

@ECHO OFF
Echo.

:: Bepalen datetime onafh van locale
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%

:: yyyyMMddHHmmss
::                                    yyyy      MM        dd        HH         mm         ss
set log=%folder%Database_LogFile_%ldt:~0,4%%ldt:~5,2%%ldt:~8,2%%ldt:~11,2%%ldt:~14,2%%ldt:~17,2%.log"

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Login testen en Versie testen
::
:: database versie moet boven de 6.23 zijn
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Call :LoginTest  || GOTO ERROR_HANDLER
Call :VersieTest  || GOTO ERROR_HANDLER

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Stored procedure folder hernoemen
::
::Het cmd script kan niet overweg met spaties in folder namen
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Echo. >> %log%
Echo *** Rename Stored Procedures folder>> %log%
Echo. >> %log%
rename "dbo\Stored Procedures", "StoredProcedures"


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Begin log
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Date /t > date.txt
Time /t > time.txt
set /p datum= < date.txt
set /p tijd=  < time.txt
del date.txt
del time.txt

Echo.
Echo Begin laadlijst databaseobjecten (%date% %time%)
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: >        %log%
Echo ::                                                                >>       %log%
Echo :: Begin laadlijst databaseobjecten (%date% %time%)               >>       %log%
Echo ::                                                                >>       %log%
Echo :: -------------------------------------------------------------  >>       %log%
Echo ::                                                                >>       %log%
Echo :: Server   : %server%                                            >>       %log%
Echo :: Database : %database%                                          >>       %log%
Echo :: UserID   : %userid%                                            >>       %log%
Echo ::                                                                >>       %log%
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: >>       %log%
Echo. >>                                                                        %log%


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Db objecten verwijderen
::
:: Alle Functions, StoredProcedures, Views verwijderen uit de DB
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Echo. >> %log%
Echo *** Functions, StoredProcedures, Views verwijderen >> %log%
  Call :Execute Vulling\DeleteDBObjects.sql                                  || GOTO ERROR_HANDLER


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Uitvoeren PRE scripts
::
:: Wijzigingsscripts uitvoeren die nodig zijn voordat de Sp's bijgewerkt worden
:: Denk aan tabel wijzigingen
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Echo. >> %log%
Echo *** Bepalen lijst met PRE alterscripts >> %log%

:: Lijst van nog uit te voeren PRE scripts op de database
Call Pre_alterlist.cmd

Echo. >> %log%
Echo *** Uitvoeren lijst met PRE alterscripts >> %log%
Echo. >> %log%

:: Pre alterscripts uitvoeren
for /F "" %%i in (foundPrealterscripts.txt) do (
       Call :Execute Pre_Alterscripts\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Speciale Views
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Echo. >> %log%
Echo *** Bepalen lijst met speciale Views >> %log%

:: Speciale Stored Procedures
:: Speciale SP's zijn SP's die in andere SP's gebruikt worden
:: Om fouten te voorkomen moeten deze eerst ingeladen worden
dir /b dbo\Views\*.sql | findstr /i "special_" | findstr /i /v "_D_" | findstr /i /v "_A_" | findstr /i /v "_O_" | findstr /i /v "_P_" >> foundspecialVWobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met speciale Views >> %log%
Echo. >> %log%

:: gevonden Stored Procedures aanmaken
for /F "" %%i in (foundspecialVWobjects.txt) do (
       Call :Execute dbo\Views\%%i  || GOTO ERROR_HANDLER
)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Speciale Stored procedures
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Echo. >> %log%
Echo *** Bepalen lijst met speciale Stored Procedures >> %log%

:: Speciale Stored Procedures
:: Speciale SP's zijn SP's die in andere SP's gebruikt worden
:: Om fouten te voorkomen moeten deze eerst ingeladen worden
dir /b dbo\StoredProcedures\*.sql | findstr /i "special_" | findstr /i /v "_D_" | findstr /i /v "_A_" | findstr /i /v "_O_" | findstr /i /v "_P_" >> foundspecialSPobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met speciale Stored Procedures >> %log%
Echo. >> %log%

:: gevonden Stored Procedures aanmaken
for /F "" %%i in (foundspecialSPobjects.txt) do (
       Call :Execute dbo\StoredProcedures\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Speciale Functions
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Echo. >> %log%
Echo *** Bepalen lijst met speciale Functions >> %log%

:: Speciale Stored Procedures
:: Speciale SP's zijn SP's die in andere SP's gebruikt worden
:: Om fouten te voorkomen moeten deze eerst ingeladen worden
dir /b dbo\Functions\*.sql | findstr /i "special_" | findstr /i /v "_D_" | findstr /i /v "_A_" | findstr /i /v "_O_" | findstr /i /v "_P_" >> foundspecialFNobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met speciale Functions >> %log%
Echo. >> %log%

:: gevonden Stored Procedures aanmaken
for /F "" %%i in (foundspecialFNobjects.txt) do (
       Call :Execute dbo\Functions\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Reguliere Functions
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met Functions >> %log%

:: Stored Procedures   excl. speciale SP's
dir /b dbo\Functions\*.sql | findstr /i /v "special_" | findstr /i /v "_D_" | findstr /i /v "_A_" | findstr /i /v "_O_" | findstr /i /v "_P_" >> foundFNobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met Functions >> %log%
Echo. >> %log%

:: gevonden Stored Procedures uitvoeren
for /F "" %%i in (foundFNobjects.txt) do (
       Call :Execute dbo\Functions\%%i  || GOTO ERROR_HANDLER
)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: AOP Functions
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met AOP Functions >> %log%

:: Stored Procedures   excl. speciale SP's
dir /b dbo\Functions\*.sql | findstr /i %omgevingspecial% >> foundAOPFNobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met AOP Functions >> %log%
Echo. >> %log%

:: gevonden Stored Procedures uitvoeren
for /F "" %%i in (foundAOPFNobjects.txt) do (
       Call :Execute dbo\Functions\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Reguliere Views
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met Views >> %log%

:: Stored Procedures   excl. speciale SP's
dir /b dbo\Views\*.sql | findstr /i /v "special_" | findstr /i /v "_D_" | findstr /i /v "_A_" | findstr /i /v "_O_" | findstr /i /v "_P_" >> foundVWobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met Views >> %log%
Echo. >> %log%

:: gevonden Stored Procedures uitvoeren
for /F "" %%i in (foundVWobjects.txt) do (
       Call :Execute dbo\Views\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: AOP Views
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met AOP Views >> %log%

:: Stored Procedures   excl. speciale SP's
dir /b dbo\Views\*.sql | findstr /i %omgevingspecial% >> foundAOPVWobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met AOP Views >> %log%
Echo. >> %log%

:: gevonden Stored Procedures uitvoeren
for /F "" %%i in (foundAOPVWobjects.txt) do (
       Call :Execute dbo\Views\%%i  || GOTO ERROR_HANDLER
)


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Reguliere Stored Procedures
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met Stored Procedures >> %log%

:: Stored Procedures   excl. speciale SP's
dir /b dbo\StoredProcedures\*.sql | findstr /i /v "special_" | findstr /i /v "_D_" | findstr /i /v "_A_" | findstr /i /v "_O_" | findstr /i /v "_P_" >> foundSPobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met Stored Procedures >> %log%
Echo. >> %log%

:: gevonden Stored Procedures uitvoeren
for /F "" %%i in (foundSPobjects.txt) do (
       Call :Execute dbo\StoredProcedures\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: AOP Stored Procedures
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met AOP Stored Procedures >> %log%

:: Stored Procedures   excl. speciale SP's
dir /b dbo\StoredProcedures\*.sql | findstr /i %omgevingspecial% >> foundAOPSPobjects.txt

Echo. >> %log%
Echo *** Uitvoeren lijst met AOP Stored Procedures >> %log%
Echo. >> %log%

:: gevonden Stored Procedures uitvoeren
for /F "" %%i in (foundAOPSPobjects.txt) do (
       Call :Execute dbo\StoredProcedures\%%i  || GOTO ERROR_HANDLER
)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Uitvoeren POST scripts
::
:: Wijzigingsscripts uitvoeren die nodig zijn Nadat de Sp's bijgewerkt zijn
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Bepalen lijst met POST alterscripts >> %log%

:: Lijst van nog uit te voeren POST scripts op de database
Call Post_alterlist.cmd

Echo. >> %log%
Echo *** Uitvoeren lijst met POST alterscripts >> %log%
Echo. >> %log%

:: gevonden alterscripts uitvoeren
for /F "" %%i in (foundPostalterscripts.txt) do (
       Call :Execute Post_Alterscripts\%%i  || GOTO ERROR_HANDLER
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Systeem parameters
::
:: Initialiseer eenmalig systeemparameters, welke afhankelijk zijn van de gekozen installatie omgeving.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Initialiseer systeemparameters indien nodig >> %log%
Call :ExecSQL "EXEC upd_systeemparameter_if_not_set @syp_module = 'interface.NAZORG',   @onderdeel = 'onderhoud', @sleutel='Email_Profile',         @par_waarde='%Nazorg_EmailProfile%'"
Call :ExecSQL "EXEC upd_systeemparameter_if_not_set @syp_module = 'interface.NAZORG',   @onderdeel = 'onderhoud', @sleutel='MailTo',                @par_waarde='%Nazorg_MailTo%'"
Call :ExecSQL "EXEC upd_systeemparameter_if_not_set @syp_module = 'interface.FVA_MAIL', @onderdeel = 'onderhoud', @sleutel='Email_Profile',         @par_waarde='%FVA_MAIL_EmailProfile%'"
Call :ExecSQL "EXEC upd_systeemparameter_if_not_set @syp_module = 'interface.FVA_MAIL', @onderdeel = 'onderhoud', @sleutel='Beheerder_email',       @par_waarde='%FVA_MAIL_BeheerderEmail%'"
Call :ExecSQL "EXEC upd_systeemparameter_if_not_set @syp_module = 'interface.FVA_MAIL', @onderdeel = 'onderhoud', @sleutel='afzender_samenvatting', @par_waarde='%FVA_MAIL_AfzenderSamenvatting%'"


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Database versie bijwerken
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Uitvoeren db_versie>> %log%
Echo. >> %log%

Call :Execute Vulling\db_versie.sql                             || GOTO ERROR_HANDLER




::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Einde log
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Date /t > date.txt
Time /t > time.txt
set /p datum= < date.txt
set /p tijd=  < time.txt
del date.txt
del time.txt

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Stored procedure folder hernoemen
::
::Het cmd script kan niet overweg met spaties in folder namen
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo. >> %log%
Echo *** Rename Stored Procedures folder>> %log%
Echo. >> %log%

rename "dbo\StoredProcedures", "Stored Procedures"

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Logfile einde
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo.
Echo Einde laadlijst databaseobjecten (%date% %time%)
Echo. >>                                                                        %log%
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: >>       %log%
Echo ::                                                                >>       %log%
Echo :: Einde laadlijst databaseobjecten (%date% %time%)               >>       %log%
Echo ::                                                                >>       %log%
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: >>       %log%

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  EINDE SCRIPT
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Goto :EOF






::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: FUNCTIES
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::
:ERROR_HANDLER
:: Fout opgetreden
Echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo ::
Echo ::   FOUT
Echo ::
echo :: Er is een fout opgetreden controleer het logbestand:
echo :: %log%
echo ::
Echo :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
pause
exit 1
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: LoginTest
::
:: Testen of de opgegeven login gegevens juist zijn
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:LoginTest
::
sqlcmd %account% -q "quit"
If %errorlevel% GTR 0 (
    echo Login gegevens [NOK]
    echo Login gegevens [NOK] >> %log%

	GOTO ERROR_HANDLER

) Else (

    echo Login gegevens [OK]
    echo Login gegevens [OK] >> %log%

)

Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: VersieTest
::
:: Testen of datbase minimaal versie 6.32 is
:: Databases voor 6.32 dienen geupdate te worden met de bij 6.3 horende database project
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:VersieTest
::
sqlcmd %account% -Q "SELECT 'results:'+(Select cast(count(*) as varchar) FROM db_versie where datamodel_versie >= '6.32')" -o versiecheck.out
If %errorlevel% GTR 0 (
    Echo Versie check [NOK]
    Echo [FOUT] sqlcmd-fout bij uitvoeren van versiecheck, proces afgebroken. >> %log%
    Type versiecheck.out >>  %log%
    Del versiecheck.out
    Exit /b 1
)
:: vreemde karakters zorgen ervoor dat findstr niet werkt, door type te gebruiken wordt dit probleem opgelost.
type versiecheck.out > versiecheck.txt
type versiecheck.txt > versiecheck.out

FindStr /I "results:1" versiecheck.out>NUL:
IF %ERRORLEVEL% NEQ 0 (
	echo Versie [NOK]
	echo Database versie moet hoger zijn dan 6.32
	Del versiecheck.txt
	Del versiecheck.out
	Exit /b 1
) ELSE (
	echo Versie [OK]
	Del versiecheck.txt
	Del versiecheck.out
)

Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: ExecSql
::
:: Voer een query uit
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ExecSQL
    :: Execute direct SQl input
    Set "queryString=%1"

    ::script uitvoeren, bij fouten komen deze in de log terecht
    sqlcmd %account% -Q %queryString% >> %log%

    IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Execute
::
:: Een sql file uitvoeren op de database
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Execute
::
Set sqlfile=%1

:: Log
Echo ...Bezig met %sqlfile%...
Echo ...Bezig met %sqlfile%... >>                                               %log%

:: Controleer of sql-bestand bestaat
If Not Exist "%sqlfile%" (
    Echo [FOUT] Bestand %sqlfile% niet gevonden, proces afgebroken.
    Echo [FOUT] Bestand %sqlfile% niet gevonden, proces afgebroken. >>          %log%

	Echo. >> %log%
	Echo *** Rename Stored Procedures folder>> %log%
	Echo. >> %log%
	rename "dbo\StoredProcedures", "Stored Procedures"
    Exit /b 1
)

:: Voer inhoud van sql-bestand uit
::sqlcmd.exe %account% -i "%sqlfile%" -o sqlcmd.out
sqlcmd %account% -I -i %sqlfile% -o sqlcmd.out
If %errorlevel% GTR 0 (
    Echo [FOUT] sqlcmd-fout bij uitvoeren van %sqlfile%, proces afgebroken.
    Echo [FOUT] sqlcmd-fout bij uitvoeren van %sqlfile%, proces afgebroken. >>    %log%
    Type sqlcmd.out >>                                                            %log%
    Del sqlcmd.out

	Echo. >> %log%
	Echo *** Rename Stored Procedures folder>> %log%
	Echo. >> %log%

	rename "dbo\StoredProcedures", "Stored Procedures"
    Exit /b 1
)

:: vreemde karakters zorgen ervoor dat findstr niet werkt, door type te gebruiken wordt dit probleem opgelost.
type sqlcmd.out > sqlcmd.txt
type sqlcmd.txt > sqlcmd.out

:: Controleer creatie
FindStr /I "Msg Level State error" sqlcmd.out>NUL:
If %errorlevel% Gtr 0 (
    Echo [OK]
    type sqlcmd.out >>                                                                %log%
    del sqlcmd.out

) Else (
    Echo [FOUT] Databasefout bij uitvoeren van %sqlfile%, proces afgebroken.
    Echo [FOUT] Databasefout bij uitvoeren van %sqlfile%, proces afgebroken. >>     %log%
    type sqlcmd.out | more
    type sqlcmd.out >>                                                                %log%
    del sqlcmd.out

	Echo. >> %log%
	Echo *** Rename Stored Procedures folder>> %log%
	Echo. >> %log%

	rename "dbo\StoredProcedures", "Stored Procedures"
    Exit /b 1
)

Goto :EOF
