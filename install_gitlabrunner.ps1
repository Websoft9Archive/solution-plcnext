# Install Git
$git_url="https://github.com/git-for-windows/git/releases/download/v2.34.1.windows.1/Git-2.34.1-64-bit.exe"
Invoke-WebRequest -Uri $git_url  -OutFile git.exe
Start-Process -FilePath "git.exe" -ArgumentList " /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS" -Wait

# Install GitLab-runner
$gitlab_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe"
Invoke-WebRequest -URI $gitlab_url -OutFile gitlab-runner.exe
.\gitlab-runner.exe install --user root --password yourpassword
.\gitlab-runner.exe start
