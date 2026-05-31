@echo off
chcp 65001 >nul
title C盘缓存清理工具

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 警告：本脚本需要管理员权限才能完全生效！
    echo 请右键选择“以管理员身份运行”。
    pause
    exit /b
)

echo ==================================
echo 正在完整清理C盘全部缓存垃圾
echo ==================================

echo [1/12] 清理用户临时文件
del /f /s /q "%temp%\*" 2>nul
for /d %%i in ("%temp%\*") do rd /s /q "%%i" 2>nul
del /f /s /q "%localappdata%\Temp\*" 2>nul
for /d %%i in ("%localappdata%\Temp\*") do rd /s /q "%%i" 2>nul

echo [2/12] 清理系统预读缓存
del /f /q "C:\Windows\Prefetch\*" 2>nul

echo [3/12] 清理打印缓存
net stop spooler 2>nul
del /f /q "C:\Windows\System32\spool\PRINTERS\*" 2>nul
net start spooler 2>nul

echo [4/12] 清理UWP应用缓存
for /d %%i in ("%localappdata%\Packages\*") do (
    if exist "%%i\AC\Temp\" (
        del /f /s /q "%%i\AC\Temp\*" 2>nul
        for /d %%j in ("%%i\AC\Temp\*") do rd /s /q "%%j" 2>nul
    )
    if exist "%%i\LocalCache\Local\Cache\" (
        del /f /s /q "%%i\LocalCache\Local\Cache\*" 2>nul
        for /d %%j in ("%%i\LocalCache\Local\Cache\*") do rd /s /q "%%j" 2>nul
    )
)

echo [5/12] 清理IE/旧Edge缓存
del /f /s /q "%localappdata%\Microsoft\Windows\INetCache\*" 2>nul
for /d %%i in ("%localappdata%\Microsoft\Windows\INetCache\*") do rd /s /q "%%i" 2>nul

echo [6/12] 清理Chrome缓存
del /f /q "%localappdata%\Google\Chrome\User Data\Default\Cache\*" 2>nul

echo [7/12] 清理新版Edge缓存
del /f /q "%localappdata%\Microsoft\Edge\User Data\Default\Cache\*" 2>nul

echo [8/12] 清理图标缩略图缓存

taskkill /f /im explorer.exe >nul 2>&1
del /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache_*.db" 2>nul
del /f /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul

timeout /t 1 /nobreak >nul
start explorer.exe

echo [9/12] 刷新DNS缓存
ipconfig /flushdns >nul 2>&1

echo [10/12] 清理Windows更新缓存
net stop wuauserv 2>nul
del /f /q "C:\Windows\SoftwareDistribution\Download\*" 2>nul
for /d %%i in ("C:\Windows\SoftwareDistribution\Download\*") do rd /s /q "%%i" 2>nul
net start wuauserv 2>nul

:: 11. 系统错误报告
echo [11/12] 清理系统错误报告
del /f /q "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*" 2>nul
for /d %%i in ("C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*") do rd /s /q "%%i" 2>nul
del /f /q "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" 2>nul
for /d %%i in ("C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*") do rd /s /q "%%i" 2>nul

echo [12/12] 清理系统安装日志

takeown /f "C:\Windows\Logs\CBS" /r /d y >nul 2>&1
icacls "C:\Windows\Logs\CBS" /grant administrators:F /t >nul 2>&1
del /f /q "C:\Windows\Logs\CBS\*" 2>nul

echo.
echo ==================================
echo 全部清理完成！
echo ==================================
echo 提示：若桌面图标或任务栏未恢复，请手动重启资源管理器。
pause
