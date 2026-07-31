title crystalTechBackup_process---Maxz666
@echo off
echo start backup!
set datetime=%date:~0,4%%date:~5,2%%date:~8,2%
echo currentTime : %datetime%
md #crystalTech_backup%datetime%
copy /-y crystalTech\* #crystalTech_backup%datetime%
echo copy successfully!
copy nul #crystalTech_backup%datetime%\__visionAccount.txt
echo account file create successfully
pause