rem This script builds the Docker container, seeds the app with sample data, and logs the screen output.

REM get DateTime var in a "YYYYMMDD-HHmmSS" format
FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO SET DTS=%%a
SET DateTime=%DTS:~0,8%-%DTS:~8,6%

REM Launches docker build and database seed
docker/build-log.bat > log/build-%DateTime%.log 2>&1
docker/seed.bat  > log/seed-%DateTime%.log 2>&1
