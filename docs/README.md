# 菲尼克斯 PLCNext CI 文档

文档版本：v1.0  

更新时间：2021-12-24  

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

### 整体架构

![](https://libs.websoft9.com/Websoft9/DocsPicture/zh/gitlab/gitlab-plcnextciarchitecture-websoft9.png)



架构要点说明：

* 以 GitLab 作为远端项目源码仓库，GitLab-Runner 作为 CI 的调度器

* Windows 容器作为构建编译环境

* 容器镜像和项目编译均实现 CI

  

架构实施说明：

* GitLab-Runner 与 编译环境同在一台主机上

* .gitlab-ci.yml 作为项目仓库的组成部分

* 镜像环境的依赖包和编译结果包采用更合理的存放方式

  

### 编译环境

由于本项目采用 Window 容器作为编译环境，因此编译环境的设计工作主要围绕 Dockerfile 进行。

#### 环境清单

经过实际调研和充分测试，编译环境所需的清单如下：

1. 宿主机系统：Windows 2019 数据中心版（含Container）
2. Windows 容器镜像：mcr.microsoft.com/windows/servercore:ltsc2019
3. VS 环境：Visual Studio 2019 community +.NET 桌面工作负载 + C++ 桌面开发工作负载+Microsoft.VisualStudio.Component.VC.v141.x86.x64 组件
4. VS 插件：PLCnext Technology Development Tools for Visual Studio.msi for VS2019
5. PLCNext：PLC CLI 和 物联网设备 SDK（型号多个）

> PLCNext plugin  目前仅支持 VS2019

#### Dockerfile

##### 设计原则
Dockerfile 的设计除了能够顺利实现应用功能之外，还需注意：

**灵活性**

1. 支持不同 Visual Studio 发行版（修改下载地址实现）
2. 支出安装多个不同型号的物联网设备 SDK
3. 支持任意的Visual Studio插件名和cli名

**简洁性**

1. 采用微软官方原生操作系统
2. 杜绝不必要的组件安装

**可维护**

1. 组件升级
2. 组件修改

##### 使用说明

Dockerfile的常用基本指令说明如下：

  - FROM <image> 指定一个构建镜像的基础源镜像

  - MAINTAINER <name> <email> <version> 指定作者和版本等维护信息

3. RUN "command" "param1" "param2" 在镜像中执行脚本命令，例如powershell脚本命令

4. EVN <key> <value> 设置容器的环境变量，可以让其后面的RUN命令使用

docker run -it -e MSBUILD_ENV_SET="C:\VisualStudi2019\Common7\Tools\Launch-VsDevShell.ps1" plcn

5. ARG <key>=<value> 设置容器的变量，在build镜像时起作用

build -t plcn:latest --build-arg VS_INSTALLATION_DIR="C:\VisualStudi2019" .

6. COPY <src> <dest>  COPY复制文件到镜像，支持模糊匹配。

7. ADD  <src> <dest> 和COPY功能类似，同时会自动解压缩。

8. VOLUME ["path"] 在主机上创建一个挂载，挂载到容器的指定路径。docker run -v命令也能完成这个操作，而且更强大。

9. WORKDIR path 配置工作目录，同时切换到该目录。可以使用多个WORKDIR指令，后续参数如果是相对路径，则会基于之前的命令指定的路径

10. ENTRYPOINT
为了保证容器能够持续运行，ENTRYPOINT启动进程需要是一个常驻进程，否则容器会运行后立即退出。它有两种模式：
shell模式
ENTRYPOINT ["Invoke-Expression $env:MSBUILD_ENV_SET;powershell.exe -NoExit -ExecutionPolicy ByPass"]

exec模式
ENTRYPOINT ["powershell.exe", "Invoke-Expression", "$env:MSBUILD_ENV_SET", ";", "powershell.exe", "-NoExit", "-ExecutionPolicy", "ByPass"]

11. EXPOSE <port> [<port>...]  Docker服务器容器对外映射的容器端口号


#### 环境维护

镜像构建和项目编译后，都会产生一些中间结果文件：

* 多个可用的镜像版本
* 失败的镜像
* 不需要的容器持久化存储文件
* 一次性中间容器
* 项目编译缓存：拉取的项目、临时文件、编译结果

这些不需要的文件，需考虑及时清理。  

另外，环境中的组件要提供便捷的升级方案。  

### 触发机制

自动化CI的触发条件需满足客户的开发流程。本项目当前的触发条件为：  

* 镜像构建触发：修改 .gitlab-ci.yml 或 更新包
* 项目编译触发：修改 .gitlab-ci.yml 或 开发者Commit 代码到指定的分子（例如：Dev）

另外，目前要求支持所有分支的触发（GitLab CI 默认支持所有分支）
   
###  CI jobs

本项目的 CI jobs主要通过  .gitlab-ci.yml 编排文件实现。  

GitLab CI 编排的文件原理：多个 Job 组成，每个 Job 需设置其 Stage 的值（build, test, deploy等）以及触发条件。  

每次项目提交的适合，Runner 会将 .gitlab-ci.yml 中的 Jobs 启动到流水线中开始运作。  

下面是一个 .gitlab-ci.yml 文件模板：  

```
image-job:
  stage: build
  only:
    changes:
      - docker/*
  script:
    - echo "build Image start"
    - cd docker
    - docker build -t plcn .
    - echo "build image success!"

solution-job:
  stage: build
  only:
    - main
  script:
    - echo "build sln start"
    - docker rm -f plcn
    - docker run -it --rm -d --name plcn -v "$(pwd):C:\solution" plcn
    - docker exec plcn powershell C:\minVS\MSBuild\Current\bin\MSbuild.exe c:\solution\IIoT_Library.sln
    - echo "MSbuild vsproject success!"

test-job:
  stage: test
  script:
    - echo "test"

deploy-job:
  stage: deploy
  script:
    - echo "deploy"
```

> 如果一个仓库关联一个 Runner 的注册实例（多个标签），则 job 中还需定义 runner 的 tag


## 用户手册

此处的用户指的是使用 CI 的开发者。

## 管理员手册

此处的管理员指的是维护本 CI 项目的开发者。  

管理员所需的操作包括：部署、配置、修改源码以及故障诊断

### 设置 GitLab CI/CD

GitLab CI/CI 支持：全局级（ [shared runners](https://docs.gitlab.com/ee/ci/runners/runners_scope.html)）、仓库级、用户组等作用域模式。  

本项目中我们使用仓库级作用域的模式，即给 GitLab 指定的仓库配置 CI/CD 

### 部署 CI

1. 下载项目到 Windows 宿主机目录，例如：c:/plcnext

2. 以管理员身份的运行 Powershell 窗口，然后 CI 环境
   ```
   ./install.ps1
   ```
3. 等待安装环境结束（拉取 Windows Server 镜像需要大约20分钟时间）

4. 浏览器登录到 GitLab 后台，获取 GitLab token
   ![](https://libs.websoft9.com/Websoft9/DocsPicture/zh/gitlab/gitlab-gettokenci-websoft9.png)

5. 修改 Gitlab-Runner 的配置文件 `runner-config.ps1` 下面几项的值

   * url
   * registration-toke

6. 运行如下命令启动 GitLab-Runner
   ```
   ./runner-config.ps1
   ```


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

#### Runner 配置文件中如何支持多个仓库？

每增加一个仓库就需要 Register 一次，下面是两个仓库的配置文件

#### Gitlab-runner start 看起来正常，但状态仍然为 stopeed？

最常见的原因：配置文件中有语法错误

#### executors 选择 docker 模式下，镜像如何引入，能否引入本地镜像？

有三种镜像引入的方式：

1. runner 级
2. 流水线级（所有 job 均可以使用）
3. job级

runner默认配置是从外部仓库pull镜像，如果能从本地获取镜像，需要runner的config.toml加入如下配置：
```
  [runners.docker]
    pull_policy = ["if-not-present"]
```
#### Dockerfile 中ENTRYPOINT 如何通过exec模式调用powershell.exe执行脚本？

ENTRYPOINT定义容器启动的程序或脚本，[ENTRYPOINT有两种方式](https://docs.docker.com/engine/reference/builder/)

ENTRYPOINT的exec模式需要跟一个活动进程，如果是一个执行后就退出的程序，需要使其成为常驻进程：
```
ENTRYPOINT ["powershell.exe", "-NoExit", "-ExecutionPolicy", "ByPass", '"$env:VS_INSTALLATION_DIR"Common7\\Tools\\Launch-VsDevShell.ps1;&']
```

#### GitLab 仓库后台显示 Runner正常运行，但仍然无法启动流水线？

如果 runner 向同一个仓库注册多次（产生了多个流水线），则 job 默认无法确认对应哪个流水线，需在 Job 编排文件中增加

```
job:
  tags:
    - ruby
    - postgres
```

#### Runner 的标准配置范例

```
concurrent = 5
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "image"
  url = "http://43.154.150.20/"
  token = "s7hKy7ZRFj4Txh_a1_3r"
  executor = "shell"
  shell = "powershell"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]

[[runners]]
  name = "Build"
  url = "http://43.154.150.20/"
  token = "GaitpV8iZJFUA2zktXFh"
  executor = "docker-windows"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    pull_policy = ["if-not-present"]
    tls_verify = false
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["c:\\cache"]
    shm_size = 0
```

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
13. [Gitlab CI 文件语法](https://docs.gitlab.com/ee/ci/yaml/)
14. [PowerShell.exe 语法](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1)
