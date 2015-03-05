FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
  apt-get install -y \
  build-essential git-core subversion \
  libmicrohttpd-dev libjansson-dev libnice-dev \
  libssl-dev libsrtp-dev libsofia-sip-ua-dev libglib2.0-dev \
  libopus-dev libogg-dev libini-config-dev libcollection-dev \
  libevent-dev pkg-config gengetopt libtool automake curl && \
  apt-get clean && rm -rf /tmp/* /var/tmp/*


RUN \
  svn co http://sctp-refimpl.googlecode.com/svn/trunk/KERN/usrsctp usrsctp && \
  git clone git://github.com/payden/libwebsock.git

RUN \
  cd usrsctp && \
  ./bootstrap && \
  ./configure --prefix=/usr && make && sudo make install && \
  cd ..

RUN \
  cd libwebsock && \
  git checkout tags/v1.0.4 && \
  autoreconf -i && \
  ./autogen.sh && \
  ./configure --enable-static --prefix=/usr && make && sudo make install && \
  cd ..

ADD . /janus-gateway
RUN \
  cd janus-gateway && \
  sh autogen.sh && \
  ./configure --enable-static --prefix=/opt/janus --enable-websockets \
    --disable-data-channels --disable-rabbitmq --disable-docs && \
  make && \
  make install && \
  make configs

# http
EXPOSE 8088

# https
EXPOSE 8089

# admin http
EXPOSE 7088

# admin https
EXPOSE 7889

# static files
EXPOSE 80

CMD /opt/janus/bin/janus & \
  cd /janus-gateway/html && python -m SimpleHTTPServer 80


# For example you can build and run janus-gateway like this
#
#   docker build -t janus-gateway .
#   docker run -it -p 80:80 -p 8088:8088 -p 7088:7088 janus-gateway
#
# and then open the browser at http://[docker_ip]:80/ to see the janus demos

