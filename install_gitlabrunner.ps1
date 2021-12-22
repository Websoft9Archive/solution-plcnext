# Install git
#Invoke-WebRequest -URI "https://github.com/git-for-windows/git/releases/download/v2.34.1.windows.1/PortableGit-2.34.1-64-bit.7z.exe" -OutFile git.exe
#Start-Process git.exe -ArgumentList '--installPath C:\Program Files\Git --quiet --norestart' -wait -NoNewWindow

# Install gitlab-runner
Invoke-WebRequest -URI "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe" -OutFile gitlab-runner.exe
.\gitlab-runner.exe install --user root --password yourpassword
.\gitlab-runner.exe start
