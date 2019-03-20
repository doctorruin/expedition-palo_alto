#!/bin/bash

mysql_setup(){
    MYSQL_PASSWORD="paloalto"
    DB_ARRAY=( "BestPractices" "RealTimeUpdates" "pandb" "pandbRBAC")
    SERVICE=( "mysql" )

    if mysql -u root --password=${MYSQL_PASSWORD} -e "SHOW DATABASES;";then
        echo "Root user password is set and mysql is running..."
        return 0
    else
        target="/var/ib/mysql"
        if find "$target" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
            echo "/var/lib/mysql has database, checking if service is running.."
            check_service_running ${SERVICE[@]}
        else
            # initialize mysql directory to mapped volume
            echo "/var/lib/mysql not initialized, initializing..."
            mysql_install_db --datadir=/var/lib/mysql


            if ! mysql -u root --password=${MYSQL_PASSWORD}  -e ";";then
                echo "Mysql root password not found, setting now"
                # start mysql to pick up new db
                check_service_running ${SERVICE[@]}
                # set root password
                echo "Setting root password..."
                mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('paloalto'); UPDATE mysql.user SET plugin = '' WHERE user = 'root' AND host = 'localhost'; FLUSH PRIVILEGES;"
                service mysql stop
                service mysql start
            else
                echo "Password found, starting mariadb.."
                service mysql start
            fi


            for d in ${DB_ARRAY[@]}; do
                if ! mysql -u root --password=${MYSQL_PASSWORD} -e "USE ${d};"; then
                    # create databases to be imported
                    echo "Creating ${d} database..."
                    mysql -u root --password=${MYSQL_PASSWORD} -e "CREATE DATABASE ${d};"
                    # import databases
                    echo "Importing ${d} database..."
                    mysql -u root --password=${MYSQL_PASSWORD} ${d} <  /home/userSpace/${d}.sql
                else
                    echo "${d} : Database already created"
                fi
             done
            # set parquetpath to datastore volume
            echo "Updating parquet path to /datastore mountpoint..."
            mysql -u root --password=${MYSQL_PASSWORD} -e "UPDATE pandbRBAC.ml_settings SET parquetPath = '/datastore' WHERE id = 1;"

        fi
    fi

}

# enable proper sites and mods for apache2
check_service_running() {
    SERVICE=("$@")

    for s in ${SERVICE[@]};do
        if (( $(ps -ef | grep -v grep | grep ${s} | wc -l) > 0 ));then
            echo "${s} is running!!!"
        else
            echo "${s} is starting!!!"
            /etc/init.d/${s} start
       fi
    done
}

#change user so no root access
sleep_start(){
    su - expedition
    sleep infinity
}

rm_sql (){
    DB_ARRAY=( "BestPractices" "RealTimeUpdates" "pandb" "pandbRBAC")
    DIR="/home/userSpace"
    for d in ${DB_ARRAY[@]}; do
        if [[ -f "${DIR}/${d}.sql" ]]; then
            rm ${DIR}/${d}.sql
        fi
    done
}

END_SERVICE_CHECK=( "apache2" "rabbitmq-server")

mysql_setup
rm_sql
check_service_running "${END_SERVICE_CHECK[@]}"
sleep_start