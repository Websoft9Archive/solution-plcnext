# Use the latest Windows Server Core image with .NET Framework 4.8.
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

MAINTAINER websoft9

# Packages for build

ARG PLCNEXT_CLI=plcli.zip
ARG PLCNEXT_SDK=plsdk.tar.xz
ARG PLCNEXT_VS=plvs.msi

# You can set your VS directory
ENV VS_PATH C:\minVS

# Build destination directory
RUN New-Item C:\solution -type directory
#VOLUME ["C:\\solution"]

SHELL ["powershell", "-command"]

# Copy packages to workdir
RUN New-Item C:\plcnext -type directory
COPY packages\* C:\\plcnext

WORKDIR "C:\plcnext"

RUN ls

# Download Visual Studio 2019 community installer from Microsoft
RUN Invoke-WebRequest -URI https://aka.ms/vs/16/release/vs_community.exe -OutFile vs_community.exe

# Install all packages, e.g  Visual Studio, PLCNext CLI/SDK...
RUN ./vs_community.exe --installPath ${VS_PATH} --add Microsoft.VisualStudio.Workload.ManagedDesktop --quiet --norestart --nocache modify
RUN ./vs_community.exe modify --installPath ${VS_PATH} --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --quiet --norestart --nocache modify
RUN msiexec /i ${PLCNEXT_VS} /quiet
RUN Expand-Archive -Path ${PLCNEXT_CLI} -DestinationPath plcli
RUN setx "path" "%path%C:\plcnext\plcli\PLCnCLI;" && setx "path" "%path%${VS_PATH}\MSBuild\Current\bin\;"
RUN plcncli install sdk -d C:\sdk -p ${PLCNEXT_SDK} | Out-Null

# Define the entry point for the docker container.
ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
