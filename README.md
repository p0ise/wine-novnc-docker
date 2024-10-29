# Wine noVNC Docker 镜像

该项目提供了一个 Docker 镜像，用于在浏览器中通过 noVNC 访问虚拟桌面运行 Windows 应用程序。项目集成了 Wine、VNC 和 noVNC，并使用 Supervisor 管理多个服务。

## 项目特性

- **Wine**: 支持运行 Windows 应用程序。
- **noVNC**: 通过 WebSocket 提供浏览器访问 VNC 虚拟桌面。
- **x11vnc**: 提供 VNC 虚拟桌面服务。
- **Openbox**: 轻量级窗口管理器。
- **Supervisor**: 管理和监控多进程服务。

## 快速开始

### 获取镜像

从 Docker Hub 拉取镜像：

```bash
docker pull invelop/wine-novnc:latest
```

或者克隆本仓库并构建镜像：

```bash
git clone https://github.com/p0ise/wine-novnc-docker.git
cd wine-novnc-docker
DOCKER_BUILDKIT=1 docker build --secret id=vnc_password,src=./vnc_password.txt -t wine-novnc .
```

### 运行容器

```bash
docker run -p 6080:6080 -p 5901:5901 --secret id=vnc_password,src=./vnc_password.txt wine-novnc
```

这将启动容器并将 noVNC 映射到本地的 `6080` 端口，VNC 映射到 `5901` 端口。

### 访问 noVNC 界面

打开浏览器，访问 `http://localhost:6080`，在提示框中输入 VNC 密码，即可访问虚拟桌面并运行 Windows 应用。

## 安全设置

为了确保安全，VNC 密码在构建时通过 Docker BuildKit 的秘密挂载方式注入，而不是通过 Dockerfile 的 `ENV` 设置。确保已配置秘密文件 `vnc_password.txt`，其中包含 VNC 密码：

```plaintext
your_secure_vnc_password
```

### 启用 BuildKit 和秘密挂载

在使用 BuildKit 构建时，通过以下命令指定秘密文件：

```bash
DOCKER_BUILDKIT=1 docker build --secret id=vnc_password,src=./vnc_password.txt -t wine-novnc .
```

并在运行容器时使用相同的秘密文件：

```bash
docker run -p 6080:6080 -p 5901:5901 --secret id=vnc_password,src=./vnc_password.txt wine-novnc
```

## 环境变量

以下环境变量在 Dockerfile 中进行配置，以确保 VNC 和 noVNC 的端口一致性：

- `VNC_PORT`：VNC 服务端口，默认 `5901`。
- `NOVNC_PORT`：noVNC WebSocket 端口，默认 `6080`。

## 文件结构

项目的主要文件包括：

- `Dockerfile`：定义镜像构建步骤，配置 Wine、VNC、noVNC 及其他依赖。
- `supervisord.conf`：配置 supervisord，管理和监控多个服务进程。
- `openbox-autostart.sh`：用于自定义 Openbox 启动时运行的应用程序。
- `download_gecko_and_mono.sh`：下载并配置 Wine 的 Gecko 和 Mono 支持文件，确保 Wine 的完整运行环境。
- `vnc_password.txt`：包含 VNC 密码的文件，通过 Docker BuildKit 的秘密挂载功能在构建和运行时注入。

## 自定义配置

您可以在 `openbox-autostart.sh` 中自定义启动时运行的应用程序。例如，可以在 Openbox 启动时通过 Wine 运行特定的 Windows 应用：

```bash
# openbox-autostart.sh
wine /path/to/your/windows-app.exe
```

## 日志文件

所有服务的日志文件存储在 `/var/log/supervisord` 目录下，便于监控和调试：

- `supervisord.log`：Supervisor 全局日志文件，记录 supervisord 本身的运行信息。
- `xvfb.log`：记录 Xvfb 服务的日志，虚拟显示的运行状态。
- `x11vnc.log`：记录 x11vnc 服务的日志，提供 VNC 访问信息。
- `novnc.log`：记录 noVNC 服务的日志，提供 WebSocket 连接日志。
- `openbox.log`：记录 Openbox 窗口管理器的日志。

可以通过检查这些日志文件来诊断和监控各个服务的状态。

## 贡献

欢迎提交 Issue 和 Pull Request，帮助改进项目。

## 许可证

本项目采用 MIT 许可证开源，详情请参阅 `LICENSE` 文件。
