@ECHO Off

CD /D %~dp0

SET "curpath=%cd%"

echo.%curpath%|findstr /C:" " >nul 2>&1
if not errorlevel 1 (
	ECHO ***************************************************************************
	ECHO ** Er is een spatie gevonden in een mapnaam!                              **
	ECHO ** Het script wordt afgebroken...                                        **
	ECHO ***************************************************************************
	PAUSE
	EXIT 1
)
CALL Common.cmd :CHECKRUNASADMIN
ECHO ***************************************************************************
ECHO ** Welkom bij de installatie van Monitoring                              **
ECHO **                                                                       **
ECHO ** Enkele installatie settings zijn afhankelijk van de doelomgeving.     **
ECHO ** Geef aan op welke omgeving u de software installeert.                 **
ECHO **   Uw Opties zijn:                                                     **
ECHO **     Acceptatie (installatie op de  acceptatie server)          **
ECHO **     Opleiding  (installatie op de  opleiding server)           **
ECHO **     Productie  (installatie op de  productie server)           **
ECHO **     Test       (installatie op een Ordina test machine)               **
ECHO **     Ontwikkel  (installatie op een Ordina ontwikkel machine)          **
ECHO ** Let op: als uw keuze niet overeen komt met een van bovenstaande       **
ECHO ** keuzes, dan zal het installatie script afbreken.                      **
ECHO ***************************************************************************
SET /p omgeving="Doelomgeving: "
SET settings_suffix=""

IF /I "%omgeving%"=="Test" (
    SET settings_suffix="Test"
) ELSE (
    IF /I "%omgeving%"=="Acceptatie" (
        SET settings_suffix="A"
    ) ELSE (
        IF /I "%omgeving%"=="Productie" (
            SET settings_suffix="P"
        ) ELSE (
            IF /I "%omgeving%"=="Opleiding" (
                SET settings_suffix="O"
            ) ELSE (
				IF /I "%omgeving%"=="Ontwikkel" (
					SET settings_suffix="Ontwikkel"
				) ELSE (
					ECHO ***************************************************************************
					ECHO ** Geen correcte doelomgeving ontvangen. Het script wordt afgebroken...  **
					ECHO ***************************************************************************
					PAUSE
					EXIT 1
				)
            )
        )
    )
)

if exist "settings_%settings_suffix%.cmd" (
    CALL "settings_%settings_suffix%.cmd"
) else (
    Echo ***************************************************************************
    Echo ** Settings file niet gevonden!                                          **
    Echo ***************************************************************************
    pause
    exit
)

CALL NetFrameWorkCheck.cmd %settings_suffix%  || exit 1

if "%CreateBackup%" equ "1" (
	rem Create a backup
	CALL Create_backup.cmd %settings_suffix% || exit 1
)
	
rem Prevent access to the application
if "%SetInMaintenanceMode%" equ "1" (
	CALL "%curpath%\Database\Monitoring\set_maintenance_on.cmd" "%DBServer%" "%DBNaam%" "%DBUser%" %settings_suffix% %~dp0 || exit 1
)

rem Stop services
CALL stop_services.cmd %settings_suffix% || exit 1

if "%Auto_Update_Database%" equ "1" (
	ECHO ***************************************************************************
	ECHO ** De software is gebackupped en alle services zijn gestopt!             **
	ECHO ** We starten nu de update van de database.                              **
	ECHO ***************************************************************************
	
	rem password wordt gevraagd door laadscript_monitoring_database-script
	call "%curpath%\Database\Monitoring\laadscript_monitoring_database.cmd" "%DBServer%" "%DBNaam%" "%DBUser%" %settings_suffix% %~dp0 || exit 1
		
	ECHO ***************************************************************************
	ECHO ** De Database is geupdate.                                              **
	ECHO ** Als u verder wilt gaan met de installatie, type hieronder Install     **
	ECHO ***************************************************************************
) ELSE (
	ECHO ***************************************************************************
	ECHO ** De software is gebackupped en alle services zijn gestopt!             **
	ECHO ** Update nu indien nodig de database.                                   **
	ECHO ** Als u verder wilt gaan met de installatie, type hieronder Install     **
	ECHO ***************************************************************************
)

SET /p temp="Type Install: "
IF /I "%temp%"=="Install" (
    CALL Install %settings_suffix% || exit 1
) ELSE (
    ECHO ***************************************************************************
    ECHO ** Tekst 'Install' niet herkent. Het script wordt afgebroken...          **
	ECHO ** LET OP: software kan nog in onderhoudsmodus staan!                    **
    ECHO ***************************************************************************
    PAUSE
    EXIT
)
ECHO ***************************************************************************
ECHO ** De nieuwe software is geinstalleerd, maar nog niet opgestart!         **
ECHO ** Als er config waardes moeten worden aangepast/toegevoegd, dan is daar **
ECHO ** nu de ruimte voor. Type na uw wijzigingen Start om door te gaan.      **
ECHO ***************************************************************************
:: start the config tool
If %Start_ConfigTool% EQU 1 (
	cd "%curpath%\ConfigEditor\"
	CALL "%curpath%\ConfigEditor\ConfigEditor.exe"
	cd "%curpath%"
)
SET /p temp="Type Start: "
IF /I "%temp%"=="Start" (
    CALL start_services.cmd %settings_suffix% || exit 1
) ELSE (
    ECHO ***************************************************************************
    ECHO ** Tekst 'Start' niet herkent. Het script wordt afgebroken...            **
	ECHO ** LET OP: software kan nog in onderhoudsmodus staan!                    **
    ECHO ***************************************************************************
    PAUSE
    EXIT
)

ECHO ***************************************************************************
ECHO ** De software is gestart!                                               **
ECHO ** Voer nu de smoketesten uit.                                           **
ECHO ** Indien succesvol, type Ok om door te gaan.                            **
ECHO ***************************************************************************
SET /p temp="Type Ok: "
IF /I "%temp%" NEQ "Ok" (
    ECHO ***************************************************************************
    ECHO ** Smoketesten niet succesvol, script wordt afgebroken...                **
	ECHO ** LET OP: software kan nog in onderhoudsmodus staan!                    **
    ECHO ***************************************************************************
    PAUSE
    EXIT
)

::Indien geen clients op de fileshare gezet hoeven te worden
::deze stap dan overslaan
IF %Install_Client_FVA% EQU 0 IF %Install_Client_Registratie% EQU 0 ( 
	goto NoFileShareUpdates
)

ECHO ***************************************************************************
ECHO ** Update nu de clients op de fileshare.                                 **
ECHO ** Indien afgerond, type Ok om door te gaan.                             **
ECHO ***************************************************************************
SET /p temp="Type Ok: "
IF /I "%temp%" NEQ "Ok" (
    ECHO ***************************************************************************
    ECHO ** Clients op fileshare niet geupdate, script wordt afgebroken...        **
	ECHO ** LET OP: software kan nog in onderhoudsmodus staan!                    **
    ECHO ***************************************************************************
    PAUSE
    EXIT
)


:NoFileShareUpdates
rem Grant access to Monitoring again
if "%SetInMaintenanceMode%" equ "1" (
	CALL "%curpath%\Database\Monitoring\set_maintenance_off.cmd" "%DBServer%" "%DBNaam%" "%DBUser%" %settings_suffix% %~dp0 || exit 1
)

ECHO ***************************************************************************
ECHO ** Installatie afgerond.                                                 **
ECHO ***************************************************************************
PAUSE