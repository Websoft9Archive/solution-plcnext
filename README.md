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
docker run -it --name containername tag:version -d
```

## 其他

```
# 删除未运行的容器
sudo docker rm $(sudo docker ps -a -q)
```
