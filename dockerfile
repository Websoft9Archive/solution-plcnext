# escape=`

# https://hub.docker.com/_/microsoft-dotnet-framework-runtime/
# FROM mcr.microsoft.com/dotnet/framework/runtime:4.8
FROM mcr.microsoft.com/windows/servercore:ltsc2019

LABEL Description="CI for PLCNext" Vendor="Websoft9" Version="0.9"

# Packages for build

ARG PLCNEXT_CLI=PLCnCLI.zip
ARG PLCNEXT_VS=PLCnext-vs.msi
ARG VS_INSTALLATION_DIR=C:\minVS

ENV VS_URL "https://aka.ms/vs/16/release/vs_community.exe" 

SHELL ["powershell", "-Command"]

WORKDIR "C:\plcnext"
COPY packages\* C:\plcnext\

# Download Visual Studio
RUN Invoke-WebRequest -URI $env:VS_URL -OutFile vs.exe

# Install VS, PLCNext CLI
RUN `
    Start-Process vs.exe -ArgumentList '--installPath C:\minVS `
    --add Microsoft.Net.Component.4.TargetingPack `
    --add Microsoft.VisualStudio.Component.Roslyn.Compiler `
    --add Microsoft.VisualStudio.Component.VC.14.20.x86.x64 `
    --quiet --norestart' -wait -NoNewWindow

RUN Start-Process msiexec.exe -ArgumentList '/i', 'plvs.msi', '/quiet', '/norestart' -NoNewWindow -Wait
RUN Expand-Archive -Path $env:PLCNEXT_CLI -DestinationPath plcli

# Configure PLCNext cli ENV
RUN `
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine') ;`
    $newpath = $path + ';C:\plcnext\plcli\PLCnCLI\'; `
    [Environment]::SetEnvironmentVariable('Path', $newpath, 'Machine') ;`
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') 

# List all the sdk names
ENV SDK_LIST Get-ChildItem -Path C:\plcnext -Recurse -ErrorAction SilentlyContinue -Filter *.tar.xz 

# Install sdks
RUN Invoke-Command -ScriptBlock {plcncli install sdk -d C:\plcnext\sdk -p pxc-glibc-x86_64-mingw32-axcf2152-image-mingw-cortexa9t2hf-neon-axcf2152-toolchain-2021.0.tar.xz | Out-File C:\plcnext\installsdk.log}
RUN Invoke-Command -ScriptBlock  {plcncli install sdk -d C:\plcnext\sdk2 -p pxc-glibc-x86_64-mingw32-axcf2152-image-mingw-cortexa9t2hf-neon-axcf2152-toolchain-2021.6.tar.xz | Out-File C:\plcnext\installsdk.log}

VOLUME "C:\solution"

# Define the entry point for the docker container.
#ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
ENTRYPOINT  ". C:\minVS\Common7\Tools\Launch-VsDevShell.ps1;powershell"
