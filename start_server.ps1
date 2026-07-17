# start_server.ps1 - Simple PowerShell Web Server
# Run this script to start a local server at http://localhost:8080/

$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
} catch {
    Write-Host "Error starting listener: $_" -ForegroundColor Red
    Write-Host "Ensure port $port is not already in use." -ForegroundColor Yellow
    exit
}

Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Web Server Started Successfully!" -ForegroundColor Green
Write-Host "  Access your dashboard at: http://localhost:$port/" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C in this window to stop the server." -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Green

$currentDir = $PSScriptRoot
if (-not $currentDir) { $currentDir = Get-Location }

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $urlPath = $request.Url.LocalPath.Replace("%20", " ")
        if ($urlPath -eq "/") {
            $urlPath = "/index.html"
        }
        
        # Build local file path
        $filePath = Join-Path $currentDir $urlPath
        
        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            # Set mime type
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = "text/html"
            if ($ext -eq ".css") { $contentType = "text/css" }
            elseif ($ext -eq ".js") { $contentType = "application/javascript" }
            elseif ($ext -eq ".png") { $contentType = "image/png" }
            elseif ($ext -eq ".jpg" -or $ext -eq ".jpeg") { $contentType = "image/jpeg" }
            elseif ($ext -eq ".svg") { $contentType = "image/svg+xml" }
            
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.Close()
    }
} catch {
    Write-Host "Server interrupted or closed." -ForegroundColor Gray
} finally {
    $listener.Stop()
}
