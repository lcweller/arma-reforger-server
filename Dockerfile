FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV STEAM_APPID=1874900

# Enable 32-bit architecture support for SteamCMD
RUN dpkg --add-architecture i386

# Install dependencies including 32-bit libraries for SteamCMD
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libstdc++6 \
        libstdc++6:i386 \
        libgl1:i386 \
        libc6:i386 \
        libxext6:i386 \
        libx11-6:i386 \
        libglib2.0-0:i386 \
        procps \
        jq \
        gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create steam user
RUN useradd -m -u 1000 steam && \
    mkdir -p /home/steam/steamcmd && \
    chown -R steam:steam /home/steam

WORKDIR /home/steam/steamcmd

# Download SteamCMD and set executable permissions on all files
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar xvz && \
    chmod -R +x . && \
    chmod -R u+w . && \
    chown -R steam:steam /home/steam/steamcmd

# Create server directory with proper permissions
RUN mkdir -p /app/data/server && \
    mkdir -p /app/data/config && \
    mkdir -p /app/data/logs && \
    mkdir -p /app/defaults && \
    chmod -R 755 /app && \
    chmod -R u+w /app

WORKDIR /app/data/server

# COPY entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
COPY config/config.json /app/defaults/config.json
RUN chmod +x /app/entrypoint.sh

# Health check - ensure the managed runtime-config game server process is present.
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=5 \
    CMD ps -eo args | grep -E '^\./ArmaReforgerServer .* -config /app/data/config/config.runtime.json' >/dev/null || exit 1

# Expose ports
EXPOSE 2001/udp 17777/udp 19999/udp

ENTRYPOINT ["/app/entrypoint.sh"]