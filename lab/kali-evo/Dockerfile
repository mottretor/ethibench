# Clean Kali box for EvoPentester: the ESO (Python, uv) and the ACI (Node) both run here.
FROM pentest-lab/kali:latest

ENV DEBIAN_FRONTEND=noninteractive

# Node (>=20) for the ACI, plus the tools its skills expect on top of the base image.
RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs npm sudo tmux build-essential \
        sshpass exploitdb john hashcat wpscan dnsrecon onesixtyone \
        smtp-user-enum enum4linux python3-impacket impacket-scripts \
    && gunzip -kf /usr/share/wordlists/rockyou.txt.gz \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# GitHub CLI (not in the Kali repos): needed to clone the private evopentester repo.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# uv (EvoPentester pins Python 3.12 via .python-version; uv fetches it on `uv sync`).
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install uv

WORKDIR /workspace

CMD ["sleep", "infinity"]
