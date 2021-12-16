# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019

LABEL Description="CI for PLCNext" Vendor="Websoft9" Version="0.5"

# Packages for build

ARG PLCNEXT_CLI=plcli.zip
ARG PLCNEXT_SDK=plsdk.tar.xz
ARG PLCNEXT_VS=plvs.msi

# 16 for vs2019, 17 for vs2022
ENV VS_URL "https://aka.ms/vs/16/release/vs_community.exe" 

SHELL ["powershell", "-Command"]

WORKDIR "C:\plcnext"
COPY packages\* C:\plcnext\

# Download Visual Studio
RUN Invoke-WebRequest -URI $env:VS_URL -OutFile vs.exe

# Install VS, PLCNext CLI
RUN `
    Start-Process vs.exe -ArgumentList '--installPath C:\minVS `
    --add Microsoft.VisualStudio.Workload.ManagedDesktop `
    --add Microsoft.VisualStudio.Workload.NativeDesktop `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --quiet --norestart' -wait -NoNewWindow

RUN Start-Process msiexec.exe -ArgumentList '/i', 'plvs.msi', '/quiet', '/norestart' -NoNewWindow -Wait
RUN Expand-Archive -Path $env:PLCNEXT_CLI -DestinationPath plcli

# Configure ENV
RUN `
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine') ;`
    $newpath = $path + ';C:\plcnext\plcli\PLCnCLI\'; `
    [Environment]::SetEnvironmentVariable('Path', $newpath, 'Machine') ;`
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') 

# Install SDK
RUN plcncli install sdk -d C:\plcnext\sdk -p $env:PLCNEXT_SDK | Out-Null

VOLUME "C:\solution"

# Define the entry point for the docker container.
ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
