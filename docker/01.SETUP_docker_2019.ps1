##############################################################################################
## needed to create the local folder that sql server can access
##############################################################################################
$backuppath = "C:\Docker\SQL\"
if((Test-Path -Path $backuppath) -eq $false) {
    md $backuppath
}

##############################################################################################
## SQL SERVER localhost
##############################################################################################
#Here is the Docker Hub Library describing it: https://hub.docker.com/_/microsoft-mssql-server

#This is abrilliant user guide
#https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-docker?view=sql-server-ver15

#Step #1 - Get the latest Docker Image from which to build the container from.
docker pull mcr.microsoft.com/mssql/server:2019-latest

#Or Get a Specific Version
#docker pull mcr.microsoft.com/mssql/server:2019-CTP3.2-ubuntu

#Now build a containter with a Data Volume so that any database restores persists between starting
# and stopping the container.
docker run `
--name DEVSQL19 `
-p 15789:1433 `
-e "ACCEPT_EULA=Y" `
-e "SA_PASSWORD=Soft2Bounce#" `
-v DEVSQLVolume:/var/opt/mssql `
-d mcr.microsoft.com/mssql/server:2019-latest


#Copy a backup file into the /var/backups folder on the Container.  
docker cp C:\Docker\SQL\Backup\SeniorDebt.bak DEVSQL19:/var/backups
docker cp C:\Docker\SQL\Backup\CoInvestApp.bak DEVSQL19:/var/backups

#Next open SSMS, or Azure Data Studio to restore the backup (or use the GUI)
#You will need to look for the file in the /var/backups folder.
USE [master]
RESTORE DATABASE [SeniorDebt] FROM  DISK = N'/var/backups/SeniorDebt.bak' 
WITH  FILE = 1,  
MOVE N'SeniorDebt' TO N'/var/opt/mssql/data/SeniorDebt.mdf',  
MOVE N'SeniorDebt_log' TO N'/var/opt/mssql/data/SeniorDebt_log.ldf',  
NOUNLOAD,  STATS = 5

USE [master]
RESTORE DATABASE [SeniorDebt] FROM  DISK = N'/var/backups/CoInvestApp.bak' 
WITH  FILE = 1,  
MOVE N'CoInvestApp' TO N'/var/opt/mssql/data/CoInvestApp.mdf',  
MOVE N'CoInvestApp_log' TO N'/var/opt/mssql/data/CoInvestApp_log.ldf',  
NOUNLOAD,  STATS = 5

#These are commands to manage the container.
# docker rm DEVSQL19 -f
# docker start DEVSQL19
# docker stop DEVSQL19
# docker ps -a
# docker logs DEVSQL19

##############################################################################################
## copy a bak file into the folder for restoreability
##############################################################################################
$backuppath = "C:\Docker\SQL\Backup\"
$backupfile = "VSDBA.bak"

if((Test-Path -Path $backuppath) -eq $false) {
    md $backuppath
}

if((Test-Path -Path ($backuppath + $backupfile)) -eq $false) {
    Copy-Item ".\Files\VSDBA.bak" $backuppath
}


#5/20/20 - Previously the run command below was used to mount a volume to the local c drive.
#I am not sure why, but this method no longer works.  Instead, I copy the backup file directly up.
#HINT: Before, when restoring a database within SSMS, change the path to c:\sql, and linux will properly pick it up.
docker run `
--name DEVSQL19 `
-p 15789:1433 `
-e "ACCEPT_EULA=Y" `
-e "SA_PASSWORD=Soft2Bounce#" `
-v C:\Docker\SQL:/sql `
-d mcr.microsoft.com/mssql/server:2019-latest


##############################################################################################
## powershell to run SQL CMD SHELL
##############################################################################################
<#
    sqlcmd -S localhost,15789 -U SA -P "Soft2Bounce#"

    CREATE DATABASE TestDB;
    SELECT Name from sys.Databases;
    GO

    USE TestDB
    CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)
    INSERT INTO Inventory VALUES (1, 'banana', 150); INSERT INTO Inventory VALUES (2, 'orange', 154);
    GO

    SELECT * FROM Inventory WHERE quantity > 152;
    SELECT * FROM Inventory;
    GO

#>