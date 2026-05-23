# ThinkPHP 本地开发：自动查找 php.exe 后执行 `think run`
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$projectPhp = Join-Path (Split-Path $root -Parent) 'tools\php\php.exe'

# Chocolatey 刚装完 PHP 时，当前窗口的 PATH 可能尚未包含 shims，先补上
$chocoBin = if ($env:ChocolateyInstall) {
    Join-Path $env:ChocolateyInstall 'bin'
} else {
    Join-Path $env:ProgramData 'chocolatey\bin'
}
if ($chocoBin -and (Test-Path $chocoBin)) {
    $env:Path = "$chocoBin;$env:Path"
}

function Test-PhpSqlite([string]$exe) {
    if (-not (Test-Path $exe)) { return $false }
    $mods = & $exe -m 2>$null
    return ($mods -match 'pdo_sqlite')
}

$candidates = @(
    $projectPhp,
    'C:\tools\php83\php.exe',
    (Get-Command php -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    (Join-Path $chocoBin 'php.exe'),
    "$env:ChocolateyInstall\lib\php\tools\php.exe",
    'C:\tools\php82\php.exe',
    'C:\php\php.exe'
) | Where-Object { $_ -and (Test-Path $_) }

$php = $candidates | Where-Object { Test-PhpSqlite $_ } | Select-Object -First 1
if (-not $php) {
    $php = $candidates | Select-Object -First 1
}
if (-not $php) {
    Write-Host (@"

未找到 php.exe。任选一种方式安装 PHP 8.1+：

1) 管理员 PowerShell（网络稳定时重试）：
   choco install php -y

2) 手动（推荐离线/网络差时）：
   - 打开 https://windows.php.net/download 下载 VS16 x64 Thread Safe ZIP
   - 解压到例如 C:\php
   - 系统设置 -> 环境变量 -> Path -> 新建 C:\php
   - 新开终端，在本目录执行： php think run

3) 若已安装 PHP 但未进 Path，把本脚本里的路径改成你的 php.exe 全路径后运行。

"@) -ForegroundColor Yellow
    exit 1
}

Write-Host "Using: $php" -ForegroundColor Cyan
Set-Location $root
& $php think run @args
