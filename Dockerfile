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
        wget \
        libstdc++6 \
        libstdc++6:i386 \
        libgl1:i386 \
        libc6:i386 \
        libxext6:i386 \
        libx11-6:i386 \
        libglib2.0-0:i386 \
        net-tools \
        procps \
        htop \
        nano \
        jq && \
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
RUN mkdir -p /app/server && \
    mkdir -p /app/config && \
    mkdir -p /app/logs && \
    chmod -R 755 /app && \
    chmod -R u+w /app

WORKDIR /app/server

# COPY entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Health check - check if server process exists
HEALTHCHECK --interval=60s --timeout=10s --start-period=60s --retries=3 \
    CMD ps aux | grep -q "[A]rmaReforgerServer" || exit 1

# Expose ports
EXPOSE 2001/udp 17777/udp 19999/udp

ENTRYPOINT ["/app/entrypoint.sh"]