# 使用 Ubuntu 22.04 基础镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NOVNC_PORT=6080

# 配置 i386 架构并添加 WineHQ 源、安装所需依赖和工具，清理缓存
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common wget curl supervisor x11vnc xvfb xterm fluxbox python3 ca-certificates && \
    . /etc/os-release && CODENAME=${UBUNTU_CODENAME:-${VERSION_CODENAME}} && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -q -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -q -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/${CODENAME}/winehq-${CODENAME}.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 安装 winetricks
RUN wget -q -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/bin/winetricks

# 复制并执行下载 Gecko 和 Mono 的脚本
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN chmod +x /root/download_gecko_and_mono.sh && \
    /root/download_gecko_and_mono.sh "$(wine --version | sed -E 's/^wine-//')" && \
    rm -f /root/download_gecko_and_mono.sh

# 安装 noVNC 和 websockify
RUN mkdir -p /opt/novnc/utils/websockify && \
    curl -sL https://github.com/novnc/noVNC/archive/v1.5.0.tar.gz | tar xz -C /opt/novnc --strip-components=1 && \
    curl -sL https://github.com/novnc/websockify/archive/v0.12.0.tar.gz | tar xz -C /opt/novnc/utils/websockify --strip-components=1

# 创建 VNC 密码文件，使用 BuildKit 秘密挂载
RUN --mount=type=secret,id=vnc_password \
    mkdir -p /root/.vnc && \
    x11vnc -storepasswd $(cat /run/secrets/vnc_password) /root/.vnc/passwd

# 创建 supervisor 配置目录和日志目录并复制独立配置文件
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisord
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/conf.d/* /etc/supervisor/conf.d/


# 暴露端口
EXPOSE ${VNC_PORT} ${NOVNC_PORT}

# 启动 supervisord
CMD ["sh", "-c", "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf"]
