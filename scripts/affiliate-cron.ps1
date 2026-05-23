# 分销定时任务（建议 Windows 任务计划程序每日 02:00 执行）
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
php think affiliate:cron @args
