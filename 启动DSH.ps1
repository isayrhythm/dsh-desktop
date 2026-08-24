$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $scriptDir 'launch.log'
function Log($m) { "$(Get-Date -Format 'HH:mm:ss') $m" | Out-File -FilePath $log -Append -Encoding utf8 }
Log '=== ps1 started ==='

$port = 3080
$appUrl = '--app=http://127.0.0.1:' + $port

$listening = netstat -ano | Select-String (':' + $port + '\s+.*LISTENING')
if (-not $listening) {
    # 清理之前卡死的 npx 下载进程（只在 3080 空闲时执行，不会误伤正在运行的服务器）
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -match '@deepseek-ai/dsh@latest'
    } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }

    # 只使用本地已经下载好的 DSH，绝不联网重新下载
    $node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
    $serverProc = $null
    if ($node) {
        $bin = $null
        # 1) 优先：npx 缓存里已下载的包（取版本最高的）
        $candidates = Get-ChildItem "$env:LOCALAPPDATA\npm-cache\_npx" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $pkg = Join-Path $_.FullName 'node_modules\@deepseek-ai\dsh\package.json'
            $b = Join-Path $_.FullName 'node_modules\@deepseek-ai\dsh\lib\bin.js'
            if ((Test-Path $b) -and (Test-Path $pkg)) {
                $v = (Get-Content $pkg -Raw | ConvertFrom-Json).version
                [pscustomobject]@{ Version = $v; Bin = $b }
            }
        } | Sort-Object { try { [version]($_.Version -replace '-.*$', '') } catch { [version]'0.0.0' } } -Descending
        if (@($candidates).Count -gt 0) { $bin = @($candidates)[0].Bin }
        # 2) 其次：全局 npm 安装的 dsh（npm i -g @deepseek-ai/dsh）
        if (-not $bin) {
            $dshCmd = Get-Command dsh.cmd -ErrorAction SilentlyContinue
            if ($dshCmd) {
                $g = Join-Path (Split-Path -Parent $dshCmd.Source) 'node_modules\@deepseek-ai\dsh\lib\bin.js'
                if (Test-Path $g) { $bin = $g }
            }
        }

        if ($bin) {
            Log ('starting cached dsh (no download): ' + $bin)
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $node
            $psi.Arguments = '"' + $bin + '" web --no-open'
            $psi.WorkingDirectory = "$env:USERPROFILE\Desktop"
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            try {
                $serverProc = [System.Diagnostics.Process]::Start($psi)
                Log ('server pid=' + $serverProc.Id)
            } catch {
                Log ('SERVER START ERROR: ' + $_.Exception.Message)
            }
        } else {
            Log 'ERROR: 本地没有已下载的 DSH 包，启动器不会联网下载。请先手动安装一次: 在命令行运行  npx --yes @deepseek-ai/dsh@latest web --no-open  （下载完成后以后都秒开）'
        }
    } else {
        Log 'ERROR: 未找到 node.exe，请先安装 Node.js'
    }

    $deadline = (Get-Date).AddSeconds(120)
    $waited = 0
    while (-not (netstat -ano | Select-String (':' + $port + '\s+.*LISTENING')) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        $waited++
    }
    if (-not (netstat -ano | Select-String (':' + $port + '\s+.*LISTENING'))) {
        Log ('WARN: server not up after ' + $waited + ' loops')
    }
    Log ('server wait done, loops=' + $waited)
}

Log 'launching Edge'
$edge = ''
foreach ($candidate in @(
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
)) {
    if (Test-Path $candidate) { $edge = $candidate; break }
}
if (-not $edge) { $edge = (Get-Command msedge.exe -ErrorAction SilentlyContinue).Source }
try {
    if ($edge) {
        $p = Start-Process -FilePath $edge -ArgumentList $appUrl -PassThru
        Log ('edge started pid=' + $p.Id)
    } else {
        Log 'EDGE ERROR: msedge.exe not found, opening default browser'
        Start-Process ('http://127.0.0.1:' + $port)
    }
} catch {
    Log ('EDGE ERROR: ' + $_.Exception.Message)
}
Log '=== ps1 finished ==='
