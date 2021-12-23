# Install Git
$git_url="https://github.com/git-for-windows/git/releases/download/v2.34.1.windows.1/Git-2.34.1-64-bit.exe"
Invoke-WebRequest -Uri $git_url  -OutFile git.exe
Start-Process -FilePath "git.exe" -ArgumentList " /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS" -Wait


# Install GitLab-runner
$password=Get-Random
echo $password | out-file -filepath password.txt

new-item GitLab-Runner -type directory
cd GitLab-Runner
$runner_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe"
Invoke-WebRequest -URI $runner_url -OutFile gitlab-runner.exe
.\gitlab-runner.exe install --user root --password $password
.\gitlab-runner.exe start
