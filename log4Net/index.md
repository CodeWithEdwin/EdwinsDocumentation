<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Meerder log files
Het is mogelijk om binnen 1 service of client meerdere log files te gebruiken voor specifieke onderdelen, zoals bijv. in de Vos Processor gebruikt wordt. 

Als uitgangspunt nemen we de volgende configuratie om het e.e.a. toe te lichten: 
```
<log4net> 
<root> 
<level value="INFO" /> 
<appender-ref ref="default" /> 
</root> 
<logger additivity="false" name="logging1"> 
<level value="INFO" /> 
<appender-ref ref="logging1" /> 
</logger> 
<logger additivity="false" name="logging2"> 
<level value="INFO" /> 
<appender-ref ref="logging2" /> 
</logger> 
<logger additivity="false" name="logging3"> 
<level value="INFO" /> 
<appender-ref ref="logging3" /> 
</logger> 

<appender name="default" type="log4net.Appender.RollingFileAppender"> 
<file value="D:\Log\file.log" /> 
<appendToFile value="true" /> 
<rollingStyle value="Size" /> 
<maxSizeRollBackups value="10" /> 
<maximumFileSize value="150MB" /> 
<staticLogFileName value="true" /> 
<layout type="log4net.Layout.PatternLayout"> <header value="date, thread, level, class, method, message" /> 
<conversionPattern value="%newline%date{yyyy-MM-dd HH:mm:ss.fff}, %thread, %level, %class, %method, %message" /> 
</layout> 
</appender> 

<appender name="logging1" type="log4net.Appender.RollingFileAppender"> 
<file value="D:\Log\file.logging1.log" /> 
<appendToFile value="true" /> 
<rollingStyle value="Size" /> 
<maxSizeRollBackups value="10" /> 
<maximumFileSize value="150MB" /> 
<staticLogFileName value="true" /> 
<layout type="log4net.Layout.PatternLayout"> 
<header value="date, thread, level, class, method, message" /> 
<conversionPattern value="%newline%date{yyyy-MM-dd HH:mm:ss.fff}, %thread, %level, %class, %method, %message" /> 
</layout> 
</appender> 

<appender name="logging2" type="log4net.Appender.RollingFileAppender"> 
<file value="D:\Log\file.logging2.log" /> 
<appendToFile value="true" /> 
<rollingStyle value="Size" /> 
<maxSizeRollBackups value="10" /> 
<maximumFileSize value="150MB" /> 
<staticLogFileName value="true" /> 
<layout type="log4net.Layout.PatternLayout"> 
<header value="date, thread, level, class, method, message" /> 
<conversionPattern value="%newline%date{yyyy-MM-dd HH:mm:ss.fff}, %thread, %level, %class, %method, %message" /> 
</layout> 
</appender> 

<appender name="logging3" type="log4net.Appender.RollingFileAppender"> 
<file value="D:\Log\file.logging3.log" /> 
<appendToFile value="true" /> 
<rollingStyle value="Size" /> 
<maxSizeRollBackups value="10" /> 
<maximumFileSize value="150MB" /> 
<staticLogFileName value="true" /> 
<layout type="log4net.Layout.PatternLayout"> 
<header value="date, thread, level, class, method, message" /> 
<conversionPattern value="%newline%date{yyyy-MM-dd HH:mm:ss.fff}, %thread, %level, %class, %method, %message" /> 
</layout> 
</appender> 

</log4net> 
```

Hier staan meerdere zgn. appenders in die in dit geval gebruikt worden als bestandslogging. 
Iedere appender dient een naam te hebben zodat er naar gerefereerd kan worden. 
Om te zorgen dat de logging niet doorelkaar gaat lopen moet er voor iedere extra appender een logger gedefinieerd worden waarbij verwezen wordt naar de appender. 
In dit geval is er ook gekozen om een default appender te definieeren waar in de root naar verwezen wordt. 
Deze constructie is nodig om meerdere bestandslogging te kunnen doen waarbij logging niet door elkaar gaat lopen.  

De naam van de appender moet gebruikt worden om toe te voegen als logger aan de Logging4Net class. 
Door deze naam door te geven aan de functie AddLogger wordt deze uitgelezen en kan deze gebruikt worden.
Bij ieder logstatement moet deze naam als parameter meegegeven te worden om te zorgen dat de log in de juiste appender terecht komt: 
 
```
LogInfo(“logging3”, "Test") 
````
 

Gebruik je echter de standaard logging zonder de naam van de appender door te geven, dan komt de logging in de default appender terecht (gespecificeerd in root) 

```
LogInfo("Test") 
```