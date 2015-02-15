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

ENV hostname="/docker.assemblee-nationale.fr"

RUN (gem install sass scss-lint)
RUN (npm install -g gulp bower)
# node-legacy package do this BETTER and avoid that install gulp fail because npm can't find nodejs renamed
#RUN (ln -s /usr/bin/nodejs /usr/bin/node)

RUN (cd / && git clone https://github.com/taigaio/taiga-front.git)

#COPY main.coffee /taiga-front/app/config/main.coffee
# Git port is not always open lets use https
RUN git config --global url."https://".insteadOf git://
RUN (cd /taiga-front && npm install)
RUN (cd /taiga-front && bower install --allow-root)
RUN (cd /taiga-front && gulp deploy)

RUN (echo "alias ll='ls -atrhlF'" >> ~/.bashrc)

VOLUME /taiga

CMD mv /taiga-front/dist /taiga
