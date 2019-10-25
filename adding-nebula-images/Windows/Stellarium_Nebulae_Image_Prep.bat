@echo off
call %USERPROFILE%\Anaconda3\Scripts\activate.bat %USERPROFILE%\Anaconda3
for %%x in (%*) do (
	call %USERPROFILE%\Anaconda3\python %USERPROFILE%\Anaconda3\Stellarium_Nebulae_Image_Prep.py %%x
	)
pause