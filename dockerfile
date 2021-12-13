# escape=`

# Use the latest Windows Server Core image with .NET Framework 4.8.
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

MAINTAINER websoft9

ENV SDK_NAME=pxc2021.0.tar.xz
ENV PLCN_PLUGIN_NAME=PLCnext-vs.msi
ENV PLCNCLI_NAME=PLCnCLI
ENV WORKDIR_NAME="C:\plcn\"

# Restore the default Windows shell for correct batch processing.
SHELL ["powershell", "-command"]

RUN mkdir C:\plcn

COPY plcn/* C:\plcn

WORKDIR C:\plcn\program
VOLUME ["C:\plcn\program\bin\AXCF2152_21.0.5.35585\Release"]

RUN cd C:\plcn\

# Install vs2019 and componets
RUN ./vs_Community.exe --installPath C:\minVS --add Microsoft.VisualStudio.Workload.CoreEditor --quiet --norestart
RUN ./vs_Community.exe modify --installPath C:\minVS --add Microsoft.VisualStudio.Workload.ManagedDesktop --quiet --norestart
RUN ./vs_Community.exe modify --installPath C:\minVS --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --quiet --norestart

# Set Env of msbuild
setx "path" "%path%C:\minVS\MSBuild\Current\bin\;"

# Install plcnext plugin for vs
RUN msiexec /i $PLCN_PLUGIN_NAME /quiet

# Install plcnext cli

# Set Env of plcnext cli
setx "path" "%path%C:\plcn\PLCnCLI"
plcncli install sdk -d C:\sdk -p $WORKDIR_NAME$SDK_NAME | Out-Null

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
