#################################################
##  Legacy Monolithic Version of OpenSource    ##
##  PaloAlto Expedition Tool - Randolph Abeyta ##
#################################################

# base images
FROM ubuntu:16.04

#these envars suppress install noise
ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive

#userSpace is used as a home for some code config files
RUN mkdir /home/userSpace/

#files needed for install from vmdk package. in array to decrease space
COPY ["db.tar.gz", "ex-repo.list", "userSpace/*", "default-ssl.conf", "my.cnf", "entrypoint.sh", "/home/userSpace/"]

# update image to begin install, including adding expedtion repo
RUN apt-get update && apt-get install -y --allow-unauthenticated \
    apt-transport-https \
    gosu \
    software-properties-common \
    sudo &&\
    mv  /home/userSpace/ex-repo.list /etc/apt/sources.list.d/ex-repo.list &&\
    apt-get update; exit 0

# install other needed packages for app
RUN apt-get install -y \
    apache2 \
    curl \
    libapache2-mod-php \
    mariadb-server \
    rabbitmq-server \
    php7.0 \
    php7.0-curl \
    php7.0-mysql

# run command line to update perms, move files to location, and enable mods
RUN chown -R www-data: /home/userSpace &&\
    adduser --home /home/expedition expedition &&\
    usermod -aG sudo expedition &&\
    echo "expedition:paloalto" | chpasswd &&\
    mkdir /datastore &&\
    chown www-data: /datastore &&\
    chmod +x /datastore &&\
    mv /home/userSpace/entrypoint.sh /sbin/entrypoint.sh &&\
    chmod 755 /sbin/entrypoint.sh &&\
    mv /home/userSpace/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf &&\
    a2dismod  autoindex -f &&\
    a2enmod ssl &&\
    a2ensite default-ssl.conf &&\
    a2dissite 000-default.conf &&\
    mv /home/userSpace/my.cnf /etc/alternatives/my.cnf &&\
    tar -zxvf /home/userSpace/db.tar.gz -C  /home/userSpace/ &&\
    rm /home/userSpace/db.tar.gz &&\
    # rewrite conf files
    sed -i -e 's/\(mysqli.reconnect = \)Off/\1On/g' /etc/php/7.0/apache2/php.ini &&\
    sed -i -e 's/\(mysqli.reconnect = \)Off/\1On/g' /etc/php/7.0/cli/php.ini &&\
    sed -i -e 's/Listen 80/\#Listen 80/g' /etc/apache2/ports.conf

# install expedition and run update script
RUN apt-get install -y --allow-unauthenticated \
    expedition-beta \
    expeditionml-dependencies-beta &&\
    chmod +x /var/www/html/OS/BPA/updateBPA306.sh &&\
    /var/www/html/OS/BPA/updateBPA306.sh &&\
    apt-get clean

# ports needed for expedition
EXPOSE 3306/tcp
EXPOSE 443/tcp
EXPOSE 5140-5150/tcp
EXPOSE 4050-4070/tcp

# run entry script to install mysql and start services
ENTRYPOINT ["/sbin/entrypoint.sh", "&"]
