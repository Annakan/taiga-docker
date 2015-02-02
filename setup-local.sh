#! /bin/bash


# setup-local is designed to NOT rely on any registry besides the base images
# the reason is, well, docker naming scheme is awfull, convoluted and probably plainly wrong confusing many goals in one (naming, locating, ownership, versionning ...)
# but mostly it prevent sane debugging and developement iteration and the dependency to the registry creep everywhere
# setup-local tries to build image "locally" with only the base images pulled from a registry and a naming shame that does not compound people name into the mix.
# you are free to tag the final images and upload them to any registry you want..

sudo mkdir -p /data/taiga/postgresql

sudo docker build -t i-fixedperm-postgres fixedperm-postgres/.
sudo docker build -t i-taiga-front frontend/.
sudo docker build -t i-taiga-back backend/.
sudo docker build -t i-taiga-front-static-builder frontend-build/.

#creating the DB container
sudo docker run -d --name taiga-postgres    -p 5432:5432  -v /data/taiga/postgresql:/var/lib/postgresql/data i-fixedperm-postgres 
#starting the RabbitMQ container
sudo docker run -d -p 5672:5672 -p 15672:15672 -v /data/taiga/rabbitmq:/data/log -v /data/rabbitmq:/data/mnesia --name rabbitmq  dockerfile/rabbitmq
# starting the redis container
docker run -d -p 6379:6379 -v /data/taiga/redis:/data --name redis dockerfile/redis


# creating the back end container and linking to the postgres, redis and rabbitMQ container
sudo docker run -d --name taiga-back  -p 8001:8001  --link taiga-postgres:postgres i-taiga-back 

# initializing the static datas of the front end web container

sudo docker run -it --rm -v /data/taiga:/taiga i-taiga-front-static-builder 


sudo docker run -d --name taiga-front -p 80:80 -p 8000:8000 --link taiga-back:taiga-back i-taiga-front


sudo docker run -it --link taiga-postgres:postgres --rm taiga-postgres sh -c "su postgres --command 'createuser -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" -d -r -s taiga'"
sudo docker run -it --link taiga-postgres:postgres --rm taiga-postgres sh -c "su postgres --command 'createdb -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" -O taiga taiga'";
sudo docker run -it --rm --link taiga-postgres:postgres taiga-back bash regenerate.sh


sudo docker stop taiga-front
sudo docker stop taiga-back
sudo docker stop taiga-postgres
