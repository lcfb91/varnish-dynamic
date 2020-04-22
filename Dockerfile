FROM cooptilleuls/varnish:6.2.0-alpine
# Define env vars for VMOD build
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
ENV ACLOCAL_PATH /usr/local/share/aclocal
# The latest commit of 6.2 branch (as for now).
# There are no releases of this VMOD for varnish v6.2 yet.
ENV VMOD_DYNAMIC_COMMIT b8731c42f73075a112d4b3475c1da08a5e85fcec
# Install build dependencies; download, build and install the VMOD;
# then remove build dependencies to keep the docker layer as small as possible.
RUN set -eux; \
        apk add --no-cache --virtual .vmod-build-deps \
            autoconf \
            automake \
            libexecinfo-dev \
            libtool \
            make \
            pcre-dev \
            pkgconf \
            py-docutils \
            python3 \
        ;\
        wget "https://github.com/nigoroll/libvmod-dynamic/archive/${VMOD_DYNAMIC_COMMIT}.zip" -O /tmp/libvmod-dynamic.zip; \
        unzip -d /tmp /tmp/libvmod-dynamic.zip; \
        cd "/tmp/libvmod-dynamic-${VMOD_DYNAMIC_COMMIT}"; \
        chmod +x ./autogen.sh; \
        ./autogen.sh; \
        ./configure --prefix=/usr/local; \
        make -j "$(nproc)"; \
        make install; \
        cd /; \
        rm -rf /tmp/libvmod-dynamic*; \
        apk del .vmod-build-deps
# Run varnish and also print logs on stdout
CMD ["/bin/sh", "-o", "pipefail", "-c", "varnishd -f /usr/local/etc/varnish/default.vcl | varnishncsa -F '%h %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\" \"%{Varnish:handling}x\"'"]
