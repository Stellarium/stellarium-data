@echo off
call %USERPROFILE%\Anaconda3\Scripts\activate.bat %USERPROFILE%\Anaconda3
for %%x in (%*) do (
	call %USERPROFILE%\Anaconda3\python %USERPROFILE%\Anaconda3\WCS_corners.py %%x
	)
pause