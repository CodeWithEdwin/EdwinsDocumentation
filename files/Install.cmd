@echo off
setlocal EnableDelayedExpansion
CD /D %~dp0

set "curpath=%cd%"
IF %1.==. (
    Echo ***************************************************************************
    Echo ** Gebruik Install_Main.cmd om de software te installeren                **
    Echo ***************************************************************************
    pause
    exit 1 
)

SET suffix=%~1
if exist "settings_%suffix%.cmd" (
    CALL "settings_%suffix%.cmd"
) else (
    Echo ***************************************************************************
    Echo ** Settings file niet gevonden!                                          **
    Echo ***************************************************************************
    pause
    exit 1
)
CALL Common.cmd :CHECKRUNASADMIN

if "%APP_Location%" equ "" (
Echo General_install.cmd kan niet rechtstreeks uitgevoerd worden
pause
exit 1
)

:: Bepalen datetime onafh van locale
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%
:: yyyyMMddHHmmss
::                                    yyyy      MM        dd        HH         mm         ss
set log="%curpath%\Install_LogFile_%ldt:~0,4%%ldt:~5,2%%ldt:~8,2%%ldt:~11,2%%ldt:~14,2%%ldt:~17,2%.log"

:: Install IIS websites
echo. >>%log% 2>>&1
Echo ...PREPARING install... >>%log% 2>>&1
echo.
if not exist %APP_Location% (
	echo APP_Location not defined, exiting...
	echo APP_Location not defined, exiting... >>%log% 2>>&1
	Goto :EOF
)
Echo ... Prepare config files ...
Echo ... Prepare config files ... >>%log% 2>>&1

:: Schedule tasks
if %Install_Interface_Report% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder Report Interfaces\Report Interfaces\Report Config.cmd
)
if %Install_Interface_SAP% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder SAP-Export Interfaces\SAP_scripts\SAP_export Interfaces\SAP_scripts\SAP_export Config.cmd
	CALL Common.cmd :CopyConfigToSetupFolder SAP-Import Interfaces\SAP_scripts\SAP_import Interfaces\SAP_scripts\SAP_import Config.cmd
)
if %Install_Task_Opschoning% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder Opschoning Tasks\Opschoning Tasks\Opschoning Config.cmd
)
if %Install_Task_FvaMail% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder FvaMail Tasks\FvaMail Tasks\FvaMail Config.cmd
)
if %Install_Task_Nazorg% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder Nazorg Tasks\Nazorg Tasks\Nazorg Config.cmd
)

:: Windows client applications
if %Install_Client_FVA% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder FVA clients\FVA clients\FVA Monitoring.Fiattering.exe.config
)
if %Install_Client_Registratie% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder Registratie clients\Registratie clients\Registratie Monitoring.Registratie.exe.config
)
if %Install_Client_TestTool% EQU 1 (	
	CALL Common.cmd :CopyConfigToSetupFolder TestTool clients\TestTool clients\TestTool Monitoring.TestSetGenerator.exe.config
)

:: Windows services	
if %Install_Service_MonitoringEventService% EQU 1 (
	CALL Common.cmd :CopyConfigToSetupFolder MonitoringEventService services\MonitoringEventService services\MonitoringEventService Monitoring.MonitoringEventService.exe.config
)
if %Install_Service_VosProcessor% EQU 1 (	
	CALL Common.cmd :CopyConfigToSetupFolder VosProcessor services\VosProcessor services\VosProcessor Monitoring.VosProcessor.exe.config
)
if %Install_Service_VerklaringWindowsService% EQU 1 (	
	CALL Common.cmd :CopyConfigToSetupFolder VerklaringWindowsService services\VerklaringWindowsService services\VerklaringWindowsService VerklaringWindowsService.exe.config
)
if %Install_Service_TreinService% EQU 1 (	
	:: IIS services / web sites (Backup current config files for websites to install directory)	
	CALL Common.cmd :CopySingleFile %APP_Location%\services\TreinService\TreinService\Web.config %curpath%\services\TreinService\ suppress
)
if %Install_Service_IdentityService% EQU 1 (	
	CALL Common.cmd :CopySingleFile %APP_Location%\services\VerklaringService\IdentityService\Web.config %curpath%\services\VerklaringService\IdentityService\ suppress
)
if %Install_Service_VosUisListener% EQU 1 (	
	CALL Common.cmd :CopySingleFile %APP_Location%\services\VosUisListener\Web.config %curpath%\services\VosUisService\ suppress
)
if %Install_Service_OngewensteGebeurtenis% EQU 1 (	
	CALL Common.cmd :CopySingleFile %APP_Location%\services\OngewensteGebeurtenisService\Web.config %curpath%\services\OngewensteGebeurtenisService\ suppress
)
::check old path frist
if %Install_Client_MBS% EQU 1 if exist "%APP_Location%\clients\MBS\MBS\Web.config" (	
	CALL Common.cmd :CopySingleFile %APP_Location%\clients\MBS\MBS\Web.config %curpath%\clients\MBS\ suppress
)
:: then check new path
if %Install_Client_MBS% EQU 1 if exist "%APP_Location%\clients\MBS\Web.config" (	
	CALL Common.cmd :CopySingleFile %APP_Location%\clients\MBS\Web.config %curpath%\clients\MBS\ suppress
)
if %Install_Service_Avp3% EQU 1 (	
	CALL Common.cmd :CopySingleFile %APP_Location%\services\Avp3Service\Web.config %curpath%\services\Avp3Service\ suppress
)
if %Install_Service_MonitoringEventService_Stub% EQU 1 (
	CALL Common.cmd :CopySingleFile %APP_Location%\services\MonitoringEventServiceStub\MonitoringEventServiceStub\Web.config %curpath%\services\MonitoringEventServiceStub\ suppress
)


if %Install_Client_MBS% EQU 0 (
	goto NoMBS
)
:: Create websites if necessary
SET poolExists=0
CALL :CheckIfApplicationPoolExists MonitoringBeheerSitePool
if %poolExists% EQU 0 (
	echo "Creating Beheer site"
	echo "Creating Beheer site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringBeheerSitePool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set AppPool "MonitoringBeheerSitePool" /recycling.periodicRestart.time:00:00:00 >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring Beheer Site" /id:105 /physicalPath:"%APP_Location%\clients\MBS" /bindings:https/*:8120: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring Beheer Site" /applicationDefaults.applicationPool:MonitoringBeheerSitePool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set config "Monitoring Beheer Site" /section:windowsAuthentication /enabled:true /commit:apphost >>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring Beheer Site" "MonitoringBeheerSitePool"
	
	
	Echo ***************************************************************************
	Echo ** Selecteer handmatig het HTTPS-verbindingscertificaat
	Echo ** bij de HTTPS binding van de site Monitoring Beheer Site
    Echo ***************************************************************************
    pause
)
:: remove virutal directory
if %Install_Client_MBS% EQU 1 if %poolExists% EQU 1 (
	echo "Beheer site: Remove virutal directory"
	echo "Beheer site: Remove virutal directory" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd delete app /app.name:"Monitoring Beheer Site"/MBS >>%log% 2>>&1
)

:NoMBS
if %StopStart_Client_FvaWeb% EQU 0 (
	goto NoFvaWeb
)
CALL :CheckIfApplicationPoolExists MonitoringFVASitePool
if %poolExists% EQU 0 (
	echo "Creating FVA site"
	echo "Creating FVA site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringFVASitePool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set AppPool "MonitoringFVASitePool" /recycling.periodicRestart.time:00:00:00 >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring FVA Site" /id:106 /physicalPath:"%APP_Location%\clients\FvaWeb" /bindings:http/*:8000: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring FVA Site" /+bindings.[protocol='https',bindingInformation=':443:'] >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring FVA Site" /applicationDefaults.applicationPool:MonitoringFVASitePool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring FVA Site" /applicationDefaults.enabledProtocols:http >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set config "Monitoring FVA Site" /section:windowsAuthentication /enabled:true /commit:apphost >>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring FVA Site" "MonitoringFVASitePool"
	
	Echo ***************************************************************************
	Echo ** Selecteer handmatig het HTTPS-verbindingscertificaat
	Echo ** bij de HTTPS binding van de site Monitoring FVA Site
    Echo ***************************************************************************
    pause
)

:NoFvaWeb
if %Install_Service_VosUisListener% EQU 0 (
	goto NoVosUis
)
CALL :CheckIfApplicationPoolExists MonitoringVosUisServicePool
if %poolExists% EQU 0 (
	echo "Creating VosUisService site"
	echo "Creating VosUisService site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringVosUisServicePool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring VosUisService" /id:107 /physicalPath:"%APP_Location%\Services\VosUisListener" /bindings:http/*:82: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring VosUisService" /applicationDefaults.applicationPool:MonitoringVosUisServicePool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring VosUisService" /applicationDefaults.enabledProtocols:http >>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring VosUisService" "MonitoringVosUisServicePool"
)

:NoVosUis
if %Install_Service_TreinService% EQU 0 (
	goto NoTreinService
)
CALL :CheckIfApplicationPoolExists MonitoringTreinServicesPool
if %poolExists% EQU 0 (
	echo "Creating TreinService site"
	echo "Creating TreinService site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringTreinServicesPool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring TreinService" /id:101 /physicalPath:"%APP_Location%\Services\TreinService" /bindings:http/*:8070: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring TreinService" /applicationDefaults.applicationPool:MonitoringTreinServicesPool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring TreinService" -+bindings.[protocol='net.tcp',bindingInformation='807:*'] >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring TreinService" /applicationDefaults.enabledProtocols:http,net.tcp >>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring TreinService" "MonitoringTreinServicesPool"
)

:NoTreinService
if %Install_Service_IdentityService% EQU 0 (
	goto NoIdentityService
)
CALL :CheckIfApplicationPoolExists MonitoringVerklaringServicesPool
if %poolExists% EQU 0 (
	echo "Creating VerklaringService site"
	echo "Creating VerklaringService site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringVerklaringServicesPool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set AppPool "MonitoringVerklaringServicesPool" /recycling.periodicRestart.time:00:00:00 >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring VerklaringService" /id:102 /physicalPath:"%APP_Location%\Services\VerklaringService" /bindings:http/*:8080: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring VerklaringService" /applicationDefaults.applicationPool:MonitoringVerklaringServicesPool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring VerklaringService" -+bindings.[protocol='net.tcp',bindingInformation='808:*'] >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring VerklaringService" /applicationDefaults.enabledProtocols:http,net.tcp	 >>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring VerklaringService" "MonitoringVerklaringServicesPool"
)

:NoIdentityService
if %Install_Service_OngewensteGebeurtenis% EQU 0 (
	goto NoOngewensteGebeurtenis
)
CALL :CheckIfApplicationPoolExists MonitoringOngewensteGebeurtenisServicePool
if %poolExists% EQU 0 (
	echo "Creating OngewensteGebeurtenisService site"
	echo "Creating OngewensteGebeurtenisService site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringOngewensteGebeurtenisServicePool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring OngewensteGebeurtenisService" /id:109 /physicalPath:"%APP_Location%\Services\OngewensteGebeurtenisService" /bindings:http/*:8060: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring OngewensteGebeurtenisService" /applicationDefaults.applicationPool:MonitoringOngewensteGebeurtenisServicePool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring OngewensteGebeurtenisService" /applicationDefaults.enabledProtocols:http	>>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring OngewensteGebeurtenisService" "MonitoringOngewensteGebeurtenisServicePool"
)

:NoOngewensteGebeurtenis
if %Install_Service_Avp3% EQU 0 (
	goto NoAvp3
)
CALL :CheckIfApplicationPoolExists MonitoringAvp3ServicePool
if %poolExists% EQU 0 (
	echo "Creating Avp3Service site"
	echo "Creating Avp3Service site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringAvp3ServicePool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring Avp3Service" /id:111 /physicalPath:"%APP_Location%\Services\Avp3Service" /bindings:http/*:9010: >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring Avp3Service" /applicationDefaults.applicationPool:MonitoringAvp3ServicePool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring Avp3Service" /applicationDefaults.enabledProtocols:http	>>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring Avp3Service" "MonitoringAvp3ServicePool"
)

:NoAvp3
if %Install_Service_MonitoringEventService_Stub% EQU 0 (
	goto NoMonitoringEventServiceStub
)
CALL :CheckIfApplicationPoolExists MonitoringEventServiceStubPool
SET MonitoringEventServiceStubExists=%poolExists%
if %poolExists% EQU 0 (
	echo "Creating MonitoringEventServiceStub site"
	echo "Creating MonitoringEventServiceStub site" >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add apppool /name:MonitoringEventServiceStubPool /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd add site /name:"Monitoring MonitoringEventServiceStub" /id:103 /physicalPath:"%APP_Location%\Services\MonitoringEventServiceStub" /bindings:http/*:8090: >>%log% 2>>&1		
	%windir%\system32\inetsrv\appcmd set site "Monitoring MonitoringEventServiceStub" /applicationDefaults.applicationPool:MonitoringEventServiceStubPool >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring MonitoringEventServiceStub" -+bindings.[protocol='net.tcp',bindingInformation='809:*'] >>%log% 2>>&1
	%windir%\system32\inetsrv\appcmd set site "Monitoring MonitoringEventServiceStub" /applicationDefaults.enabledProtocols:http,net.tcp >>%log% 2>>&1
	CALL Common.cmd :StopWebsiteIfExists "Monitoring MonitoringEventServiceStub" "MonitoringEventServiceStubPool"
)

:NoMonitoringEventServiceStub
echo. >>%log% 2>>&1
Echo ...DONE PREPARING install... >>%log% 2>>&1
echo.

:: Install IIS websites
echo. >>%log% 2>>&1
Echo ...INSTALLING IIS sites... >>%log% 2>>&1
echo.

if %Install_Service_TreinService% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\services\TreinService\TreinService.Implementation.zip" "Monitoring TreinService/TreinService"
	CALL common.cmd :CopyConfigToAppLocationFolder TreinService services\TreinService services\TreinService\TreinService Web.config
)
if %Install_Service_IdentityService% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\services\VerklaringService\IdentityService\IdentityService.Implementation.zip" "Monitoring VerklaringService/IdentityService"
	CALL common.cmd :CopyConfigToAppLocationFolder IdentityService services\VerklaringService\IdentityService services\VerklaringService\IdentityService Web.config
)
if %Install_Service_VosUisListener% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\services\VosUisService\VosUisService.Implementation.zip" "Monitoring VosUisService"
	CALL common.cmd :CopyConfigToAppLocationFolder VosUisService services\VosUisService services\VosUisListener Web.config
)

::needed to remove in next release
If %Delete_Service_Bijsturing% EQU 1 (
	CALL Common.cmd :RemoveWebsiteAndAppPoolANDWebsiteDirectoryIfExists "Monitoring BijsturingService" MonitoringBijsturingServicePool "%APP_Location%\Services\BijsturingService"
)

if %Install_Service_OngewensteGebeurtenis% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\services\OngewensteGebeurtenisService\OngewensteGebeurtenis.Implementation.zip" "Monitoring OngewensteGebeurtenisService"
	CALL common.cmd :CopyConfigToAppLocationFolder OngewensteGebeurtenisService services\OngewensteGebeurtenisService services\OngewensteGebeurtenisService Web.config
)
If %Delete_Service_TVSM% EQU 1 (
	CALL Common.cmd :RemoveWebsiteAndAppPoolANDWebsiteDirectoryIfExists "Monitoring TvsmService" MonitoringTvsmServicePool "%APP_Location%\Services\TvsmService"
)
if %Install_Client_MBS% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\clients\MBS\MBS.zip" "Monitoring Beheer Site"
	CALL common.cmd :CopyConfigToAppLocationFolder MBS clients\MBS clients\MBS Web.config
)
if %Install_Client_FvaWeb% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\clients\FvaWeb\FVA.zip" "Monitoring FVA Site"
	CALL common.cmd :CopyConfigToAppLocationFolder FvaWeb clients\FvaWeb clients\FvaWeb Web.config
)
if %Install_Service_Avp3% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\services\Avp3Service\Avp3Service.Implementation.zip" "Monitoring Avp3Service"
	CALL common.cmd :CopyConfigToAppLocationFolder Avp3Service services\Avp3Service services\Avp3Service Web.config
)
if %Install_Service_MonitoringEventService_Stub% EQU 1 (
	CALL Common.cmd :InstallIISWebsiteFromPackage "%curpath%\services\MonitoringEventServiceStub\MonitoringEventServiceStub.Implementation.zip" "Monitoring MonitoringEventServiceStub/MonitoringEventServiceStub"
	:: Zet de IIS config files terug
	CALL common.cmd :CopyConfigToAppLocationFolder MonitoringEventServiceStub services\MonitoringEventServiceStub services\MonitoringEventServiceStub\MonitoringEventServiceStub Web.config
)


echo. >>%log% 2>>&1
Echo ...DONE INSTALLING IIS sites... >>%log% 2>>&1
echo.

:: Windows services deïnstalleren
echo. >>%log% 2>>&1
Echo ...INSTALLING Windows services... >>%log% 2>>&1
echo.

if %Install_Service_MonitoringEventService% EQU 1 (
	CALL Common.cmd :UninstallWindowsServiceIfExists "Monitoring MonitoringEvent Service" "%APP_Location%\Services\MonitoringEventService\Monitoring.MonitoringEventService.exe" MonitoringEventService		
	
	if not exist "%APP_Location%\Services\MonitoringEventService" mkdir "%APP_Location%\Services\MonitoringEventService"
	CALL Common.cmd :CopyFilesForService MonitoringEventService "%curpath%\Services\MonitoringEventService" "%APP_Location%\Services\MonitoringEventService"
	CALL Common.cmd :InstallWindowsService MonitoringEventService "%APP_Location%\Services\MonitoringEventService\Monitoring.MonitoringEventService.exe"
)

if %Install_Service_VosProcessor% EQU 1 (
	CALL Common.cmd :UninstallWindowsServiceIfExists "Monitoring VosProcessor" "%APP_Location%\Services\VosProcessor\Monitoring.VosProcessor.exe" VosProcessor

	if not exist "%APP_Location%\Services\VosProcessor" mkdir "%APP_Location%\Services\VosProcessor"
	CALL Common.cmd :CopyFilesForService VosProcessor "%curpath%\Services\VosProcessor" "%APP_Location%\Services\VosProcessor"
	CALL Common.cmd :InstallWindowsService VosProcessor "%APP_Location%\Services\VosProcessor\Monitoring.VosProcessor.exe"
)

if %Install_Service_VerklaringWindowsService% EQU 1 (
	CALL Common.cmd :UninstallWindowsServiceIfExists "Monitoring Verklaring Service" "%APP_Location%\Services\VerklaringWindowsService\VerklaringWindowsService.exe" VerklaringWindowsService

    if not exist "%APP_Location%\Services\VerklaringWindowsService" mkdir "%APP_Location%\Services\VerklaringWindowsService"
	CALL Common.cmd :CopyFilesForService VerklaringWindowsService "%curpath%\Services\VerklaringWindowsService" "%APP_Location%\Services\VerklaringWindowsService"
	CALL Common.cmd :InstallWindowsService VerklaringWindowsService "%APP_Location%\Services\VerklaringWindowsService\VerklaringWindowsService.exe"
)

echo. >>%log% 2>>&1
Echo ...DONE INSTALLING Windows services... >>%log% 2>>&1
echo.

if %Install_Interface_Report% EQU 1 (
	::Scheduletask
	echo. >>%log% 2>>&1
	Echo ...INSTALLING Report Interface... >>%log% 2>>&1
	echo.
	CALL Common.cmd :UninstallScheduleTaskIfExists "BI_Koppeling" %ScheduledTaskFolder%\BI_Koppeling
	if exist "%APP_Location%\Interfaces\Report" rmdir "%APP_Location%\Interfaces\Report" /s /q
	mkdir "%APP_Location%\Interfaces\Report"
	mkdir "%APP_Location%\Interfaces\Report\Queries"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\Report\Queries\*.sql" "%APP_Location%\Interfaces\Report\Queries"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\Report\Run.cmd" "%APP_Location%\Interfaces\Report"	
	if exist "%curpath%\Interfaces\Report\SnapshotCreate_%suffix%.sql" (
		CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\Report\SnapshotCreate_%suffix%.sql" "%APP_Location%\Interfaces\Report\"
		rename "%APP_Location%\Interfaces\Report\SnapshotCreate_%suffix%.sql" SnapshotCreate.sql
	)	
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\Report\Config.cmd" "%APP_Location%\Interfaces\Report"	
	CALL Common.cmd :InstallScheduleTask BI_Koppeling "%ScheduledTaskFolder%\BI_Koppeling" "%APP_Location%\Interfaces\Report\Run.cmd" 02:00
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\BI_Koppeling"
	echo. >>%log% 2>>&1
	Echo ...DONE INSTALLING Report Interface... >>%log% 2>>&1
	echo.
)

if %Install_Interface_SAP% EQU 1 (
	::Install (Scheduled) Tasks for SAP
	echo. >>%log% 2>>&1
	Echo ...INSTALLING SAP Interface... >>%log% 2>>&1
	echo.
	CALL Common.cmd :UninstallScheduleTaskIfExists "SAP_Export" %ScheduledTaskFolder%\SAP_Export
	if not exist "%APP_Location%\Interfaces\SAP_scripts\SAP_export" mkdir "%APP_Location%\Interfaces\SAP_scripts\SAP_export"
	if not exist "%APP_Location%\Interfaces\SAP_scripts\SAP_export\Queries" mkdir "%APP_Location%\Interfaces\SAP_scripts\SAP_export\Queries"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_export\Queries\*.*" "%APP_Location%\Interfaces\SAP_scripts\SAP_export\Queries"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_export\Run.cmd" "%APP_Location%\Interfaces\SAP_scripts\SAP_export"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_export\Common.cmd" "%APP_Location%\Interfaces\SAP_scripts\SAP_export"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_export\Config.cmd" "%APP_Location%\Interfaces\SAP_scripts\SAP_export"	

	CALL Common.cmd :InstallScheduleTask SAP_Export "%ScheduledTaskFolder%\SAP_Export" "%APP_Location%\Interfaces\SAP_scripts\SAP_export\Run.cmd" 0
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\SAP_Export"

	CALL Common.cmd :UninstallScheduleTaskIfExists "SAP_Import" %ScheduledTaskFolder%\SAP_Import
	if not exist "%APP_Location%\Interfaces\SAP_scripts\SAP_import" mkdir "%APP_Location%\Interfaces\SAP_scripts\SAP_import"
	if not exist "%APP_Location%\Interfaces\SAP_scripts\SAP_import\Queries" mkdir "%APP_Location%\Interfaces\SAP_scripts\SAP_import\Queries"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_import\Queries\*.*" "%APP_Location%\Interfaces\SAP_scripts\SAP_import\Queries"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_import\Run.cmd" "%APP_Location%\Interfaces\SAP_scripts\SAP_import"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_import\Common.cmd" "%APP_Location%\Interfaces\SAP_scripts\SAP_import"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\SAP_import\Config.cmd" "%APP_Location%\Interfaces\SAP_scripts\SAP_import"
	CALL Common.cmd :InstallScheduleTask SAP_Import "%ScheduledTaskFolder%\SAP_Import" "%APP_Location%\Interfaces\SAP_scripts\SAP_import\Run.cmd" 0
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\SAP_import"


	CALL Common.cmd :UninstallScheduleTaskIfExists "SAP_Interface" %ScheduledTaskFolder%\SAP_Interface
	if not exist "%APP_Location%\Interfaces\SAP_scripts" mkdir "%APP_Location%\Interfaces\SAP_scripts"
	CALL Common.cmd :CopySingleFile "%curpath%\Interfaces\SAP_scripts\Run.cmd" "%APP_Location%\Interfaces\SAP_scripts"
	CALL Common.cmd :InstallScheduleTask SAP_Interface "%ScheduledTaskFolder%\SAP_Interface" "%APP_Location%\Interfaces\SAP_scripts\Run.cmd" %SAP_scheduleTime%
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\SAP_Interface"

	echo. >>%log% 2>>&1
	Echo ...DONE INSTALLING SAP Interface... >>%log% 2>>&1
	echo.
)

if %Install_Task_Opschoning% EQU 1 (
	::Opschoning
	echo. >>%log% 2>>&1
	Echo ...INSTALLING Opschoning... >>%log% 2>>&1
	echo.
	CALL Common.cmd :UninstallScheduleTaskIfExists "Opschoning" %ScheduledTaskFolder%\Opschoning
	if exist "%APP_Location%\Tasks\Opschoning" rmdir "%APP_Location%\Tasks\Opschoning" /s /q
	mkdir "%APP_Location%\Tasks\Opschoning"	
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\Opschoning\Run.cmd" "%APP_Location%\Tasks\Opschoning"
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\Opschoning\Common.cmd" "%APP_Location%\Tasks\Opschoning"	
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\Opschoning\Config.cmd" "%APP_Location%\Tasks\Opschoning"	
	CALL Common.cmd :InstallScheduleTask Opschoning "%ScheduledTaskFolder%\Opschoning" "%APP_Location%\Tasks\Opschoning\Run.cmd" 03:30
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\Opschoning"
	echo. >>%log% 2>>&1
	Echo ...DONE INSTALLING Opschoning... >>%log% 2>>&1
	echo.
)

if %Install_Task_FvaMail% EQU 1 (
	::FvaMail
	echo. >>%log% 2>>&1
	Echo ...INSTALLING FvaMail... >>%log% 2>>&1
	echo.
	CALL Common.cmd :UninstallScheduleTaskIfExists "FvaMail" %ScheduledTaskFolder%\FvaMail
	if exist "%APP_Location%\Tasks\FvaMail" rmdir "%APP_Location%\Tasks\FvaMail" /s /q
	mkdir "%APP_Location%\Tasks\FvaMail"	
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\FvaMail\Run.cmd" "%APP_Location%\Tasks\FvaMail"
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\FvaMail\Common.cmd" "%APP_Location%\Tasks\FvaMail"	
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\FvaMail\Config.cmd" "%APP_Location%\Tasks\FvaMail"	
	CALL Common.cmd :InstallScheduleTaskFromXml "%ScheduledTaskFolder%\FvaMail" "%curpath%\Tasks\FvaMail\#%ScheduledTaskFolder%#FvaMail.xml" "%APP_Location%\Tasks\FvaMail\Run.cmd"
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\FvaMail"
	echo. >>%log% 2>>&1
	Echo ...DONE INSTALLING FvaMail... >>%log% 2>>&1
	echo.
)

if %Install_Task_Nazorg% EQU 1 (
	::Nazorg
	echo. >>%log% 2>>&1
	Echo ...INSTALLING Nazorg... >>%log% 2>>&1
	echo.
	CALL Common.cmd :UninstallScheduleTaskIfExists "Nazorg" %ScheduledTaskFolder%\Nazorg
	if exist "%APP_Location%\Tasks\Nazorg" rmdir "%APP_Location%\Tasks\Nazorg" /s /q
	mkdir "%APP_Location%\Tasks\Nazorg"	
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\Nazorg\Run.cmd" "%APP_Location%\Tasks\Nazorg"
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\Nazorg\Common.cmd" "%APP_Location%\Tasks\Nazorg"	
	CALL Common.cmd :CopySingleFile "%curpath%\Tasks\Nazorg\Config.cmd" "%APP_Location%\Tasks\Nazorg"	
	CALL Common.cmd :InstallScheduleTask Nazorg "%ScheduledTaskFolder%\Nazorg" "%APP_Location%\Tasks\Nazorg\Run.cmd" 01:30
	CALL Common.cmd :DisableScheduleTaskIfExists "%ScheduledTaskFolder%\Nazorg"
	echo. >>%log% 2>>&1
	Echo ...DONE INSTALLING Nazorg... >>%log% 2>>&1
	echo.
)

:: Windows client applications installeren
:: TODO Verbeter dit. Neem de chm files op in de installpackage en zorg dat je de ACCEPT files net zo behandelt als config files. Dan kun je in een keer de hele directory kopiëren.
echo. >>%log% 2>>&1
Echo ...INSTALLING client applications... >>%log% 2>>&1
echo.

if %Delete_Client_Beheer% EQU 1 (
	echo. >>%log% 2>>&1
	Echo ...REMOVE Beheer... >>%log% 2>>&1
	Echo ...REMOVE Beheer...

	RD /S /Q  "%APP_Location%\clients\Beheer\" >>%log% 2>>&1
	IF !ERRORLEVEL! NEQ 0 GOTO ERROR_HANDLER

	ECHO 		[DONE] 
	ECHO 		[DONE] >>%log% 2>>&1
)

if %Install_Client_Registratie% EQU 1 (
	echo. >>%log% 2>>&1
	Echo ...INSTALLING Registratie... >>%log% 2>>&1
	Echo ...INSTALLING Registratie...
	CALL Common.cmd :CopySingleFile "%curpath%\clients\Registratie\*.exe" "%APP_Location%\clients\Registratie\"
	CALL Common.cmd :CopySingleFile "%curpath%\clients\Registratie\*.dll" "%APP_Location%\clients\Registratie\"
	CALL Common.cmd :CopySingleFile "%curpath%\clients\Registratie\*.config" "%APP_Location%\clients\Registratie\"
	ECHO 		[DONE] 
	ECHO 		[DONE] >>%log% 2>>&1
)

if %Install_Client_FVA% EQU 1 (
	echo. >>%log% 2>>&1
	Echo ...INSTALLING FVA... >>%log% 2>>&1
	Echo ...INSTALLING FVA...
	CALL Common.cmd :CopySingleFile "%curpath%\clients\FVA\*.exe" "%APP_Location%\clients\FVA\"
	CALL Common.cmd :CopySingleFile "%curpath%\clients\FVA\*.dll" "%APP_Location%\clients\FVA\"
	CALL Common.cmd :CopySingleFile "%curpath%\clients\FVA\*.config" "%APP_Location%\clients\FVA\"
	ECHO 		[DONE] 
	ECHO 		[DONE] >>%log% 2>>&1
)
if %Install_Client_TestTool% EQU 1 (
	echo. >>%log% 2>>&1
	Echo ...INSTALLING TestTool... >>%log% 2>>&1
	Echo ...INSTALLING TestTool...
	CALL Common.cmd :CopySingleFile "%curpath%\clients\TestTool\*.exe" "%APP_Location%\clients\TestTool\"
	CALL Common.cmd :CopySingleFile "%curpath%\clients\TestTool\*.dll" "%APP_Location%\clients\TestTool\"
	CALL Common.cmd :CopySingleFile "%curpath%\clients\TestTool\*.config" "%APP_Location%\clients\TestTool\"
	ECHO 		[DONE] 
	ECHO 		[DONE] >>%log% 2>>&1
) 

echo. >>%log% 2>>&1
Echo ...DONE INSTALLING client applications... >>%log% 2>>&1
echo.

::On Opleiding remove the MonitoringEventService
::dit kan worden weggehaald nadat versie 7.9 op "opleiding" geïnstalleerd is
if %Install_Service_MonitoringEventService% EQU 0 (
	if exist "%APP_Location%\Services\MonitoringEventService" (
		if "%SettingsOmgeving%" equ "opleiding" (
			CALL Common.cmd :UninstallWindowsServiceIfExists "Monitoring MonitoringEvent Service" "%APP_Location%\Services\MonitoringEventService\Monitoring.MonitoringEventService.exe" MonitoringEventService
			echo rmdir "%APP_Location%\Services\MonitoringEventService" /s /q >>%log% 2>>&1
			rmdir "%APP_Location%\Services\MonitoringEventService" /s /q
		)
	)
)

::On Opleiding remove the MonitoringEventServiceStub
::dit kan worden weggehaald nadat versie 7.9 op "opleiding" geïnstalleerd is
if %Install_Service_MonitoringEventService_Stub% EQU 0 (
	if "%SettingsOmgeving%" equ "opleiding" (
		CALL Common.cmd :RemoveWebsiteAndAppPoolANDWebsiteDirectoryIfExists "Monitoring MonitoringEventServiceStub" "MonitoringEventServiceStubPool" "%APP_Location%\Services\MonitoringEventServiceStub"
	)
)

cd /D %curpath%

Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::
:CheckIfApplicationPoolExists
:: Check of een IIS application pool reeds bestaat
SET PoolNaam=%1
Echo ...Checking pool %PoolNaam%...
Echo ...Checking pool %PoolNaam%... >>%log% 2>>&1
SET poolExists=0
echo %windir%\system32\inetsrv\appcmd list apppool /name:"%PoolNaam%" >>%log% 2>>&1
%windir%\system32\inetsrv\appcmd list apppool /name:"%PoolNaam%" >>%log% 2>>&1
IF %ERRORLEVEL% EQU 0 (
	SET poolExists=1
	ECHO 		[EXISTS]
	ECHO 		[EXISTS]  >>%log% 2>>&1
) else (
	SET poolExists=0
	ECHO 		[DOES NOT EXIST]
	ECHO 		[DOES NOT EXIST]  >>%log% 2>>&1
)
Goto :EOF
