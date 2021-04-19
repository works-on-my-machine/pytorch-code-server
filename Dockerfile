FROM nvidia/cuda:11.1-base-ubuntu20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl \
  ca-certificates \
  dumb-init \
  htop \
  sudo \
  git \
  bzip2 \
  libx11-6 \
  locales \
  man \
  nano \
  git \
  procps \
  openssh-client \
  vim.tiny \
  lsb-release \
  python \
  python3-pip \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen
ENV LANG=en_US.UTF-8

# Create project directory
RUN mkdir /projects

# Create a non-root user
RUN adduser --disabled-password --gecos '' --shell /bin/bash coder \
  && chown -R coder:coder /projects
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-coder

# Install fixuid
ENV ARCH=amd64
RUN curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
  chown root:root /usr/local/bin/fixuid && \
  chmod 4755 /usr/local/bin/fixuid && \
  mkdir -p /etc/fixuid && \
  printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

# Install code-server
WORKDIR /tmp
ENV CODE_SERVER_VERSION=3.9.3
RUN curl -fOL https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_${ARCH}.deb
RUN dpkg -i ./code-server_${CODE_SERVER_VERSION}_${ARCH}.deb && rm ./code-server_${CODE_SERVER_VERSION}_${ARCH}.deb
COPY ./entrypoint.sh /usr/bin/entrypoint.sh

# Switch to default user
USER coder
ENV USER=coder
ENV HOME=/home/coder
WORKDIR /projects

EXPOSE 8443
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8443", "--cert", "--disable-telemetry", "."]