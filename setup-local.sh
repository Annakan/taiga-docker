#! /bin/bash


#TAIGA_DATA_DIR="/data/taiga/"
#TAIGA_BD_DIR="$TAIGA_DATA_DIR/postgresql"

source gen_dockerfiles.sh

function find_running {
  for i in $(docker ps -a | grep "$1" | cut -f1 -d" "); do echo $i; done
}

function stop_running {
  echo "stopping $1"
  local cont_id=$(find_running $1)
  echo "id $cont_id"
  if [[ -n "$cont_id" ]]; then
    docker stop $cont_id;
    echo "Stopping  $cont_id"
    if [[ "$2" -eq "rm" ]]; then 
      sleep 2
      docker rm $cont_id
      echo "removed $1 $cont_id"
    fi
  fi
}

# setup-local is designed to NOT rely on any registry besides the base images
# the reason is, well, docker naming scheme is awfull, convoluted and probably plainly wrong confusing many goals in one (naming, locating, ownership, versionning ...)
# but mostly it prevents sane debugging and developement iteration and the dependency to the registry creep everywhere
# setup-local tries to build image "locally" with only the base images pulled from a registry and a naming scheme that does not compound "people" names into the mix.
# You are free to tag the final images and upload them to any registry you want..

#if [ -e "jq" ]; then
# curl -O http://stedolan.github.io/jq/download/linux64/jq
# chmod +x ./jq
#fi

if [ "$1" = "fresh" ]; then
  sudo rm  -rf $TAIGA_DATA_DIR
  echo " ********************* removed $TAIGA_DATA_DIR data erased **************************** "
  sleep 2
fi

sudo mkdir -p $TAIGA_BD_DIR
 
echo "****************************** building taiga ****************************************"
#docker build -t i-taiga-front frontend/. && 
docker build -t i-taiga-back backend/.  
docker build -t i-taiga-front-static-builder frontend-build/.
echo "****************************** END building taiga ****************************************"

# creating the DB container
echo "********************************** creating the DB container ********************************************* "
stop_running  taiga-postgres rm
docker build -t i-fixedperm-postgres fixedperm-postgres/.
docker run -d --name taiga-postgres  -p 5432:5432  -v $TAIGA_BD_DIR:/var/lib/postgresql/data i-fixedperm-postgres 
sleep 5 
docker run -it --link taiga-postgres:postgres --rm -e "SERVER_NAME=$SERVER_NAME" i-fixedperm-postgres sh -c "su postgres --command 'createuser -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" -d -r -s taiga'"
docker run -it --link taiga-postgres:postgres --rm -e "SERVER_NAME=$SERVER_NAME" i-fixedperm-postgres sh -c "su postgres --command 'createdb -h "'$POSTGRES_PORT_5432_TCP_ADDR'" -p "'$POSTGRES_PORT_5432_TCP_PORT'" -O taiga taiga'";
echo "********************************** END creating the DB container ********************************************* "


# starting the RabbitMQ container
stop_running rabbitmq rm
docker run -d -p 5672:5672 -p 15672:15672 -v /data/taiga/rabbitmq:/data/log -v /data/rabbitmq:/data/mnesia --name rabbitmq  dockerfile/rabbitmq

# starting the redis container
stop_running redis rm
docker run -d -p 6379:6379 -v /data/taiga/redis:/data --name redis dockerfile/redis


# creating the back end container and linking to the postgres, redis and rabbitMQ container
echo "******************** creating the back end container and linking to the postgres, redis and rabbitMQ container ********************"
stop_running taiga-back  rm
docker run -d  -e "SERVER_NAME=$SERVER_NAME" --name taiga-back  -p 8001:8001  --link taiga-postgres:postgres i-taiga-back 

# initializing the static datas of the front end web container
echo "*************** initializing the static datas of the front end web container *************************** "

docker run -it --rm  -e "SERVER_NAME=$SERVER_NAME" -v /data/taiga:/taiga i-taiga-front-static-builder 

stop_running taiga-front rm
cd ./frontend/ && source build.sh || cd ..
docker run -d  -e "SERVER_NAME=$SERVER_NAME" --name taiga-front -p 80:80 -p 8000:8000 --link taiga-back:taiga-back i-taiga-front
#docker exec taiga-front sh -c "cd /usr/local/nginx/html/js; sed s/localhost/$URL/g <app.js>app2.js; mv app2.js app.js"
#docker exec taiga-front sh -c "cd /usr/local/nginx/html/js; sed -i.old  s/localhost/$URL/g libs.js"
#docker exec taiga-front sh -c "cd /usr/local/nginx/html/js; sed -i.old  s/localhost/$URL/g app-loader.js"

echo "******************************************** regenerate datas ********************************************* "
docker run -it --rm --link taiga-postgres:postgres i-taiga-back bash regenerate.sh


docker stop taiga-front
docker stop taiga-back
docker stop taiga-postgres
