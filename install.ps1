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
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    exit
}

$zipUrl = "https://gitcode.com/freedom3z/vnt/releases/download/v1.0/vnt.zip"
$installDir = "C:\Program Files\vnt"
$zipFile = Join-Path $env:TEMP "vnt.zip"

Write-Host "Downloading package from $zipUrl..."

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
} catch {
    Write-Host "❌ Failed to download the package."
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
    Write-Host "❌ vn-link-cli.exe not found."
    exit
}

# ================================
# GitHub token 获取（兼容旧PS）
# ================================
$githubProxy = "https://ghfast.top/"
$tokenUrl = "https://raw.githubusercontent.com/jianghuaangte/vnt-code/refs/heads/main/code.txt"
$finalTokenUrl = $githubProxy + $tokenUrl

Write-Host "Fetching token..."

try {
    $response = Invoke-WebRequest -Uri $finalTokenUrl
    $token = $response.Content.Trim()
} catch {
    Write-Host "❌ Failed to fetch token"
    exit
}

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "❌ Token is empty"
    exit
}

# ================================
# password = token 反转 (最兼容)
# ================================
$password = ""
for ($i = $token.Length - 1; $i -ge 0; $i--) {
    $password += $token[$i]
}

# 随机字符串函数
function Get-RandomAlphaNumeric {
    param([int]$Length = 12)

    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $random = New-Object System.Random
    $result = ""

    for ($i = 0; $i -lt $Length; $i++) {
        $result += $chars[$random.Next(0, $chars.Length)]
    }

    return $result
}

# 保持原逻辑
$device = Get-RandomAlphaNumeric
$ports = "58088,58089"

Write-Host ""
Write-Host "Token:    $token"
Write-Host "Password: $password"
Write-Host "Device:   $device"
Write-Host "Ports:    $ports"
Write-Host ""

# 执行
$exePath = $vnCli.FullName
$workingDir = Split-Path $exePath
$arguments = "-k $token -w $password -W --ports $ports -d $device -o 0.0.0.0/0"

Write-Host "Running vn-link-cli.exe..."

try {
    Start-Process -FilePath $exePath `
        -WorkingDirectory $workingDir `
        -ArgumentList $arguments `
        -NoNewWindow `
        -Wait
} catch {
    Write-Host "❌ Failed to start vn-link-cli.exe"
    exit
}

Write-Host ""
Write-Host "Done!"
