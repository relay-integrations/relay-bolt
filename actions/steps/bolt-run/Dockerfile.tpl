{{- /* Installing ni in these containers should be temporary (pending resolution of PN-59). */ -}}

{{- $PackageFileName := printf "ni-%s-linux-amd64.tar.xz" .SDKVersion -}}
{{- $PackageSHA256FileName := printf "%s.sha256" $PackageFileName -}}
{{- $PackageRepoURL := printf "https://packages.nebula.puppet.net/sdk/ni/%s" .SDKVersion -}}

FROM puppet/puppet-bolt:latest
ENV LANG C.UTF-8
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl git jq openssh-client wget xz-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN set -eux ; \
    mkdir -p /tmp/ni && \
    cd /tmp/ni && \
    wget {{ printf "%s/%s" $PackageRepoURL $PackageFileName }} && \
    wget {{ printf "%s/%s" $PackageRepoURL $PackageSHA256FileName }} && \
    echo "$( cat {{ $PackageSHA256FileName }} )  {{ $PackageFileName }}" | sha256sum -c - && \
    tar -xvJf {{ $PackageFileName }} && \
    mv ni-{{ .SDKVersion }}*-linux-amd64 /usr/local/bin/ni && \
    cd - && \
    rm -fr /tmp/ni
COPY ./step.sh /nebula/step.sh
ENTRYPOINT []
CMD ["/bin/bash", "/nebula/step.sh"]
