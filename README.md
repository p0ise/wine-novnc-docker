# Wine noVNC Docker 基础镜像

该项目提供了一个 Docker 基础镜像，用于在浏览器中通过 noVNC 访问虚拟桌面运行 Windows 应用程序。项目集成了 Wine、VNC 和 noVNC，并使用模块化的 Supervisor 管理多个服务。该镜像非常适合作为基础镜像，用户可在其上添加自定义应用程序。

## 项目特性

- **Wine**: 支持运行 Windows 应用程序。
- **noVNC**: 通过 WebSocket 提供浏览器访问 VNC 虚拟桌面。
- **x11vnc**: 提供 VNC 虚拟桌面服务。
- **Fluxbox**: 轻量级、开箱即用的窗口管理器。
- **xterm**: 简单、轻量的终端工具，方便用户在桌面环境中使用命令行。
- **Supervisor**: 管理和监控多进程服务，采用模块化配置，易于扩展和自定义。

## 快速开始

### 获取镜像

从 Docker Hub 拉取基础镜像：

```bash
docker pull invelop/wine-novnc:latest
```

或者克隆本仓库并构建镜像：

```bash
git clone https://github.com/p0ise/wine-novnc-docker.git
cd wine-novnc-docker
docker build -t invelop/wine-novnc .
```

### 运行容器并设置 VNC 密码

此镜像支持通过 `VNC_PASSWORD` 环境变量设置自定义 VNC 密码，同时支持自动生成随机密码的逻辑：

- **自定义密码**：如果在启动容器时传入 `VNC_PASSWORD` 环境变量，则该密码将作为 VNC 密码，无论密码文件是否已存在。
- **自动生成密码**：如果未提供 `VNC_PASSWORD` 且容器没有现有密码文件，启动时将自动生成一个随机密码并显示在控制台。
- **保留现有密码**：如果容器内已有密码文件且未传入 `VNC_PASSWORD`，则使用现有密码，不会覆盖。

#### 设置自定义密码的示例

```bash
docker run -p 6080:6080 -p 5901:5901 -e VNC_PASSWORD=my_custom_password invelop/wine-novnc
```

#### 自动生成密码的示例

如果未设置 `VNC_PASSWORD` 且没有现有密码文件，容器将生成一个随机密码并显示在控制台：

```bash
docker run -p 6080:6080 -p 5901:5901 invelop/wine-novnc
```

### 访问 noVNC 界面

打开浏览器，访问 `http://localhost:6080`，在提示框中输入 VNC 密码，即可访问虚拟桌面并运行 Windows 应用。

## 环境变量

以下环境变量在 Dockerfile 中进行配置，以确保 VNC 和 noVNC 的端口一致性：

- `VNC_PORT`：VNC 服务端口，默认 `5901`。
- `NOVNC_PORT`：noVNC WebSocket 端口，默认 `6080`。

## 文件结构

项目的主要文件包括：

- `Dockerfile`：定义镜像构建步骤，配置 Wine、VNC、noVNC 及其他依赖。
- `supervisord.conf`：主 `supervisor` 配置文件，包含基本设置并引入模块化配置。
- `supervisor/conf.d/`：包含各服务的独立 `supervisor` 配置文件：
  - `xvfb.conf`：配置 Xvfb 虚拟显示服务。
  - `x11vnc.conf`：配置 x11vnc VNC 服务。
  - `fluxbox.conf`：配置 Fluxbox 窗口管理器。
  - `novnc.conf`：配置 noVNC 服务。
- `startup.sh`：启动脚本，用于设置 VNC 密码并启动 `supervisord` 管理服务。
- `download_gecko_and_mono.sh`：下载并配置 Wine 的 Gecko 和 Mono 支持文件，确保 Wine 的完整运行环境。

## 自定义应用配置

该镜像提供 `/app` 目录，便于用户挂载和自定义应用。可以在 `supervisor` 的模块化配置目录 `conf.d/` 中添加应用的配置文件，以便在镜像启动时运行自定义应用。

### 示例：基于此基础镜像构建自定义应用

以下示例展示如何在基础镜像上添加自定义的 Windows 应用 `my-windows-app`：

#### 自定义应用的 `Dockerfile`

```Dockerfile
# 基于 wine-novnc 基础镜像
FROM invelop/wine-novnc

# 复制应用到 /app 目录
COPY my-windows-app /app/my-windows-app

# 添加应用的 Supervisor 配置文件
COPY myapp-supervisor.conf /etc/supervisor/conf.d/myapp.conf

# 设置工作目录
WORKDIR /app

# 继续使用基础镜像的 ENTRYPOINT
CMD []
```

#### `myapp-supervisor.conf` 配置

通过 `supervisor` 启动应用的配置示例：

```ini
[program:myapp]
command=wine /app/my-windows-app/myapp.exe
autostart=true
autorestart=true
priority=50
stdout_logfile=/var/log/supervisord/myapp.log
stderr_logfile=/var/log/supervisord/myapp_error.log
```

#### 构建和运行自定义应用镜像

1. **构建镜像**：

   ```bash
   docker build -t my-custom-app .
   ```

2. **运行容器**：

   ```bash
   docker run -p 6080:6080 -p 5901:5901 my-custom-app
   ```

在浏览器中访问 `http://localhost:6080`，即可看到 `Fluxbox` 桌面环境，并确认 `my-windows-app` 已启动。

## 日志文件

所有服务的日志文件存储在 `/var/log/supervisord` 目录下，便于监控和调试：

- `supervisord.log`：Supervisor 全局日志文件，记录 supervisord 本身的运行信息。
- `xvfb.log`：记录 Xvfb 服务的日志，虚拟显示的运行状态。
- `x11vnc.log`：记录 x11vnc 服务的日志，提供 VNC 访问信息。
- `novnc.log`：记录 noVNC 服务的日志，提供 WebSocket 连接日志。
- `fluxbox.log`：记录 Fluxbox 窗口管理器的日志。
- `myapp.log`：记录自定义应用的日志（根据 `myapp-supervisor.conf` 配置文件）。

可以通过检查这些日志文件来诊断和监控各个服务的状态。

## 贡献

欢迎提交 Issue 和 Pull Request，帮助改进项目。

## 许可证

本项目采用 MIT 许可证开源，详情请参阅 `LICENSE` 文件。
