FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV STEAM_APPID=1874900

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        libstdc++6 \
        libxss1 \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libfontconfig1 \
        libxext6 \
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

# Download SteamCMD and set executable permissions
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar xvz && \
    chmod +x steamcmd.sh

# Create server directory
RUN mkdir -p /app/server && \
    mkdir -p /app/config && \
    mkdir -p /app/logs && \
    chown -R steam:steam /app

WORKDIR /app/server

# COPY entrypoint script
COPY --chown=steam:steam entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Health check - check if server process exists
HEALTHCHECK --interval=60s --timeout=10s --start-period=60s --retries=3 \
    CMD ps aux | grep -q "[A]rmaReforgerServer" || exit 1

# Expose ports
EXPOSE 2001/udp 17777/udp 19999/udp

USER steam

ENTRYPOINT ["/app/entrypoint.sh"]