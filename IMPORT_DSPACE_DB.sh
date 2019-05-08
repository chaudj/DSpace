#!/bin/bash

echo "$(tput setaf 6)ARE YOU SURE? "$(tput sgr 0)
read sure
if [ $sure != 'yes' ]; then
   exit
fi

echo "$(tput setaf 6)AGAIN ARE YOU SURE?"$(tput sgr 0)
read sureagain
if [ $sureagain != 'yes' ]; then
   exit
fi
echo 'HELLO'

cd /home/ubuntu/db_backup

echo "$(tput setaf 6)mEnter database number <<default:Last downloaded database>>"$(tput sgr 0)
read num

if [ ! -n "$num" ]; then
    num=`ls -t | awk '{printf("%s",$0);exit}' | tr -d '[:alpha:]\-\.'`
fi

if [ -f "dspace-$num.dump" ]; then
   echo "$(tput setaf 5)File dspace-$num.dump  exist."$(tput sgr 0)
elif [ -f "dspace-$num.dump.tar.gz" ]; then
   echo "$(tput setaf 5)Extracting the file..."$(tput sgr 0)
   tar -xvzf dspace-$num.dump.tar.gz
else
   echo "$(tput setaf 5)File not found"$(tput sgr 0)
   exit
fi

echo "$(tput setaf 6)Stopping dspace container..."$(tput sgr 0)
docker stop dspace

echo "$(tput setaf 6)Droping database..."$(tput sgr 0)
docker exec dspace_db dropdb -U postgres dspace

echo "$(tput setaf 6)Creating database..."$(tput sgr 0)
docker exec dspace_db createdb -U postgres -O dspace --encoding=UNICODE dspace

echo "$(tput setaf 6)Creating dspace user..."$(tput sgr 0)
docker exec dspace_db psql -U postgres dspace -c 'alter user dspace createuser;'

echo "$(tput setaf 6)Copying database..."$(tput sgr 0)
cp dspace-$num.dump /home/ubuntu/dspace-docker/postgresData/

echo "$(tput setaf 6)Importing database..."$(tput sgr 0)
docker exec dspace_db pg_restore -U postgres -d dspace /var/lib/postgresql/data/dspace-$num.dump

echo "$(tput setaf 6)Removing dspace user..."$(tput sgr 0)
docker exec dspace_db psql -U postgres dspace -c 'alter user dspace nocreateuser;'

echo "$(tput setaf 6)Vacum database..."$(tput sgr 0)
docker exec dspace_db vacuumdb -U postgres dspace

echo "$(tput setaf 6)Updating sequences..."$(tput sgr 0)
docker cp dspace:/dspace/etc/postgres/update-sequences.sql /home/ubuntu/dspace-docker/postgresData/
docker exec dspace_db psql -U dspace -f /var/lib/postgresql/data/update-sequences.sql dspace

echo "$(tput setaf 6)Cleaning up..."$(tput sgr 0)
rm /home/ubuntu/dspace-docker/postgresData/update-sequences.sql
rm /home/ubuntu/dspace-docker/postgresData/dspace-$num.dump
rm dspace-$num.dump

echo "$(tput setaf 6)Starting dspace container..."$(tput sgr 0)
docker start dspace

echo "$(tput setaf 6)Finish"$(tput sgr 0)