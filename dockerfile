# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019

MAINTAINER websoft9

# Packages for build

ARG PLCNEXT_CLI=plcli.zip
ARG PLCNEXT_SDK=plsdk.tar.xz
ARG PLCNEXT_VS=plvs.msi

ENV VS_URL "https://aka.ms/vs/16/release/vs_community.exe" 

SHELL ["powershell", "-Command"]

WORKDIR "C:\plcnext"
COPY packages\* C:\\plcnext\

# Download Visual Studio
RUN Invoke-WebRequest -URI $env:VS_URL -OutFile vs.exe

# Install all packages, e.g  Visual Studio, PLCNext CLI/SDK...
RUN Start-Process vs.exe -ArgumentList '--installPath C:\minVS --add Microsoft.VisualStudio.Workload.CoreEditor --quiet --norestart' -wait -NoNewWindow
RUN Start-Process vs.exe -ArgumentList 'modify --installPath C:\minVS --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --quiet --norestart' -wait -NoNewWindow
RUN Start-Process msiexec.exe -ArgumentList '/i', '$env:PLCNEXT_VS', '/quiet', '/norestart' -NoNewWindow -Wait

RUN Expand-Archive -Path $env:PLCNEXT_CLI -DestinationPath plcli

#RUN setx "path" "%path%C:\plcnext\plcli\PLCnCLI;" 
#RUN setx "path" "%path%${VS_PATH}\MSBuild\Current\bin\;"
#RUN plcncli install sdk -d C:\sdk -p ${PLCNEXT_SDK} | Out-Null

VOLUME "C:\solution"

# Define the entry point for the docker container.
ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
