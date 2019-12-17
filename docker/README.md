GETTING STARTED
===

Just grab the Dockerfile and build the docker.

```
docker build . -t bop
```

(name "bop" is used in the start script)

The docker will download the whole project from github so the rest of the source code is not needed. Just the files under docker directory are necessary.

RUN THE DOCKER
===

```
./docker_run.sh
```

No argument needed.

The script will try to create the directory documents/bop-data under your home. This directory will be used to make all the generated data persistent. Change the script if you need another path.

The docker will bind to your port 3000 to let you access to the web server

WORLD MANAGEMENT
===

To create a wold

```
docker exec -it balance_of_power bop-perl-v2 new WORLD
```

To make the world elaborate a new turn

```
docker exec -it balance_of_power bop-perl-v2 elaborate WORLD
```

To delete a world

```
docker exec -it balance_of_power bop-perl-v2 delete WORLD
```

WEB SERVER
===

Web server is listening on port 3000 on the host of the container. Try <http://localhost:3000>





