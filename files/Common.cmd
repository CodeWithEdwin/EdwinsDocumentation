@echo OFF
setlocal EnableDelayedExpansion
call %*
Goto :EOF
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
:::::::::::::::::::::::::::::::::::::::::::::::::rem minimal version of the .Net framework version 4
rem https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
rem 528040 = version 4.8
:CheckNetFrameWorkVersion
SET "NET_FRAMEWORK_VERSION=%1"
Echo ...Check .NET Framework Version ...
Echo ...Check .NET Framework Version ... >>%log% 2>>&1

if "%NET_FRAMEWORK_VERSION%" equ "" (
	Echo .Net Framework Version not found
	Echo .Net Framework Version not found >>%log% 2>>&1
	Pause
	EXIT 1
	Goto :EOF
)

rem check if the minimal version of the .net Framework version 4 is supported
rem if you would check another version then version 4 you need to replace the v4 of the HKLM key
powershell -command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release -ge %NET_FRAMEWORK_VERSION%" > %curpath%\netFrameWorkVersion.txt
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
set /p VersionOk= < %curpath%\netFrameWorkVersion.txt
del %curpath%\netFrameWorkVersion.txt 

if "%VersionOk%" NEQ "True" (
	Echo Vereiste .Net Framework versie niet geinstalleerd!
	Echo Vereiste .Net Framework versie niet geinstalleerd! >>%log% 2>>&1
	Pause
	EXIT 1
	Goto :EOF
)
Echo .Net Framework Version %NET_FRAMEWORK_VERSION% OK >>%log% 2>>&1
ECHO 		[DONE] 
ECHO 		[DONE] >>%log% 2>>&1

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::
:CHECKRUNASADMIN
net session > NUL
IF %ERRORLEVEL% NEQ 0 (
    ECHO This script is NOT running as Administrator. Exiting...
    PING 127.0.0.1 > NUL 2>&1
    EXIT 1
	Goto :EOF
) 
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:BackupScheduleTasks
:: Backup Schedule Tasks
Set scheduledTaskFolder=%~1
Set backupLocation=%~2

Echo ...Backup Schedule Tasks ...
Echo ...Backup Schedule Tasks ... >>%log% 2>>&1	

if not exist "%backupLocation%" mkdir "%backupLocation%" >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

if exist "%curpath%\tempTasksList.txt" del "%curpath%\tempTasksList.txt" >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

schtasks /query /TN \%scheduledTaskFolder%\ /fo csv | findstr /V /c:"TaskName" > %curpath%\tempTasksList.txt

for /F "delims=," %%T in (%curpath%\tempTasksList.txt) do (
	set tn=%%T
	set fn=!tn:\=#!
	schtasks /query /xml /TN !tn! > %backupLocation%\!fn!.xml
)
  
if exist "%curpath%\tempTasksList.txt" del "%curpath%\tempTasksList.txt" >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 
		
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:ImportScheduleTask
:: Import schedule task
set filename=%1
Set Importpad=%2\

rem replace out the # symbol and .xml to derived the task name
set taskname=%filename:#=\%
rem replace full path
call set taskname=%%taskname:%Importpad%=%%
rem remove Xml extension
set taskname=%taskname:.xml=%

Echo ...Import Schedule Tasks ...
Echo ...Import Schedule Tasks ... >>%log% 2>>&1	

echo schtasks /create /tn %taskname% /xml %filename% >>%log% 2>>&1
schtasks /create /tn %taskname% /xml %filename% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER  

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 
  
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:RestoreScheduleTasks
:: Restore schedule task
Set Importpad=%1

Echo ...Restore Schedule Tasks ...
Echo ...Restore Schedule Tasks ... >>%log% 2>>&1	

If not exist "%Importpad%" (
	ECHO Importpad pad bestaat niet >>%log% 2>>&1
	ECHO Importpad pad bestaat niet
	pause
	Goto :EOF
)

for %%f in ("%Importpad%\*.xml") do (
	call :ImportScheduleTask "%%f" %Importpad%
)

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 
		
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:BackupIIS
:: Backup IIS settings
:: backupLocation; folder path path where the apppools.xmlm sites.xml and the backup of the Https Certificate will be saved
:: httpsPorts; comma seperated values of portnumbers form where Https Certificates are used; using ~ will dequote the variable; using ~ will dequote the variable
Set "backupLocation=%~1"
Set "httpsPorts=%~2"

set "curpathStartWebsite=%cd%"
cd /D %windir%\system32\inetsrv

Echo ...Backup IIS ...
Echo ...Backup IIS ... >>%log% 2>>&1	

if not exist "%backupLocation%" mkdir "%backupLocation%" >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

rem if there are no https ports, then no certificate backup is created
if "%httpsPorts%" NEQ "" (
	for %%a in ("%httpsPorts:,=" "%") do (
	   :: backup used certificaat
		ECHO %windir%\system32\netsh http show sslcert ipport=0.0.0.0:%%~a >>%log% 2>>&1
		ECHO location: "%backupLocation%\HTTPSCertificaat_%%~a.txt" >>%log% 2>>&1
		ECHO Backup HTTPS Certificaat voor Poort %%~a >> "%backupLocation%\HTTPSCertificaat_%%~a.txt"
		%windir%\system32\netsh http show sslcert ipport=0.0.0.0:%%~a >> "%backupLocation%\HTTPSCertificaat_%%~a.txt"
		IF !ERRORLEVEL! NEQ 0 (
		  rem Delete file if error's mostly there is no certificate in use
		  rem The Restore of IIS check if this file is available
		  rem If not there is no restore for the certificate
		  del "%backupLocation%\HTTPSCertificaat_%%~a.txt" >>%log% 2>>&1
		  Echo Certificaat voor %%~a is niet aanwezig. >>%log% 2>>&1
		)
	)	
)

ECHO %windir%\system32\inetsrv\appcmd list apppool /config /xml >>%log% 2>>&1
Echo location: "%backupLocation%\apppools.xml" >>%log% 2>>&1
%windir%\system32\inetsrv\appcmd list apppool /config /xml > "%backupLocation%\apppools.xml"
rem %ERRORLEVEL% = 1: no apppools in IIS defined
if %ERRORLEVEL% NEQ 0 if %ERRORLEVEL% NEQ 1 (
 GOTO ERROR_HANDLER
)

  
Echo %windir%\system32\inetsrv\appcmd list site /config /xml >>%log% 2>>&1
Echo location: "%backupLocation%\sites.xml" >>%log% 2>>&1
%windir%\system32\inetsrv\appcmd list site /config /xml > "%backupLocation%\sites.xml"
rem %ERRORLEVEL% = 1: no sites in IIS defined
if %ERRORLEVEL% NEQ 0 if %ERRORLEVEL% NEQ 1 (
 GOTO ERROR_HANDLER
)

  
ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 
		
cd /D %curpathStartWebsite%
Goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::
:RestoreIIS
:: Restore IIS settings
:: importpad; folder path path where the apppools.xml and sites.xml are located; using ~ will dequote the variable
:: httpsPorts; comma seperated values of portnumbers form where Https Certificates are used; using ~ will dequote the variable
Set "Importpad=%~1"
Set "httpsPorts=%~2"

set "curpathStartWebsite=%cd%"
cd /D %windir%\system32\inetsrv

Echo ...Restore IIS ...
Echo ...Restore IIS ... >>%log% 2>>&1	

If not exist "%Importpad%" (
	ECHO Importpad pad bestaat niet >>%log% 2>>&1
	ECHO Importpad pad bestaat niet
	pause
	Goto :EOF
)
If not exist "%Importpad%\apppools.xml" (
	ECHO apppools.xml bestaat niet >>%log% 2>>&1
	ECHO apppools.xml bestaat niet
	pause
	Goto :EOF
)
If not exist "%Importpad%\sites.xml" (
	ECHO sites.xml bestaat niet >>%log% 2>>&1
	ECHO sites.xml bestaat niet
	pause
	Goto :EOF
)
echo %windir%\system32\inetsrv\appcmd add apppool /in < "%Importpad%\apppools.xml" >>%log% 2>>&1
%windir%\system32\inetsrv\appcmd add apppool /in < "%Importpad%\apppools.xml" >>%log% 2>>&1
rem %ERRORLEVEL% = 1: no apppools in IIS defined
if %ERRORLEVEL% NEQ 0 if %ERRORLEVEL% NEQ 1 (
 GOTO ERROR_HANDLER
)

Echo %windir%\system32\inetsrv\appcmd add site /in < "%Importpad%\sites.xml" >>%log% 2>>&1
%windir%\system32\inetsrv\appcmd add site /in < "%Importpad%\sites.xml" >>%log% 2>>&1
rem %ERRORLEVEL% = 1: no sites in IIS defined
if %ERRORLEVEL% NEQ 0 if %ERRORLEVEL% NEQ 1 (
 GOTO ERROR_HANDLER
)

rem if there are no https ports, then no certificate is needed to restore
if "%httpsPorts%" NEQ "" (
	for %%a in ("%httpsPorts:,=" "%") do (
		rem check if the certificate is in the backup
		rem only then restore it
		IF exist "%Importpad%\HTTPSCertificaat_%%~a.txt" (
			CALL :RestoreHttpsCertificate %%~a
	    )
	)	
)

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 

cd /D %curpathStartWebsite%
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:RestoreHttpsCertificate
::Restore Https Certificate
:: httpsPort; portnumbers form where Https Certificates are used
SET "HttpsPort=%1"

::Ask for the Certificate hash and the Application ID of the certificate to restore it
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
ECHO Restore HTTPS Certificaat voor Poort %HttpsPort%
ECHO Voer het Certificate Hash van het certificaat in
SET /p certhash="Certificate Hash: "
ECHO Voer het Application ID van het certificaat in zonder de { }
SET /p appid="Application ID: "
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 

ECHO netsh http delete sslcert ipport=0.0.0.0:%HttpsPort% >>%log% 2>>&1
netsh http delete sslcert ipport=0.0.0.0:%HttpsPort% >>%log% 2>>&1

echo netsh http add sslcert ipport=0.0.0.0:%HttpsPort% certhash=%certhash% appid={%appid%} >>%log% 2>>&1
netsh http add sslcert ipport=0.0.0.0:%HttpsPort% certhash=%certhash% appid={%appid%} >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:RemoveWebsiteAndAppPoolANDWebsiteDirectoryIfExists
:: Delete Website en applicationpool and the Diretory from the website
Set WebsiteNaam=%1
Set PoolNaam=%2
Set Directory=%3
set "curpathStartWebsite=%cd%"
cd /D %windir%\system32\inetsrv

Echo ...REMOVING Website %WebsiteNaam%...
Echo ...REMOVING Website %WebsiteNaam%... >>%log% 2>>&1	

:: First check if website exists at all
CALL %windir%\system32\inetsrv\appcmd list site /name:%WebsiteNaam% >>%log% 2>>&1
IF "!ERRORLEVEL!" EQU "0" (
	%windir%\system32\inetsrv\appcmd delete site %WebsiteNaam% >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
	
	%windir%\system32\inetsrv\appcmd delete apppool %PoolNaam%
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
	
	RD /S /Q %Directory% >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
	
	ECHO 		[DONE]  >>%log% 2>>&1
	ECHO 		[DONE] 
) else (
			ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
			ECHO 		[DOES NOT EXIST] 
)

cd /D %curpathStartWebsite%
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:StopWebsiteIfExists
:: Creeer Website en applicationpool in IIS
Set WebsiteNaam=%1
Set PoolNaam=%2
set "curpathStartWebsite=%cd%"
cd /D %windir%\system32\inetsrv

Echo ...STOPPING Website %WebsiteNaam%...
Echo ...STOPPING Website %WebsiteNaam%... >>%log% 2>>&1	

:: First check if website exists at all
CALL %windir%\system32\inetsrv\appcmd list site /name:%WebsiteNaam%
IF "!ERRORLEVEL!" EQU "0" (
	::geen resultaat, dan moeten we hem stoppen
	%windir%\system32\inetsrv\appcmd list site /state:Stopped /name:%WebsiteNaam% >>%log% 2>>&1
	IF "!ERRORLEVEL!" EQU "1" (
		echo. >>%log% 2>>&1
		echo.  
		echo %windir%\system32\inetsrv\appcmd stop site /site.name:%WebsiteNaam% >>%log% 2>>&1
		%windir%\system32\inetsrv\appcmd stop site /site.name:%WebsiteNaam% >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
		
		ECHO 		[DONE]  >>%log% 2>>&1
		ECHO 		[DONE] 
	)
	::Geen resultaat, dan moeten we hem stoppen
	%windir%\system32\inetsrv\appcmd list apppool /state:Stopped | find %PoolNaam% >>%log% 2>>&1
	IF "!ERRORLEVEL!" EQU "1" (
		Echo ...STOPPING Pool %PoolNaam%...
		Echo...STOPPING Pool %PoolNaam%... >>%log% 2>>&1

		echo %windir%\system32\inetsrv\appcmd stop apppool /apppool.name:"%PoolNaam%" >>%log% 2>>&1
		%windir%\system32\inetsrv\appcmd stop apppool /apppool.name:"%PoolNaam%" >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
		
			ECHO 		[DONE]  >>%log% 2>>&1
			ECHO 		[DONE] 
	)
) else (
			ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
			ECHO 		[DOES NOT EXIST] 
)

cd /D %curpathStartWebsite%
Goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::
:DeleteApp
:: Probeer een app te deleten uit IIS
Set WebsiteSlashAppNaam=%1
set "curpathDeleteApp=%cd%"
cd /D %windir%\system32\inetsrv

Echo ...DELETING App %AppNaam% from %WebsiteNaam%...
Echo ...DELETING App %AppNaam% from %WebsiteNaam%... >>%log% 2>>&1	

:: Delete app
%windir%\system32\inetsrv\appcmd delete app %WebsiteSlashAppNaam% >>%log% 2>>&1
IF "!ERRORLEVEL!" EQU "1" (
	echo. App already deleted... >>%log% 2>>&1
	echo.
)

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 


cd /D %curpathDeleteApp%
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:CopyConfigToAppLocationFolder
:: Vanuit de submap \Configs\ in de installatie naar het te installeren onderdeel
:: Copy alleen indien aanwezig
Set ServiceName=%1
set SetupFolder=%2
set App_LocationFolder=%3
set ConfigFileName=%4

Echo ...Configuration Activation %ServiceName%...
Echo ...Configuration Activation %ServiceName%... >>%log% 2>>&1	

Echo if exist "%APP_Location%\%App_LocationFolder%\Configs" rmdir "%APP_Location%\%App_LocationFolder%\Configs" /s /q >>%log% 2>>&1
if exist "%APP_Location%\%App_LocationFolder%\Configs" rmdir "%APP_Location%\%App_LocationFolder%\Configs" /s /q >>%log% 2>>&1

if exist "%curpath%\%SetupFolder%\Configs\%SettingsOmgeving%_%ConfigFileName%" (
		ECHO 	Use config %SettingsOmgeving%:  >>%log% 2>>&1
		ECHO 	Use config %SettingsOmgeving%:

		echo copy "%curpath%\%SetupFolder%\Configs\%SettingsOmgeving%_%ConfigFileName%" "%APP_Location%\%App_LocationFolder%\%ConfigFileName%" /Y >>%log% 2>>&1
        copy "%curpath%\%SetupFolder%\Configs\%SettingsOmgeving%_%ConfigFileName%" "%APP_Location%\%App_LocationFolder%\%ConfigFileName%" /Y >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER

		ECHO 		[DONE]  >>%log% 2>>&1
		ECHO 		[DONE] 
) else (
		IF exist "%curpath%\%SetupFolder%\%ConfigFileName%" (
			ECHO 	Use active config:  >>%log% 2>>&1
			ECHO 	Use active config:

			ECHO copy "%curpath%\%SetupFolder%\%ConfigFileName%" "%APP_Location%\%App_LocationFolder%" /Y >>%log% 2>>&1
			copy "%curpath%\%SetupFolder%\%ConfigFileName%" "%APP_Location%\%App_LocationFolder%" /Y >>%log% 2>>&1
			IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
				
			ECHO 		[DONE]  >>%log% 2>>&1
			ECHO 		[DONE] 
		) else (
			ECHO 		[FAILED]  >>%log% 2>>&1
			ECHO 		[FAILED] 
		)
)
Goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::
:CopyConfigToSetupFolder
:: Vanuit de submap \Configs\ in de installatie naar het te installeren onderdeel
:: Copy alleen indien aanwezig
Set ServiceName=%1
set SetupFolder=%2
set App_LocationFolder=%3
set ConfigFileName=%~4 
rem using ~ will dequote the variable

Echo ...Configuration Setup %ServiceName%...
Echo ...Configuration Setup %ServiceName%... >>%log% 2>>&1	

if exist "%curpath%\%SetupFolder%\Configs\%SettingsOmgeving%_%ConfigFileName%" (
		ECHO 	Use config %SettingsOmgeving%:  >>%log% 2>>&1
		ECHO 	Use config %SettingsOmgeving%:

		echo copy "%curpath%\%SetupFolder%\Configs\%SettingsOmgeving%_%ConfigFileName%" "%curpath%\%SetupFolder%\%ConfigFileName%" /Y >>%log% 2>>&1
        copy "%curpath%\%SetupFolder%\Configs\%SettingsOmgeving%_%ConfigFileName%" "%curpath%\%SetupFolder%\%ConfigFileName%" /Y >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER

		ECHO 		[DONE]  >>%log% 2>>&1
		ECHO 		[DONE] 
) else (
	IF	exist "%APP_Location%\%App_LocationFolder%\%ConfigFileName%" (
		ECHO 	Use active config:  >>%log% 2>>&1
		ECHO 	Use active config:

		ECHO copy "%APP_Location%\%App_LocationFolder%\%ConfigFileName%" "%curpath%\%SetupFolder%\" /Y >>%log% 2>>&1
		copy "%APP_Location%\%App_LocationFolder%\%ConfigFileName%" "%curpath%\%SetupFolder%\" /Y >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
			
		ECHO 		[DONE]  >>%log% 2>>&1
		ECHO 		[DONE] 
	) else (
			ECHO 	No config installed  >>%log% 2>>&1
			ECHO 	No config installed
			ECHO 		[OK]  >>%log% 2>>&1
			ECHO 		[OK] 
	)
)
Goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::
:CopyFiles
:: Copy Files 
SET service=%1
Set FROM=%2
Set TO=%3

if exist %TO% rmdir %TO% /s /q >>%log% 2>>&1
echo mkdir %TO% >>%log% 2>>&1
mkdir %TO% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

if exist %FROM% (
	echo xcopy.exe %FROM% %TO% /f /s /e /Y >>%log% 2>>&1
	xcopy.exe %FROM% %TO% /f /s /e /Y >>%log% 2>>&1
	IF %ERRORLEVEL% NEQ 0 ( GOTO ERROR_HANDLER )
) else (
	echo %FROM% NOT EXISTS >>%log% 2>>&1
	echo %FROM% NOT EXISTS
)

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:CopyFilesForService
:: Copy Files 
SET service=%1
Set FROM=%2
Set TO=%3

CALL common.cmd :CopyFiles %service% %FROM% %TO%
Echo if exist %TO%\Configs rmdir %TO%\Configs /s /q >>%log% 2>>&1
if exist %TO%\Configs rmdir %TO%\Configs /s /q >>%log% 2>>&1

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:CopyFilesIIS
:: Copy Files 
SET service=%1
Set FROM="%2"
Set TO="%3"
set "curpathCopy=%cd%"
cd /D %windir%\system32\

echo.  
Echo ...Install %service%...
Echo ...Install %service%... >>%log% 2>>&1

if not exist "%TO%" (
	echo mkdir "%TO%" >>%log% 2>>&1
	mkdir "%TO%"
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
) else (
	for %%i in ("%TO%") do (
		if not "%%i"=="aspnet_client" (
			echo Del /f /q "%%i" >>%log% 2>>&1
			del /f /q "%%i" >>%log% 2>>&1
			IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
		)
	)
	FOR /D %%i IN ("%TO%\*.*") do (
		if not "%%i"=="%TO%\aspnet_client" (
			echo rmdir "%%i" >>%log% 2>>&1
			rmdir "%%i" /s /q >>%log% 2>>&1
			IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
		)
	)
)

  echo xcopy.exe "%FROM%" "%TO%" /f /s /e /Y >>%log% 2>>&1
  xcopy.exe "%FROM%" "%TO%" /f /s /e /Y >>%log% 2>>&1
  IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

cd /D %curpathCopy%
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:StartWebsiteIfExists
:: Start Website en applicationpool in IIS
Set PoolNaam=%1
Set WebsiteNaam=%2
set "curpathStartWebsite=%cd%"
cd /D %windir%\system32\inetsrv

echo. >>%log% 2>>&1
echo.  
Echo ...STARTING Website %WebsiteNaam%...
Echo ...STARTING Website %WebsiteNaam%... >>%log% 2>>&1

:: First check if website exists at all
CALL %windir%\system32\inetsrv\appcmd list site /name:%WebsiteNaam%
IF "!ERRORLEVEL!" EQU "0" (
	echo %windir%\system32\inetsrv\appcmd start apppool /apppool.name:%PoolNaam% >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd start apppool /apppool.name:%PoolNaam% >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER

	echo %windir%\system32\inetsrv\appcmd start site /site.name:%WebsiteNaam% >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd start site /site.name:%WebsiteNaam% >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
		ECHO 		[DONE]  >>%log% 2>>&1
		ECHO 		[DONE] 	
) else (
		ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
		ECHO 		[DOES NOT EXIST] 
)

cd /D %curpathStartWebsite%
Goto :EOF

:reset
exit /b 0

:::::::::::::::::::::::::::::::::::::::::::::::::
:CreateWebsite
:: Creeer Website en applicationpool in IIS
Set WebsiteNaam=%1
Set PoolNaam=%2
Set Port=%3
Set PoolisNetwork=%4
Set WindowsAuth=%5

set "curpathwebsite=%cd%"

echo.  
Echo ...Create Website %WebsiteNaam%...
Echo ...Create Website %WebsiteNaam%... >>%log% 2>>&1
cd /D %windir%\system32\inetsrv


set PoolExists=0
ECHO 	ApplicationPool: >>%log% 2>>&1
ECHO 	ApplicationPool:
%windir%\system32\inetsrv\appcmd list apppool /name:"%PoolNaam%"  >>%log% 2>>&1
IF %ERRORLEVEL% EQU 0 (
    ECHO 		[EXISTS] >>%log% 2>>&1
	ECHO 		[EXISTS]
) else (
	echo %windir%\system32\inetsrv\appcmd add apppool /name:"%PoolNaam%" /managedRuntimeVersion:v4.0  >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:"%PoolNaam%" /managedRuntimeVersion:v4.0  >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER

	IF "%PoolisNetwork%" EQU "1" (
		echo %windir%\system32\inetsrv\appcmd set config /section:applicationPools /[name='%PoolNaam%'].processModel.identityType:NetworkService >>%log% 2>>&1
		%windir%\system32\inetsrv\appcmd set config /section:applicationPools /[name='%PoolNaam%'].processModel.identityType:NetworkService >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
		
		ECHO 		NETWORK [CREATED] >>%log% 2>>&1
		ECHO 		NETWORK [CREATED]
	) ELSE (
		ECHO  		[CREATED] >>%log% 2>>&1
		ECHO  		[CREATED] 
	)
)

%windir%\system32\inetsrv\appcmd list site /name:"%WebsiteNaam%" >>%log% 2>>&1
IF "%ERRORLEVEL%" EQU "0" (
	call :StopWebsiteIfExists "%WebsiteNaam%" "%PoolNaam%"   
) ELSE (
	ECHO 	Website:  >>%log% 2>>&1
	ECHO 	Website:

	if not exist %APP_Location%\%WebsiteNaam% (
		mkdir %APP_Location%\%WebsiteNaam%
	)
	echo  %windir%\system32\inetsrv\appcmd add site /name:"%WebsiteNaam%" /physicalPath:"%APP_Location%\%WebsiteNaam%"  /bindings:"http/*:%Port%:" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"%WebsiteNaam%" /physicalPath:"%APP_Location%\%WebsiteNaam%"  /bindings:"http/*:%Port%:" >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
	
	echo %windir%\system32\inetsrv\appcmd set app "%WebsiteNaam%/" /applicationPool:"%PoolNaam%" >>%log% 2>>&1
    %windir%\system32\inetsrv\appcmd set app "%WebsiteNaam%/" /applicationPool:"%PoolNaam%" >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
	
	if "%WindowsAuth%" EQU "1" (
		echo %windir%\system32\inetsrv\appcmd set config "%WebsiteNaam%" /section:windowsAuthentication /enabled:true /commit:apphost >>%log% 2>>&1
		%windir%\system32\inetsrv\appcmd set config "%WebsiteNaam%" /section:windowsAuthentication /enabled:true /commit:apphost >>%log% 2>>&1
		IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER
	)
	
	ECHO 		[CREATED] >>%log% 2>>&1
	ECHO 		[CREATED]
   
)
echo.  
cd /D %curpathwebsite%
Goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::
:StopWindowsServiceIfExists
Set ServiceNaam=%1

echo ...Stopping Windows service %ServiceNaam%...>>%log% 2>>&1
echo ...Stopping Windows service %ServiceNaam%...

SC QUERY %ServiceNaam% > NUL
IF ERRORLEVEL 1060 (
	Echo			[DOES NOT EXIST] >>%log% 2>>&1
	Echo			[DOES NOT EXIST] 
) else (
	echo 	Stopping:
	Echo 	Stopping: >>%log% 2>>&1
	Net stop %ServiceNaam% >>%log% 2>>&1
	IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
	
	:CheckifServiceStopped
	sc query %ServiceNaam% | FIND "STATE" | FIND "STOPPED" >nul
	if ERRORLEVEL 1 (
		Echo			Waiting for stopping...  >>%log% 2>>&1
		Echo			Waiting for stopping... 
		TIMEOUT /T 10
		goto :CheckifServiceStopped
	) else (
		Echo			[DONE] >>%log% 2>>&1	
		Echo			[DONE] 
	)
)
GOTO :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:StartWindowsServiceIfExists
Set ServiceNaam=%1

echo ...Starting Windows service %ServiceNaam%...>>%log% 2>>&1
echo ...Starting Windows service %ServiceNaam%...

SC QUERY %ServiceNaam% > NUL
IF ERRORLEVEL 1060 (
	Echo			[DOES NOT EXIST] >>%log% 2>>&1
	Echo			[DOES NOT EXIST] 
) else (
	echo 	Starting:
	Echo 	Starting: >>%log% 2>>&1
	Net start %ServiceNaam% >>%log% 2>>&1
	IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
	Echo			[DONE] >>%log% 2>>&1
	Echo			[DONE] 
)
GOTO :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:UninstallWindowsServiceIfExists
Set ServiceNaam=%1
Set ExeWithPath=%2
Set ShortServiceNaam=%3

echo ...Uninstalling Windows service %ShortServiceNaam%...>>%log% 2>>&1
echo ...Uninstalling Windows service %ShortServiceNaam%...

SC QUERY %ServiceNaam% > NUL
IF ERRORLEVEL 1060 (
	Echo			[DOES NOT EXIST] >>%log% 2>>&1
	Echo			[DOES NOT EXIST] 
) else (
	echo 	Uninstalling:
	Echo 	Uninstalling: >>%log% 2>>&1
	echo %WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /u /logFile="%APP_Location%\_Logging\%ShortServiceNaam%_uninstall.log" %ExeWithPath% >>%log% 2>>&1
	%WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /u /logFile="%APP_Location%\_Logging\%ShortServiceNaam%_uninstall.log" %ExeWithPath% >>%log% 2>>&1	
	IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
	
	:CheckifServiceUninstalled	
	SC QUERY %ServiceNaam% > NUL
	IF ERRORLEVEL 1060 (
		Echo			[DONE] >>%log% 2>>&1	
		Echo			[DONE] 		
	) else (
		Echo			Waiting for uninstalling...  >>%log% 2>>&1
		Echo			Waiting for uninstalling... 
		TIMEOUT /T 10
		goto :CheckifServiceUninstalled
	)
)
GOTO :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:DisableWindowsServiceIfExists
Set ServiceNaam=%1

echo ...Disabling Windows service %ServiceNaam%...>>%log% 2>>&1
echo ...Disabling Windows service %ServiceNaam%...

SC QUERY %ServiceNaam% > NUL
IF ERRORLEVEL 1060 (
	Echo			[DOES NOT EXIST] >>%log% 2>>&1
	Echo			[DOES NOT EXIST] 
) else (
	echo 	Disabling:
	Echo 	Disabling: >>%log% 2>>&1
	echo sc config %ServiceNaam% start= disabled
	sc config %ServiceNaam% start= disabled >>%log% 2>>&1
	IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
	Echo			[DONE] >>%log% 2>>&1
	Echo			[DONE] 
)
GOTO :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:InstallWindowsService
Set ShortServiceNaam=%1
Set ExeWithPath=%2

echo ...Installing Windows service %ShortServiceNaam%...>>%log% 2>>&1
echo ...Installing Windows service %ShortServiceNaam%...

echo 	Installing:
Echo 	Installing: >>%log% 2>>&1
echo %WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /logFile="%APP_Location%\_Logging\%ShortServiceNaam%_install.log" %ExeWithPath% >>%log% 2>>&1
%WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /logFile="%APP_Location%\_Logging\%ShortServiceNaam%_install.log" %ExeWithPath% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
Echo			[DONE] >>%log% 2>>&1
Echo			[DONE] 

GOTO :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
::Installer class in windows Service moet aangepast zijn en overerven van de LOA_Common.InstallerWithUsernamePassword om deze functie te kunnen gebruiken
:InstallWindowsServiceWithUsernamePassword
Set ShortServiceNaam=%1
Set ExeWithPath=%2
Set Username=%~3
Set Password=%~4

echo ...Installing Windows service %ShortServiceNaam%...>>%log% 2>>&1
echo ...Installing Windows service %ShortServiceNaam%...

echo    Account: %Username% >>%log% 2>>&1
echo    Account: %Username%

echo 	Installing:
Echo 	Installing: >>%log% 2>>&1
echo %WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /user="%Username%" /password="[not logged]" /logFile="%APP_Location%\_Logging\%ShortServiceNaam%_install.log" %ExeWithPath% >>%log% 2>>&1
%WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /user="%Username%" /password="%Password%" /logFile="%APP_Location%\_Logging\%ShortServiceNaam%_install.log" %ExeWithPath% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
Echo			[DONE] >>%log% 2>>&1
Echo			[DONE] 

GOTO :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:CopySingleFile
:: Copy File 
Set FROM=%1
Set TO=%2
set "curpathCopy=%cd%"
cd /D %windir%\system32\

echo xcopy.exe %FROM% %TO% /f /Y >>%log% 2>>&1
xcopy.exe %FROM% %TO% /f /Y >>%log% 2>>&1
IF %3.==. (
	IF %ERRORLEVEL% NEQ 0 ( GOTO ERROR_HANDLER )
	)
	
cd /D %curpathCopy%
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:InstallIISWebsiteFromPackage
Set PackageWithPath=%1
Set WebsiteNaamWithApplicationPath=%2

echo ...Installing %WebsiteNaamWithApplicationPath%...>>%log% 2>>&1
echo ...Installing %WebsiteNaamWithApplicationPath%...

set "curpathCopy=%cd%"
if exist "%programfiles%\IIS\Microsoft Web Deploy V3\msdeploy.exe" (
	cd /D "%programfiles%\IIS\Microsoft Web Deploy V3"
) else (
	if exist "%programfiles%\IIS\Microsoft Web Deploy V2\msdeploy.exe" (
		cd /D "%programfiles%\IIS\Microsoft Web Deploy V2"
	) else (
		if exist "%programfiles%\IIS\Microsoft Web Deploy\msdeploy.exe" (
			cd /D "%programfiles%\IIS\Microsoft Web Deploy"
		) else (
			echo "Web Deploy is not found on the system."
			GOTO ERROR_HANDLER
		)
	)
)

msdeploy -verb:sync -source:package=%PackageWithPath% -dest:auto -setParam:"IIS Web Application Name"=%WebsiteNaamWithApplicationPath%

IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
Echo			[DONE] >>%log% 2>>&1
Echo			[DONE] 

cd /D %curpathCopy%
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:UninstallScheduleTaskIfExists
:: Uninstall a schedule Task
SET Naam=%1
SET fullpathName=%2

echo ...Uninstalling %Naam%...>>%log% 2>>&1
echo ...Uninstalling %Naam%...


schtasks /query /TN "%fullpathName%" >>NUL 2>>&1
if %errorlevel% NEQ 0 (
	ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
	ECHO 		[DOES NOT EXIST]	 
) else (
	echo schtasks /Delete /TN "%fullpathName%" /F >>%log% 2>>&1
	schtasks /Delete /TN "%fullpathName%" /F >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 call common.cmd :ERROR_HANDLER
	
	ECHO 		[DONE]  >>%log% 2>>&1
	ECHO 		[DONE]
)	
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:InstallScheduleTaskFromXml
:: Import schedule task
set Taskname=%1
Set File=%2
set Command=%3

echo ...Installing %Taskname%...>>%log% 2>>&1
echo ...Installing %Taskname%...

echo schtasks /create /tn %Taskname% /xml %File% >>%log% 2>>&1
schtasks /create /tn %Taskname% /xml %File% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER  

::change the command because it can be runned on other locations then specified in the xml
echo schtasks /change /tn %Taskname% /tr %Command% >>%log% 2>>&1
schtasks /change /tn %Taskname% /tr %Command% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER  

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 
  
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:InstallScheduleTask
:: Install a schedule Task
SET Naam=%1
SET fullpathName=%2
SET Command=%3
SET ScheduleTime=%4

echo ...Installing %Naam%...>>%log% 2>>&1
echo ...Installing %Naam%...

IF %ScheduleTime% NEQ 0 (
    SET "SCHEDULING_OPTIONS=/SC DAILY /ST %ScheduleTime%"
) ELSE (
	SET "SCHEDULING_OPTIONS=/SC ONCE /SD 01/01/1901 /ST 00:00"
)

echo schtasks /create /RU "SYSTEM" /NP /tn %fullpathName% /tr %Command% %SCHEDULING_OPTIONS% >>%log% 2>>&1
schtasks /create /RU "SYSTEM" /NP /tn %fullpathName% /tr %Command% %SCHEDULING_OPTIONS% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 

Goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::
:InstallScheduleTaskWithUsernamePassword
:: Install a schedule Task
SET Naam=%1
SET fullpathName=%2
SET Command=%3
SET ScheduleTime=%4
Set Username=%~5
Set Password=%~6

echo ...Installing %Naam%...>>%log% 2>>&1
echo ...Installing %Naam%...

echo    Account: %Username% >>%log% 2>>&1
echo    Account: %Username%

IF %ScheduleTime% NEQ 0 (
    SET "SCHEDULING_OPTIONS=/SC DAILY /ST %ScheduleTime%"
) ELSE (
	SET "SCHEDULING_OPTIONS=/SC ONCE /SD 01/01/1901 /ST 00:00"
)

echo schtasks /create /RU "%Username%" /RP "[not logged]" /tn %fullpathName% /tr %Command% %SCHEDULING_OPTIONS% >>%log% 2>>&1
schtasks /create /RU "%Username%" /RP "%Password%" /tn %fullpathName% /tr %Command% %SCHEDULING_OPTIONS% >>%log% 2>>&1
IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER

ECHO 		[DONE]  >>%log% 2>>&1
ECHO 		[DONE] 

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:DisableScheduleTaskIfExists
:: Install a schedule Task
SET Naam=%1

echo ...Disable %Naam%...>>%log% 2>>&1
echo ...Disable %Naam%...

schtasks /query /TN "%Naam%" >>NUL 2>>&1
if %errorlevel% NEQ 0 (
	ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
	ECHO 		[DOES NOT EXIST]
) else (
	echo schtasks /CHANGE /tn "%Naam%" /DISABLE >>%log% 2>>&1 
	schtasks /CHANGE /tn "%Naam%" /DISABLE >>%log% 2>>&1 
	IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
	
	ECHO 		[DONE]  >>%log% 2>>&1
	ECHO 		[DONE] 	
)	

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:EnableScheduleTaskIfExists
:: Install a schedule Task
SET Naam=%1

echo ...Enable %Naam%...>>%log% 2>>&1
echo ...Enable %Naam%...

schtasks /query /TN "%Naam%" >>NUL 2>>&1
if %errorlevel% NEQ 0 (
	ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
	ECHO 		[DOES NOT EXIST]
	 
) else (
	echo schtasks /CHANGE /tn "%Naam%" /ENABLE >>%log% 2>>&1 
	schtasks /CHANGE /tn "%Naam%" /ENABLE >>%log% 2>>&1
	IF %ERRORLEVEL% NEQ 0 GOTO ERROR_HANDLER
	ECHO 		[DONE]  >>%log% 2>>&1
	ECHO 		[DONE]
)		
Goto :EOF