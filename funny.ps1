# URL to open
$url = "http://youtube-watch.rf.gd/"

# Path to Microsoft Edge (default install location)
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Start Edge in kiosk (fullscreen) mode
$process = Start-Process -FilePath $edgePath `
    -ArgumentList "--kiosk $url --edge-kiosk-type=fullscreen --no-first-run" `
    -PassThru

# Wait 2 minutes (120 seconds)
Start-Sleep -Seconds 120

# Close Edge
if (!$process.HasExited) {
    $process.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 5
    if (!$process.HasExited) {
        $process.Kill()
    }
}
