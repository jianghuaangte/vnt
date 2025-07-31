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

# 检查管理员权限
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    exit
}

# 下载配置
$zipUrl = "https://gitcode.com/freedom3z/vnt/releases/download/v1.0/vnt.zip"
$installDir = "C:\Program Files\vnt"
$zipFile = Join-Path $env:TEMP "vnt.zip"

Write-Host "Downloading vnt package from $zipUrl..."

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing
} catch {
    Write-Host "Failed to download the package. Please check your internet connection."
    exit
}

# 解压目录处理
Write-Host "Extracting to $installDir..."
if (Test-Path $installDir) {
    Remove-Item -Recurse -Force $installDir
}
Expand-Archive -LiteralPath $zipFile -DestinationPath $installDir

# 随机字符串生成函数
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

# 参数生成
$token = Get-RandomAlphaNumeric -Length 12
$password = Get-RandomAlphaNumeric -Length 12
$device = Get-RandomAlphaNumeric -Length 12
$ports = "58088,58089"
$output = "-k $token -w $password -d $device"

Write-Host "Generated parameters:"
Write-Host $output

# 执行命令
$exePath = Join-Path $installDir "vn-link-cli.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "vn-link-cli.exe not found in extracted directory!"
    exit
}

Write-Host "Launching vn-link-cli.exe..."
Start-Process -FilePath $exePath -WorkingDirectory $installDir -ArgumentList "-k $token -w $password -W --ports $ports -d $device -o 0.0.0.0/0" -NoNewWindow -Wait

Write-Host @"
Done!

Your VNT service is now running with the following:
Token:    $token
Password: $password
Device:   $device
Ports:    $ports

Check the output for any runtime messages.
"@
