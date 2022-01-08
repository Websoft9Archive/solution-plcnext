# Configure image runner
.\gitlab-runner.exe register --run-untagged --non-interactive --url "http://43.154.150.20/" --registration-token "sjCzRqVb5WkTP_WJ6bpM" --executor "shell" --shell "powershell"

# Configure build-project runner
.\gitlab-runner.exe register --run-untagged --non-interactive --url "http://43.154.150.20/" --registration-token "HKYW6jq8Z7EroY_zqpLk" --executor "docker-windows"  --shell "powershell"--docker-image "plcn" --docker-pull-policy "if-not-present"

.\gitlab-runner.exe restart
