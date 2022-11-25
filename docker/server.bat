rem This script runs the Rails server and logs the screen output.

REM get DateTime var in a "YYYYMMDD-HHmmSS" format
FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO SET DTS=%%a
SET DateTime=%DTS:~0,8%-%DTS:~8,6%

docker/server-log.bat > log/server-%DateTime%.log 2>&1