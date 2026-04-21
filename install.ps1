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

# 生成随机字符串的函数 (用于device)
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

# --- 配置加速地址并获取Token ---
$githubAccelerator = "https://ghfast.top/"
$tokenUrl = $githubAccelerator + "https://raw.githubusercontent.com/jianghuaangte/vnt-code/refs/heads/main/code.txt"

Write-Host "`nFetching token from $tokenUrl ..."

# 重试获取token，最多3次
$maxRetries = 3
$retryCount = 0
$token = $null

do {
    $retryCount++
    try {
        Write-Host "Attempt $retryCount of $maxRetries..."
        $response = Invoke-WebRequest -Uri $tokenUrl -UseBasicParsing
        $token = $response.Content.Trim()
        
        # 检查是否成功获取到非空值
        if ($token) {
            Write-Host "✅ Token fetched successfully: $token"
            break
        } else {
            Write-Host "⚠️ Token is empty, retrying..."
        }
    } catch {
        Write-Host "⚠️ Failed to fetch token: $_"
    }
    
    # 如果不是最后一次尝试，等待1秒
    if ($retryCount -lt $maxRetries -and -not $token) {
        Write-Host "Waiting 1 second before retry..."
        Start-Sleep -Seconds 1
    }
} while ($retryCount -lt $maxRetries -and -not $token)

# 检查最终是否获取到token
if (-not $token) {
    Write-Host "❌ Failed to fetch token after $maxRetries attempts. Please check the URL or your internet connection."
    exit
}

# 生成password (token的反向字符串)
try {
    $charArray = $token.ToCharArray()
    [Array]::Reverse($charArray)
    $password = -join $charArray
    Write-Host "✅ Password generated successfully."
} catch {
    Write-Host "❌ Failed to generate password from token: $_"
    exit
}

# 生成device和ports (保持原样)
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
