Invoke-WebRequest -URI “https://github.com/git-for-windows/git/releases/download/v2.34.1.windows.1/Git-2.34.1-64-bit.exe” -OutFile git.exe
Start-Process git.exe -ArgumentList '--installPath C:\git --quiet --norestart' -wait -NoNewWindow
