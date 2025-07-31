param(
    [switch]$AllUsers
)

$installInstructions = @'
Hey friend

This installer is only available for Windows.
Please manually install on other systems.
'@

if ($IsMacOS -or $IsLinux) {
    Write-Host $installInstructions
    exit
}

# 检查是否管理员权限
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    exit
}

$zipUrl = "https://gitcode.com/freedom3z/vnt/releases/download/v1.0/vnt.zip"
$installDir = "C:\Program Files\vnt"
$zipFile = Join-Path $env:TEMP "vnt.zip"

Write-Host "Downloading package from $zipUrl..."

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing
} catch {
    Write-Host "❌ Failed to download the package. Please check your internet connection."
    exit
}

# 解压目录
Write-Host "Extracting to $installDir..."
if (Test-Path $installDir) {
    Remove-Item -Recurse -Force $installDir
}
Expand-Archive -LiteralPath $zipFile -DestinationPath $installDir

# 查找 vn-link-cli.exe
Write-Host "Searching for vn-link-cli.exe..."
$vnCli = Get-ChildItem -Path $installDir -Filter "vn-link-cli.exe" -Recurse -File | Select-Object -First 1

if (-not $vnCli) {
    Write-Host "❌ vn-link-cli.exe not found after extraction."
    exit
}

# 生成随机字符串的函数
function Get-RandomAlphaNumeric {
    param([int]$Length = 12)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $random = New-Object System.Random
    $string = ""
    1..$Length | ForEach-Object {
        $string += $chars[$random.Next(0, $chars.Length)]
    }
    return $string
}

# 生成唯一参数
$token = Get-RandomAlphaNumeric
do {
    $password = Get-RandomAlphaNumeric
} while ($password -eq $token)

$device = Get-RandomAlphaNumeric
$ports = "58088,58089"

# 显示参数
Write-Host "`n✅ Generated parameters:"
Write-Host "Token:    $token"
Write-Host "Password: $password"
Write-Host "Device:   $device"
Write-Host "Ports:    $ports`n"

# 执行命令
$exePath = $vnCli.FullName
$workingDir = Split-Path $exePath
$arguments = "-k $token -w $password -W --ports $ports -d $device -o 0.0.0.0/0"

Write-Host "🚀 Running vn-link-cli.exe..."
try {
    Start-Process -FilePath $exePath -WorkingDirectory $workingDir -ArgumentList $arguments -NoNewWindow -Wait
} catch {
    Write-Host "❌ Failed to start vn-link-cli.exe"
    exit
}

Write-Host @"
🎉 Done!

vn-link-cli.exe executed successfully with the following parameters:
------------------------------------------------------
Token:    $token
Password: $password
Device:   $device
Ports:    $ports
------------------------------------------------------
"@
