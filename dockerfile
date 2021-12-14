# escape=`

# Use the latest Windows Server Core image with .NET Framework 4.8.
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

MAINTAINER websoft9

# Packages for build

ARG PLCNEXT_CLI=plcli.zip
ARG PLCNEXT_SDK=plsdk.tar.xz
ARG PLCNEXT_VS=plvs.msi

ENV VS_PATH "C:\minVS"
ENV VS_URL "https://aka.ms/vs/16/release/vs_community.exe" 

SHELL ["powershell", "-command"]

WORKDIR "C:\plcnext"
COPY packages\* C:\\plcnext\

VOLUME "C:\solution"

# Download Visual Studio
RUN Invoke-WebRequest -URI $env:VS_URL -OutFile vs.exe

# Install all packages, e.g  Visual Studio, PLCNext CLI/SDK...
RUN ./vs.exe --installPath ${VS_PATH} --add Microsoft.VisualStudio.Workload.ManagedDesktop --quiet --norestart --nocache modify
RUN ./vs.exe modify --installPath ${VS_PATH} --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --quiet --norestart --nocache modify
RUN Start-Process msiexec.exe -ArgumentList '/i', '$env:PLCNEXT_VS', '/quiet', '/norestart' -NoNewWindow -Wait
RUN Expand-Archive -Path $env:PLCNEXT_CLI -DestinationPath plcli
WORKDIR "C:\plcnext\plcli\PLCnCLI"
RUN ./plcncli.exe install sdk -d C:\sdk -p C:\plcnext\plsdk.tar.xz | Out-Null

ENV PATH C:\minVS\MSBuild\Current\bin:$PATH
ENV PATH C:\plcnext\plcli\PLCnCLI:$PATH

# Define the entry point for the docker container.
ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
