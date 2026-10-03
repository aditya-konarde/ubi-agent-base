FROM registry.access.redhat.com/ubi9/ubi-init:latest

RUN dnf -y install --setopt=install_weak_deps=False \
      bash git-core curl-minimal ca-certificates jq findutils diffutils \
      tar gzip unzip procps-ng iproute util-linux sudo \
      python3.12 python3.12-pip shadow-utils && \
    dnf clean all && rm -rf /var/cache/dnf

# uv is copied from its official release image; no installer runs at boot.
COPY --from=ghcr.io/astral-sh/uv:0.12.22 /uv /uvx /usr/local/bin/

RUN ln -s /usr/bin/python3.12 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.12 /usr/local/bin/python

ARG RIPGREP_VERSION=15.2.0
RUN set -eu; \
    case "$(uname -m)" in \
      x86_64) target=x86_64-unknown-linux-musl ;; \
      aarch64) target=aarch64-unknown-linux-gnu ;; \
      *) exit 1 ;; \
    esac; \
    archive="ripgrep-${RIPGREP_VERSION}-${target}.tar.gz"; \
    mkdir /tmp/rg; cd /tmp/rg; \
    curl -fsSLO "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${archive}"; \
    curl -fsSLO "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${archive}.sha256"; \
    sha256sum -c "${archive}.sha256"; \
    tar -xzf "${archive}"; \
    install -m 0755 "ripgrep-${RIPGREP_VERSION}-${target}/rg" /usr/local/bin/rg; \
    cd /; rm -rf /tmp/rg

# Official pinned Herdr binaries, verified against the release manifest.
COPY herdr-release.json /tmp/herdr-release.json
RUN set -eu; \
    case "$(uname -m)" in x86_64) platform=linux-x86_64 ;; aarch64) platform=linux-aarch64 ;; *) exit 1 ;; esac; \
    url=$(jq -r --arg p "$platform" '.assets[$p]' /tmp/herdr-release.json); \
    checksum=$(jq -r --arg p "$platform" '.sha256[$p]' /tmp/herdr-release.json); \
    curl -fsSL "$url" -o /usr/local/bin/herdr; \
    printf '%s  /usr/local/bin/herdr\n' "$checksum" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/herdr; \
    herdr --version; rm /tmp/herdr-release.json

RUN groupadd -g 1000 exedev && useradd -m -u 1000 -g exedev -s /bin/bash exedev && \
    printf 'exedev ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/exedev && \
    chmod 0440 /etc/sudoers.d/exedev && \
    printf '\nexport PATH=/usr/local/bin:$HOME/.local/bin:$PATH\n' >> /home/exedev/.bashrc && \
    printf 'export PATH=/usr/local/bin:$HOME/.local/bin:$PATH\n' > /etc/profile.d/agent-path.sh && \
    mkdir -p /home/exedev/.config/shelley /etc/systemd/journald.conf.d && \
    chown -R exedev:exedev /home/exedev && \
    printf '[Journal]\nStorage=persistent\nSystemMaxUse=64M\n' > /etc/systemd/journald.conf.d/limits.conf && \
    printf '/dev/vda / ext4 defaults,x-systemd.growfs 0 1\n' > /etc/fstab

COPY herdr-ssh.sh /etc/herdr-ssh.sh
RUN printf '\nsource /etc/herdr-ssh.sh\n' >> /home/exedev/.bashrc

COPY init /usr/local/bin/init
COPY exe-setup.service shelley.service shelley.socket /etc/systemd/system/
COPY licenses/ /usr/share/licenses/ubi-agent/
RUN chmod 0755 /usr/local/bin/init && \
    systemctl enable exe-setup.service shelley.socket && \
    systemctl mask systemd-udevd.service systemd-udevd-control.socket \
      systemd-udevd-kernel.socket systemd-udev-trigger.service \
      systemd-modules-load.service systemd-network-generator.service getty.target && \
    systemctl set-default multi-user.target && \
    : > /etc/machine-id

ENV PATH=/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
WORKDIR /home/exedev
LABEL exe.dev/login-user="exedev" exe.dev/install-shelley="true"
LABEL org.opencontainers.image.source="https://github.com/aditya-konarde/ubi-agent-base"
EXPOSE 8000 9999
CMD ["/usr/local/bin/init"]
