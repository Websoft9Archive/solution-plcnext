# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019

LABEL Description="CI for PLCNext" Vendor="Websoft9" Version="0.9"

# Packages for build
ARG VS_INSTALLATION_DIR=C:\minVS
ARG BASIC_DIR=C:\plcnext\
ARG VS_URL="https://aka.ms/vs/16/release/vs_community.exe" 

ENV MSBUILD_ENV_SET C:\\minVS\\Common7\\Tools\\Launch-VsDevShell.ps1

SHELL ["powershell", "-Command"]

WORKDIR ${BASIC_DIR}
COPY packages\* ${BASIC_DIR}

# Download Visual Studio
RUN Invoke-WebRequest -URI $env:VS_URL -OutFile vs.exe

# Install VS, PLCNext CLI
RUN `
    Start-Process vs.exe -ArgumentList "--installPath", "$env:VS_INSTALLATION_DIR", `
    "--add", "Microsoft.Net.Component.4.TargetingPack", `
    "--add", "Microsoft.VisualStudio.Component.Roslyn.Compiler", `
    "--add", "Microsoft.VisualStudio.Component.VC.14.20.x86.x64", `
    "--quiet", "--norestart" -wait -NoNewWindow

# Get the file of msi, and install it
RUN `
    $plugin = Get-ChildItem -Name -Filter *.msi;`
    Start-Process $plugin -ArgumentList "/quiet" -wait

# Get the file of plcncli, and unzip it
RUN `
    $cli = Get-ChildItem -Name -Filter *.zip;`
    Expand-Archive -Path $cli -DestinationPath plcncli

# Configure PLCNext cli ENV
RUN `
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine') ;`
    $newpath = $path + ';' + $env:BASIC_DIR + 'plcncli\PLCnCLI\'; `
    [Environment]::SetEnvironmentVariable('Path', $newpath, 'Machine') ;`
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') 

# Install package's all SDKS
RUN `
    Invoke-Command -ScriptBlock {`
    new-item -name sdks -type directory;`
    $SDK_LIST= Get-ChildItem -Name -Filter *.xz;`
    foreach ($file in $SDK_LIST){ `
        $sdkname=$file.Split("'-'")[4];`
        new-item  -path .\sdks -name $sdkname -type directory;`
        $version=$file.Split("'-'")[$file.Split("'-'").length-1].Split("'.tar.xz'")[0];`
        plcncli install sdk -d .\sdks\$sdkname\$version -p $file | Out-File .\installsdk.log;`
    }`
  }

# Delete install files, image size optimization
RUN Remove-Item *.zip,*.msi,*.xz,*.exe

VOLUME "C:\solution"

# Define the entry point for the docker container
ENTRYPOINT ["powershell.exe", "-NoExit", "-ExecutionPolicy", "ByPass", ".  $env:MSBUILD_ENV_SET;& echo 'msbuild env configure success'"]
