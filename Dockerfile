FROM ubuntu:16.04 as base

ARG BUILDCMD
ENV DEBIAN_FRONTEND=noninteractive TERM=xterm BUILDCMD=${BUILDCMD:-build}
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

# Nodejs
RUN wget -O - https://nodejs.org/dist/v8.4.0/node-v8.4.0-linux-x64.tar.gz | tar xz
RUN mv node* node
ENV PATH $PATH:/node/bin

# Build Stage
FROM base as build

# Build tools
RUN apt-get install -y build-essential
COPY app /app
RUN cd /app && \
    npm --unsafe-perm install
RUN cd /app && \
    npm --unsafe-perm run $BUILDCMD

# Final Stage
FROM base as final
COPY --from=build /app /app

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

