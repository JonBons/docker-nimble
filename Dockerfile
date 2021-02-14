FROM magixus/nimble-server:3.6.7
RUN set -xe          \
    && echo '#!/bin/sh' > /usr/sbin/policy-rc.d         \
    && echo 'exit 101' >> /usr/sbin/policy-rc.d         \
    && chmod +x /usr/sbin/policy-rc.d           \
    && dpkg-divert --local --rename --add /sbin/initctl         \
    && cp -a /usr/sbin/policy-rc.d /sbin/initctl        \
    && sed -i 's/^exit.*/exit 0/' /sbin/initctl                 \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup                 \
    && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean       \
    && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean       \
    && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean          \
    && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages              \
    && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes          \
    && echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests
RUN rm -rf /var/lib/apt/lists/*
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
RUN mkdir -p /run/systemd \
    && echo 'docker' > /run/systemd/container
CMD ["/bin/bash"]
MAINTAINER Phusion <info@phusion.nl>
COPY files/bd_build /bd_build
RUN chmod +x /bd_build/prepare.sh \
    &&  chmod +x /bd_build/system_services.sh \
    &&  chmod +x /bd_build/utilities.sh \
    &&  chmod +x /bd_build/cleanup.sh
RUN /bin/sh -c /bd_build/prepare.sh \
    &&  /bd_build/system_services.sh \
    &&  /bd_build/utilities.sh \
    &&  /bd_build/cleanup.sh
ENV DEBIAN_FRONTEND=teletype LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
CMD ["/sbin/my_init"]
RUN echo "deb http://nimblestreamer.com/ubuntu xenial/" > /etc/apt/sources.list.d/nimblestreamer.list     \
    && curl -L -s http://nimblestreamer.com/gpg.key | apt-key add -     \
    && apt-get update     \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y nimble nimble-srt     \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*     \
    && mkdir /etc/nimble.conf     \
    && mv /etc/nimble/* /etc/nimble.conf
VOLUME [/etc/nimble]
VOLUME [/var/cache/nimble]
VOLUME [/videos]
ENV WMSPANEL_USER=
ENV WMSPANEL_PASS=
ENV WMSPANEL_SLICES=
ADD files/nimble_reg /etc/my_init.d
EXPOSE 1935 8081 4444
