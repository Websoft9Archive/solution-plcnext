# Install GitLab-runner
$runner_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe"
cd GitLab-Runner
.\gitlab-runner.exe stop

Invoke-WebRequest -URI $runner_url -OutFile gitlab-runner.exe
.\gitlab-runner.exe start