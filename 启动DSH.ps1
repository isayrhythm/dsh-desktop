$ErrorActionPreference = 'Continue'
$log = 'D:\workspace\dsh-desktop\launch.log'
function Log($m) { "$(Get-Date -Format 'HH:mm:ss') $m" | Out-File -FilePath $log -Append -Encoding utf8 }
Log '=== ps1 started ==='
$port = 3080
$appUrl = '--app=http://127.0.0.1:' + $port
$listening = netstat -ano | Select-String (':' + $port + '\s+.*LISTENING')
if (-not $listening) {
    Log 'starting server (hidden)'
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','npx --yes @deepseek-ai/dsh@latest web --no-open' -WorkingDirectory "$env:USERPROFILE\Desktop" -WindowStyle Hidden
    $deadline = (Get-Date).AddSeconds(120)
    $waited = 0
    while (-not (netstat -ano | Select-String (':' + $port + '\s+.*LISTENING')) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        $waited++
    }
    Log ('server wait done, loops=' + $waited)
}
Log 'launching Edge'
try {
    $p = Start-Process -FilePath 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -ArgumentList $appUrl -PassThru
    Log ('edge started pid=' + $p.Id)
} catch {
    Log ('EDGE ERROR: ' + $_.Exception.Message)
}
Log '=== ps1 finished ==='
