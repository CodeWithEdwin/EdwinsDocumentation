Declare @procName varchar(500)

declare curSP cursor 
for select [name] from sys.objects where type = 'p' AND is_ms_shipped = 0
open curSP
fetch next from curSP into @procName
while @@fetch_status = 0
begin
	PRINT 'drop procedure [' + @procName + ']'
    exec('drop procedure [' + @procName + ']')
	PRINT '[OK]'
    fetch next from curSP into @procName
end
close curSP
deallocate curSP

declare curFN cursor 
for select [name] from sys.objects where type in ( 'FN', 'IF', 'TF' ) AND is_ms_shipped = 0
open curFN
fetch next from curFN into @procName
while @@fetch_status = 0
begin
	PRINT 'drop function [' + @procName + ']'
    exec('drop function [' + @procName + ']')
	PRINT '[OK]'
    fetch next from curFN into @procName
end
close curFN
deallocate curFN

declare curVW cursor 
for select [name] from sys.objects where type = 'v' AND is_ms_shipped = 0
open curVW
fetch next from curVW into @procName
while @@fetch_status = 0
begin
	PRINT 'drop view [' + @procName + ']'
    exec('drop view [' + @procName + ']')
	PRINT '[OK]'
    fetch next from curVW into @procName
end
close curVW
deallocate curVW