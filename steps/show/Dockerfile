FROM puppet/puppet-bolt:latest
ENV LANG C.UTF-8
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl git jq openssh-client wget xz-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN set -eux ; \
    mkdir -p /tmp/ni && \
    cd /tmp/ni && \
    wget https://packages.nebula.puppet.net/sdk/ni/v1/ni-v1-linux-amd64.tar.xz && \
    wget https://packages.nebula.puppet.net/sdk/ni/v1/ni-v1-linux-amd64.tar.xz.sha256 && \
    echo "$( cat ni-v1-linux-amd64.tar.xz.sha256 )  ni-v1-linux-amd64.tar.xz" | sha256sum -c - && \
    tar -xvJf ni-v1-linux-amd64.tar.xz && \
    mv ni-v1*-linux-amd64 /usr/local/bin/ni && \
    cd - && \
    rm -fr /tmp/ni
COPY ./step.sh /relay/step.sh
ENTRYPOINT []
CMD ["/bin/bash", "/relay/step.sh"]

LABEL "org.opencontainers.image.title"="Show the available Bolt tasks or plans"
LABEL "org.opencontainers.image.description"="Shows the available Bolt tasks or plans."
LABEL "com.puppet.nebula.sdk.version"="v1"
