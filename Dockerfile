# Use the latest Ubuntu base image
FROM docker.io/ubuntu:latest

# Set noninteractive to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install all necessary packages, including dos2unix, in one layer
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    binutils wget ca-certificates tini gpg openbox \
    python3-pip python3-venv git \
    libwebkit2gtk-4.1-0 policykit-1 \
    dos2unix && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install the .deb package in one layer
RUN wget -q -O /tmp/uprockmining.deb https://edge.uprock.com/v1/app-download/UpRock-Mining-v0.0.10.deb && \
    dpkg -i /tmp/uprockmining.deb && \
    apt-get update -y && \
    apt-get install -y --fix-broken --no-install-recommends --no-install-suggests && \
    rm /tmp/uprockmining.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create virtual environment and install websockify in one layer
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir websockify

# Update CA certificates
RUN update-ca-certificates

# Clone noVNC in a single command
RUN git clone https://github.com/novnc/noVNC.git /noVNC

# Install TurboVNC, combining repository setup and installation
RUN wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor > /etc/apt/trusted.gpg.d/TurboVNC.gpg && \
    wget -q -O /etc/apt/sources.list.d/turbovnc.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --no-install-suggests turbovnc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Remove unnecessary packages
RUN apt-get purge -y wget gpg && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy startup script to /root/, convert line endings, and set executable permissions
COPY start.sh /root/start.sh
RUN dos2unix /root/start.sh && \
    chmod +x /root/start.sh

# Expose necessary ports
EXPOSE 5900 6080

# Set tini as entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "/root/start.sh"]
