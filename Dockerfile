FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Install tools and dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      ca-certificates \
      libsasl2-modules \
      git \
      automake \
      autopoint \
      autoconf \
      texinfo \
      libjansson-dev \
      libtool \
      libltdl-dev \
      libgpg-error-dev \
      libidn11-dev \
      libunistring-dev \
      libglpk-dev \
      libbluetooth-dev \
      libextractor-dev \
      libmicrohttpd-dev \
      libgnutls28-dev \
      libgcrypt20-dev \
      libpq-dev \
      libsqlite3-dev && \
    apt-get clean all && \
    apt-get -y autoremove && \
    rm -rf \
      /var/lib/apt/lists/* \
      /tmp/*

# Install GNUrl
ENV GNURL_GIT_URL https://git.taler.net/gnurl.git
ENV GNURL_GIT_BRANCH gnurl-7.57.0

RUN git clone $GNURL_GIT_URL \
      --branch $GNURL_GIT_BRANCH \
      --depth=1 \
      --quiet && \
    cd /gnurl && \
      autoreconf -i && \
      ./configure \
        --enable-ipv6 \
        --with-gnutls \
        --without-libssh2 \
        --without-libmetalink \
        --without-winidn \
        --without-librtmp \
        --without-nghttp2 \
        --without-nss \
        --without-cyassl \
        --without-polarssl \
        --without-ssl \
        --without-winssl \
        --without-darwinssl \
        --disable-sspi \
        --disable-ntlm-wb \
        --disable-ldap \
        --disable-rtsp \
        --disable-dict \
        --disable-telnet \
        --disable-tftp \
        --disable-pop3 \
        --disable-imap \
        --disable-smtp \
        --disable-gopher \
        --disable-file \
        --disable-ftp \
        --disable-smb && \
      make install && \
    cd - && \
    rm -fr /gnurl


# Install libmicrohttpd

ENV LIBMICROHTTPD_PREFIX /opt/libmicrohttpd

RUN git clone https://gnunet.org/git/libmicrohttpd.git &&\
    cd libmicrohttpd &&\
    autoreconf -fi  &&\
    ./configure --disable-doc --prefix="$LIBMICROHTTPD_PREFIX" &&\
    make -j4 &&\
    make install

# Install GNUnet
ENV GNUNET_GIT_URL https://gnunet.org/git/gnunet
ENV GNUNET_GIT_BRANCH master
ENV GNUNET_PREFIX /usr
ENV CFLAGS '-g -Wall -O0'

RUN git clone $GNUNET_GIT_URL \
      --branch $GNUNET_GIT_BRANCH \
      --depth=1 \
      --quiet && \
    cd /gnunet && \
      ./bootstrap && \
      ./configure \
        --with-nssdir=/lib \
        --prefix="$GNUNET_PREFIX" \
        --enable-logging=verbose \
        --with-microhttpd="$LIBMICROHTTPD_PREFIX" && \
      make -j3 && \
      make install && \
      ldconfig && \
    cd - && \
    rm -fr /gnunet

# Configure GNUnet
COPY gnunet.conf /etc/gnunet.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN cp /usr/lib/gnunet/nss/libnss_gns.so.2 /lib/$(uname -m)-linux-gnu/ && \
    sed -i -E 's/^(hosts:\s+files) dns/\1 gns [NOTFOUND=return] dns/' /etc/nsswitch.conf

RUN chmod 755 /usr/local/bin/docker-entrypoint

ENV LOCAL_PORT_RANGE='40001 40200'
ENV PATH "$GNUNET_PREFIX/bin:/usr/local/bin:$PATH"

ENTRYPOINT ["docker-entrypoint"]
