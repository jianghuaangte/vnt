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

# GitHub 加速地址
$githubProxy = "https://ghfast.top/"
$tokenUrl = "$githubProxy/https://raw.githubusercontent.com/jianghuaangte/vnt-code/refs/heads/main/code.txt"

# 获取 Token（最多重试3次）
$token = $null
$maxRetries = 3
$retryCount = 0

while ($retryCount -lt $maxRetries -and (-not $token -or $token -eq "")) {
    try {
        Write-Host "Fetching token from $tokenUrl (Attempt $($retryCount+1))..."
        $response = Invoke-WebRequest -Uri $tokenUrl -UseBasicParsing -ErrorAction Stop
        $token = $response.Content.Trim()
        # 移除可能的特殊字符，只保留字母数字
        $token = $token -replace '[^a-zA-Z0-9]', ''
        
        if (-not $token -or $token -eq "") {
            throw "Empty or invalid token received."
        }
        Write-Host "Token fetched successfully: $token"
    } catch {
        Write-Warning "Failed to fetch token: $_"
        $token = $null
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $token -or $token -eq "") {
    Write-Error "Unable to fetch token after $maxRetries attempts. Exiting."
    exit 1
}

# 计算 Password 为 Token 的反值（添加调试信息和错误处理）
Write-Host "Debug: Original token = '$token'"
Write-Host "Debug: Token length = $($token.Length)"

# 方法1：使用字符串反转（最简单）
$password = ""
if ($token -and $token.Length -gt 0) {
    # 将字符串转换为字符数组并反转
    $charArray = $token.ToCharArray()
    [Array]::Reverse($charArray)
    $password = -join $charArray
}

# 如果方法1失败，使用方法2
if (-not $password -or $password -eq "") {
    Write-Host "Method 1 failed, trying Method 2..."
    # 方法2：手动反转
    $password = ""
    for ($i = $token.Length - 1; $i -ge 0; $i--) {
        $password += $token[$i]
    }
}

Write-Host "Debug: Generated password = '$password'"
Write-Host "Debug: Password length = $($password.Length)"

# 生成随机 Device 和 Ports（保持原样）
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

$device = Get-RandomAlphaNumeric
$ports = "58088,58089"

# 显示参数
Write-Host "`n✅ Generated parameters:"
Write-Host "Token:    $token"
Write-Host "Password: $password"
Write-Host "Device:   $device"
Write-Host "Ports:    $ports`n"

# 后续安装和运行逻辑保持不变
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

# 执行命令
$exePath = $vnCli.FullName
$workingDir = Split-Path $exePath
$arguments = "-k $token -w $password -W --ports $ports -d $device -o 0.0.0.0/0"

Write-Host "🚀 Running vn-link-cli.exe..."
Write-Host "Command: $exePath $arguments"
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
