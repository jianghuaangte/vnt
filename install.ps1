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

# 生成随机字符串的函数 (用于 Device 和 Ports)
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

# 反转字符串的函数
function Reverse-String {
    param([string]$InputString)
    $charArray = $InputString.ToCharArray()
    [array]::Reverse($charArray)
    return -join $charArray
}

# 设置 GitHub 加速地址
$githubAccelerator = "https://ghfast.top/"
$codeUrl = "https://raw.githubusercontent.com/jianghuaangte/vnt-code/refs/heads/main/code.txt"
$acceleratedUrl = $githubAccelerator + $codeUrl

Write-Host "Fetching token from $acceleratedUrl ..."

# 重试机制：最多尝试3次
$maxRetries = 3
$retryCount = 0
$token = $null
$fetchSuccess = $false

while ($retryCount -lt $maxRetries -and -not $fetchSuccess) {
    $retryCount++
    
    if ($retryCount -gt 1) {
        Write-Host "Retry attempt $retryCount of $maxRetries..."
        Start-Sleep -Seconds 2  # 等待2秒后重试
    }
    
    try {
        $response = Invoke-WebRequest -Uri $acceleratedUrl -UseBasicParsing
        $token = $response.Content.Trim()
        
        # 检查内容是否为空
        if (-not [string]::IsNullOrEmpty($token)) {
            $fetchSuccess = $true
            Write-Host "✅ Token fetched successfully on attempt $retryCount."
        } else {
            Write-Host "⚠️ Token content is empty (attempt $retryCount of $maxRetries)."
        }
    } catch {
        Write-Host "⚠️ Failed to fetch token (attempt $retryCount of $maxRetries): $($_.Exception.Message)"
    }
}

# 检查是否成功获取非空 token
if (-not $fetchSuccess) {
    Write-Host "❌ Failed to fetch valid token after $maxRetries attempts. Exiting."
    exit
}

# 生成 Password (Token 的反值)
$password = Reverse-String -InputString $token

# 生成其他参数 (保持原样)
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
