# escape=`

# https://hub.docker.com/_/microsoft-dotnet-framework-runtime/
# FROM mcr.microsoft.com/dotnet/framework/runtime:4.8
FROM mcr.microsoft.com/windows/servercore:ltsc2019

LABEL Description="CI for PLCNext" Vendor="Websoft9" Version="0.9"

# Packages for build

ARG PLCNEXT_CLI=PLCnCLI.zip
ARG PLCNEXT_VS=PLCnext-vs.msi
ARG VS_INSTALLATION_DIR=C:\minVS
ARG BASIC_DIR=C:\plcnext\

ENV VS_URL "https://aka.ms/vs/16/release/vs_community.exe" 

SHELL ["powershell", "-Command"]

WORKDIR ${BASIC_DIR}
COPY packages\* ${BASIC_DIR}

# Download Visual Studio
RUN Invoke-WebRequest -URI $env:VS_URL -OutFile vs.exe

# There is space in msi file name, rename file to support it
RUN get-childItem *.msi  | rename-item -newname $env:PLCNEXT_VS

# Install VS, PLCNext CLI
RUN `
    Start-Process vs.exe -ArgumentList "--installPath", "$env:VS_INSTALLATION_DIR", `
    "--add", "Microsoft.Net.Component.4.TargetingPack", `
    "--add", "Microsoft.VisualStudio.Component.Roslyn.Compiler", `
    "--add", "Microsoft.VisualStudio.Component.VC.14.20.x86.x64", `
    "--quiet", "--norestart" -wait -NoNewWindow

RUN Start-Process msiexec.exe -ArgumentList '/i', $env:PLCNEXT_VS, '/quiet', '/norestart' -NoNewWindow -Wait
RUN Expand-Archive -Path $env:PLCNEXT_CLI -DestinationPath plcli

# Configure PLCNext cli ENV
RUN `
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine') ;`
    $newpath = $path + ';C:\plcnext\plcli\PLCnCLI\'; `
    [Environment]::SetEnvironmentVariable('Path', $newpath, 'Machine') ;`
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') 

# Create SDKS Directory
RUN new-item -path $env:BASIC_DIR -name sdks -type directory

# Install package's all SDKS
RUN `
    Invoke-Command -ScriptBlock {`
    $SDK_LIST= Get-ChildItem -Path C:\plcnext\ -Name  -Filter *.xz;`
    foreach ($file in $SDK_LIST){ `
        plcncli install sdk -d C:\plcnext\sdks\$file -p $file | Out-File C:\plcnext\installsdk.log`
    }`
  }


# Delete install files, image size optimization
RUN Remove-Item * -Include *.zip
RUN Remove-Item * -Include *.msi
RUN Remove-Item * -Include *.xz
RUN Remove-Item * -Include *.exe

VOLUME "C:\solution"

# Define the entry point for the docker container.
#ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
ENTRYPOINT  ". C:\minVS\Common7\Tools\Launch-VsDevShell.ps1;powershell"

