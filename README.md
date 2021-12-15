# plcn

## 环境变量

#### VS_PATH

Visual Studio 在镜像中的安装路径，例如："C:\minVS"   

#### VS_URL

Visual Studio 微软官方的下载路径，例如："https://aka.ms/vs/16/release/vs_community.exe"   

> VS2019 Community

## Volume

目前预设一个挂载目录：c:/solution

## 运行容器

```
docker run -it --name containername -d -v path:c:\solution tag:version
docker exec -it cdl powershell msbuild c:\solution\IIoT_Library.sln
```

## 其他

```
# 删除所有容器
docker rm -f $(docker ps -a -q)

# 清理镜像
docker image prune -f
```
