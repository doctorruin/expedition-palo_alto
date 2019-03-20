# Containerized Expedition - Palo Alto

Docker build for Expedition.

docker build .

Installs from debian repository and uses base ubuntu:16.04

docker run --user expedition --name expedition -d -p 3306:3306 -p 443:443 -p 5140-5150:5140-5150 -p 4050-4070:4050-4070 -v $(PWD)/datastore:/datastore -v $(PWD)/mysql:/var/lib/mysql expedition:v0.8.1

### Docker Run Command
#### User
Run with --user expedition to secure the container, especially since php is used

#### Ports
-p 3306:3306 -p 443:443 -p 5140-5150:5140-5150 -p 4050-4070:4050-4070

These ports are required by the app. Make sure to open these orts on your firewall to map to the container.

#### Volumes
-v $(PWD)/datastore:/datastore -v $(PWD):/var/lib/mysql

The datastore mapping is for the ML part of the app. The Folder is created in the container, and if you want the data to persist
you need to map a local directory to it.

Same for mysql database. You can map an empty directory that will be initialized on docker run. If you have an already built
database, it will check the credentials and run against it. 


##### NOTE:
######This container is quite monolithic and doesn't follow all best practices. The next step is to seperate out apache2, mysql, and the app.
