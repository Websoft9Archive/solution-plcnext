# 菲尼克斯 PLCNext CI 文档

文档版本：v1.0  

更新时间：2021-12-22  

技术支持：help@websoft9.com  



## 需求

菲尼克斯（南京）某软件项目组 CI 需求主要包括两点：

* 镜像环境自动构建
* 工程自动编译

当前的工程基于 Visual Studio 2019 开发，每个工程在 Visual Studio 中以 Solution 的形式存在，每个 Solution 包 C# 和 C++ 两种开发语言组成的项目，其中 C ++ 项目引用了 C# 的编译结果。为了保证实现联动编译， Visual Studio 中安装了 PLCNext for VS 2019 插件，只需使用一个编译命令即可实现完整的编译目标。

```
msbuild IIoT_Library.sln
```

如果采用分步编译，主要的步骤如下：

```
msbuild IIoT_Library.csproj
plcncli build --path project -t AXCF2152
```

本项目的需求是实现一次联动编译。故，本项目的设计和实现均以一次编译为目标。

> MSBuild 是微软提供的编译解决方案。PLCNext 是菲尼克斯公司提供的开源物联网解决方案。  

## 设计

### 架构

![](E:\Develop\plcn\docs\images\architecture.png)



架构要点说明：

* 以 GitLab 作为远端项目源码仓库，GitLab-Runner 作为 CI 的调度器
* Windows 容器作为构建编译环境
* 容器镜像和项目编译均实现 CI

### 组件清单

经过实际调研和充分测试，编译环境清单如下：

1. 宿主机系统：Windows 2019 数据中心版（含Container）
2. Windows 容器镜像：mcr.microsoft.com/windows/servercore:ltsc2019
3. VS 环境：Visual Studio 2019 community +.NET 桌面工作负载 + C++ 桌面开发工作负载+Microsoft.VisualStudio.Component.VC.v141.x86.x64 组件
4. VS 插件：PLCnext Technology Development Tools for Visual Studio.msi for VS2019
5. PLCNext：PLC CLI 和 物联网设备 SDK（型号多个）

> PLCNext plugin  目前仅支持 VS2019



### Dockerfile

Dockerfile 的设计除了能够顺利安装组件清单之外，还需注意：

**灵活性**

1. 支持不同 Visual Studio 发行版（修改下载地址实现）
2. 支出安装多个不同型号的物联网设备 SDK

**简洁性**

1. 采用微软官方原生操作系统
2. 杜绝不必要的组件安装

### image-ci.yml

## msbuild.yml



## 用户手册

此处的用户指的是使用 CI 的开发者。

## 管理员手册

此处的管理员指的是维护本 CI 项目的开发者。  

管理员所需的操作包括：部署、配置、修改源码以及故障诊断

### 设置 GitLab CI/CD

### 部署 CI

1. 下载项目到 Windows 宿主机目录，例如：c:/plcnext

2. 以管理员身份的运行 Powershell 窗口，然后 CI 环境
   ```
   ./install.ps1
   ```
3. 等待安装环境结束（拉取 Windows Server 镜像需要大约20分钟时间）

3. 浏览器登录到 GitLab 后台，获取 GitLab token
![image](https://user-images.githubusercontent.com/43192516/147311858-71c78bda-662f-415c-9835-771daa85dd62.png)

4. 修改 Gitlab-Runner 的配置文件 `config.toml` 下面几项的值
![image](https://user-images.githubusercontent.com/43192516/147311341-06689f8c-e806-4a29-8f0b-7d133696a963.png)
   * url
   * token

5. 分别运行如下命令
   ```
   ./gitlab-runner.exe stop
   ./gitlab-runner.exe start
   ```
6. GitLab-Runner 会对远程的 GitLab 仓库进行一个注册动作，把自身 IP 写到 GitLab 中

### 镜像

镜像有关的说明：

#### 环境变量

* VS_URL：Visual Studio 微软官方的下载路径，例如："https://aka.ms/vs/16/release/vs_community.exe"   

> 16 代表 2019，17 代表 2022

#### Volume

镜像预设一个挂载目录：c:/solution

### 容器

与容器有关的命令包括：

```
# 创建容器
docker run -it --name containername -d -v path:c:\solution tag:version

# 编译项目
docker exec -it containername powershell msbuild c:\solution\IIoT_Library.sln

# 删除所有容器
docker rm -f $(docker ps -a -q)

# 清理镜像
docker image prune -f
```

### 修改


## 常见问题

#### 为什么需要安装 Visual Studio 2019 中的  C++ 桌面 工作负载？

如果没有安装它，编译的时候会提示缺少：Roslyn.Compiler 和 .net framework 4.0

#### 可以使用 Visual Studio 2022 吗？

当前不可以，因为 PLCnext Technology Development Tools for Visual Studio.msi 只支持 Visual Studio 2019

#### Gitlab-Runner 与 GitLab 的版本兼容性如何？

GitLab Runner 版本应与 GitLab 主要和次要版本保持同步。较老的跑步者可能仍然使用较新的 GitLab 版本，反之亦然。但是，如果存在版本差异，则功能可能不可用或无法正常工作。  

总之，尽量不断更新 Gitlab-Runner

#### 一个仓库是否可以对应多个同名 Runner?

不可以，会覆盖

## 参考文档

本项目的涉及多种技术，需要参考的文档包括：

1. [PLCNext 帮助文档](https://www.plcnext.help/)
2. [PLCnext cli 帮助文档](http://www.plcnext-runtime.com/ch01-04-installing-a-software-development-kit.html)
3. [PLCNext CLI 编译项目的步骤](https://github.com/PLCnext/CppExamples#compile-the-code-with-the-plcnext-cli)
4. [Visual Studio 帮助文档](https://docs.microsoft.com/zh-cn/visualstudio/get-started/visual-studio-ide)
5. [Visual Studio 命令式指南](https://docs.microsoft.com/en-us/visualstudio/ide/reference/command-prompt-powershell?view=vs-2019)
6. [VS 工作负载和组件ID查询](https://docs.microsoft.com/zh-cn/visualstudio/install/workload-component-id-vs-community)
7. [MSbuild 帮助文档](https://docs.microsoft.com/zh-cn/visualstudio/msbuild/msbuild)
8. [Dockerfile on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/manage-windows-dockerfile)
9. [MSbuild dockerfile  范例](https://docs.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2019) Install Build Tools into a container
10. [Windows Container](https://docs.microsoft.com/zh-cn/virtualization/windowscontainers/)  
11. [Install GitLab Runner on Windows](https://docs.gitlab.com/runner/install/windows.html)
12. [Gitlab CI 指南](https://docs.gitlab.com/ee/ci/introduction/index.html#continuous-integration)
