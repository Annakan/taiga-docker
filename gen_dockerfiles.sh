#! /bin/bash

TAIGA_DATA_DIR="/data/taiga/"
TAIGA_BD_DIR="$TAIGA_DATA_DIR/postgresql"

#SERVER_NAME="docker.assemblee-nationale.fr"
SERVER_NAME=${TAIGA_SERVER_NAME:=localhost}
URL_SCHEME=${TAIGA_URL_SCHEME:=http}
#URL_SCHEME="http"

cat << EOFDOCK > /frontend/Dockerfile
##############################################################
##
##
##  Taiga-front
##
##
###############################################################

FROM debian:wheezy

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

ENV SERVER_NAME $SERVER_NAME 

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" >> /etc/apt/sources.list

# make the "en_US.UTF-8" locale
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8



ENV NGINX_VERSION 1.7.9-1~wheezy
RUN apt-get update && apt-get install -y  ca-certificates nginx && rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

#VOLUME ["/usr/share/nginx/html"]
#VOLUME ["/etc/nginx"]
VOLUME ["/var/log/nginx"]

RUN echo "alias ll='ls -atrhlF'" >> ~/.bashrc

COPY build/dist /usr/local/nginx/html
COPY build/static /usr/local/nginx/html
COPY taiga.conf /etc/nginx/conf.d/default.conf
RUN sed -i.orig  s/TO_REPLACE/$SERVER_NAME/g /etc/nginx/conf.d/default.conf
ENV PATH /usr/local/nginx/sbin:$PATH
WORKDIR /usr/local/nginx/html

EXPOSE 80 443 8000

CMD ["nginx", "-g", "daemon off;"]
EOFDOCK


cat << EOFDOCK > /frontend-build/Dockerfile
##############################################################
##
##
##  Taiga-front
##
##
###############################################################


FROM ruby:2.1.2

MAINTAINER Ivan Pedrazas <ivan@pedrazas.me>

# More recent version of node and NPM than in the base repos
RUN apt-get install -y build-essential
# Docker special tricks with packages cause apt-get update to fail when used repeatdly
# see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=624122
RUN rm -f /etc/apt/apt.conf.d/docker-*
RUN apt-get update -y && curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get update -y && apt-get install --no-install-recommends -y -q  nodejs
RUN npm install npm -g

ENV SERVER_NAME=$SERVER_NAME
ENV URL_SCHEME=$URL_SCHEME

RUN (gem install sass scss-lint)
RUN (npm install -g gulp bower)
# node-legacy package do this BETTER and avoid that install gulp fail because npm can't find nodejs renamed
#RUN (ln -s /usr/bin/nodejs /usr/bin/node)

RUN (cd / && git clone https://github.com/taigaio/taiga-front.git)

#COPY main.coffee /taiga-front/app/config/main.coffee
RUN sed -i.orig s/${hostname}/$SERVER_NAME/g /taiga-front/app/config/main.coffee
RUN sed -i.orig s/${scheme}/$URL_SCHEME/g /taiga-front/app/config/main.coffee
# Git port is not always open lets use https
RUN git config --global url."https://".insteadOf git://
RUN (cd /taiga-front && npm install)
RUN (cd /taiga-front && bower install --allow-root)
RUN (cd /taiga-front && gulp deploy)

RUN (echo "alias ll='ls -atrhlF'" >> ~/.bashrc)

VOLUME /taiga

CMD mv /taiga-front/dist /taiga
EOFDOCK


cat << EOFDOCK > /backend/Dockerfile
FROM python:3
MAINTAINER Ivan Pedrazas "ipedrazas@gmail.com"
RUN apt-get -qq update

RUN apt-get install -y python-dev python-setuptools git-core locales

# make the "en_US.UTF-8" locale for utf-8 to be enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV SERVER_NAME $SERVER_NAME 


# this lines seems not to properly set the locale , it might not show on dockers run on a en_US.UTF-8 set host but does make the build fail on other hosts, the above locale setting method has been ripped from the postgres official docker container build and DOES work
#RUN echo "LANG=en_US.UTF-8" > /etc/default/locale
#RUN echo "LC_MESSAGES=POSIX" >> /etc/default/locale
#RUN echo "LANGUAGE=en" >> /etc/default/locale
#RUN locale-gen en_US.UTF-8
#ENV LANG en_US.UTF-8

RUN (echo hi)
RUN (echo hi)
RUN mkdir -p /logs/ && touch /logs/logfile.log
RUN (cd / && git clone https://github.com/taigaio/taiga-back.git taiga)

# docker needs to define the host database, use this file for
# any other settings you want to add/change
RUN (pip install -r /taiga/requirements.txt)
COPY docker-settings.py /tmp/docker-settings.py
RUN (cd /taiga && cat /tmp/docker-settings.py >> settings/local.py)
RUN (rm /tmp/docker-settings.py)
RUN sed -i.old  s/example/$SERVER_NAME/g /taiga/settings/local.py
RUN sed -i.old  s/example/$SERVER_NAME/g /taiga/settings/common.py
RUN sed -i.old  s/example/$SERVER_NAME/g /taiga/taiga/base/utils/urls.py


RUN (echo "alias ll='ls -atrhlF'" >> ~/.bashrc)

RUN (cd /taiga && python manage.py collectstatic --noinput)

VOLUME ["/logs"]

WORKDIR /taiga

EXPOSE 8001

CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]
EOFDOCK

