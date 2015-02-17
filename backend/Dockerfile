FROM python:3
MAINTAINER Ivan Pedrazas "ipedrazas@gmail.com"
RUN apt-get -qq update

RUN apt-get install -y python-dev python-setuptools git-core locales

# make the "en_US.UTF-8" locale for utf-8 to be enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV SERVER_NAME docker.assemblee-nationale.fr


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
