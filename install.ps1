# Install Git
$git_url="https://github.com/git-for-windows/git/releases/download/v2.34.1.windows.1/Git-2.34.1-64-bit.exe"
Invoke-WebRequest -Uri $git_url  -OutFile git.exe
Start-Process -FilePath "git.exe" -ArgumentList " /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS" -Wait


# Install GitLab-runner
$runner_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe"
new-item GitLab-Runner -type directory
cd GitLab-Runner
Invoke-WebRequest -URI $runner_url -OutFile gitlab-runner.exe
.\gitlab-runner.exe install
.\gitlab-runner.exe start

# Configure image runner
.\gitlab-runner.exe register --run-untagged --non-interactive --url "http://43.154.150.20/" --registration-token "sjCzRqVb5WkTP_WJ6bpM" --executor "shell"

# Configure build-project runner
.\gitlab-runner.exe register --run-untagged --non-interactive --url "http://43.154.150.20/" --registration-token "HKYW6jq8Z7EroY_zqpLk" --executor "docker-windows" ----docker-pull-policy "if-not-present"
 
 
 

