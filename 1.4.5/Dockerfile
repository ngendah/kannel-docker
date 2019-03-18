FROM alpine:3.9

WORKDIR /root

ENV BASE_PACKAGES="perl tzdata"
RUN apk add --no-cache --virtual .base-deps $BASE_PACKAGES

ENV BUILD_PACKAGES="build-base m4 libffi-dev libxml2-dev bzip2-dev libgcrypt-dev openssl-dev zlib-dev"
RUN apk add --no-cache --virtual .build-deps $BUILD_PACKAGES

RUN cp /usr/share/zoneinfo/GMT0 /etc/localtime
RUN echo "GMT0" >  /etc/timezone

ENV BISON_DOWNLOAD_PATH="http://ftp.gnu.org/gnu/bison/bison-2.7.tar.gz"
RUN set -ex \
	&& wget -q $BISON_DOWNLOAD_PATH \
	&& tar zxf bison-2.7.tar.gz \
	&& rm bison-2.7.tar.gz \
	&& cd bison-2.7 \
	&& ./configure \
	&& make \
	&& make install \
	&& cd .. \
	&& rm -rf bison-2.7

ENV KANNEL_BUILD_PACKAGES="linux-headers hiredis-dev postgresql-dev"
RUN apk add --no-cache --virtual .kannel-deps $KANNEL_BUILD_PACKAGES
RUN echo "#include <unistd.h>" > /usr/include/sys/unistd.h
RUN echo "#include <poll.h>" > /usr/include/sys/poll.h

ENV KANNEL_DOWNLOAD_PATH="https://redmine.kannel.org/attachments/download/322/gateway-1.4.5.tar.gz"
RUN set -ex \
	&& wget -q --no-check-certificate $KANNEL_DOWNLOAD_PATH \
	&& tar zxf gateway-1.4.5.tar.gz \
	&& rm gateway-1.4.5.tar.gz \
	&& cd gateway-1.4.5 \
	&& ./configure --with-redis --with-pgsql  \
	&& make \
	&& make install \
	&& cd .. \
	&& rm -rf gateway-1.4.5

ARG KANNEL_DIR
ENV KANNEL_DIR=$KANNEL_DIR

RUN mkdir -p $KANNEL_DIR

COPY ./startbox.sh .

ENTRYPOINT ["sh", "-c", "./startbox.sh"]

# TODO check sha512 sums
# TODO mark devel packages for removal