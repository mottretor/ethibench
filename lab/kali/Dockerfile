FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# Curated web-pentest toolset: recon/scanning, content discovery/fuzzing,
# exploitation, wordlists, utilities, and Python for scripting/agents.
RUN apt-get update && apt-get install -y --no-install-recommends \
        nmap masscan whatweb wafw00f nikto nuclei sslscan \
        ffuf gobuster dirb wfuzz feroxbuster \
        sqlmap hydra commix \
        seclists wordlists \
        curl wget jq git netcat-traditional dnsutils iputils-ping iproute2 procps \
        vim-tiny ca-certificates \
        python3 python3-pip python3-venv python3-requests pipx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["sleep", "infinity"]
