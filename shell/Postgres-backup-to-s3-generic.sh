#!/bin/bash -x 

export PATH=$PATH:/usr/bin/aws
export PGPASSWORD=xxxXXXXXxxxx
#### BEGIN CONFIGURATION ####

# set dates for backup rotation
NOWDATE=`date +%Y-%m-%d`
LASTDATE=$(date +%Y-%m-%d --date='1 week ago')

# set backup directory variables
SRCDIR='/dbbackup'
DESTDIR='dbbackup'
BUCKET='project-posgres-bkp'

# database access details
HOST='127.0.0.1'
PORT='5432'
USER='dbbackup-user'
DB='dbname'

#### END CONFIGURATION ####

# make the temp directory if it doesn't exist
mkdir -p $SRCDIR

# dump each database to its own sql file
DBLIST=`psql -l -h$HOST -p$PORT -U$USER \
| awk '{print $1}' | grep -v "+" | grep -v "Name" | \
grep -v "List" | grep -v "(" | grep -v "template" | \
grep -v "postgres" | grep -v "root" | grep -v "|" | grep -v "|"`

# get list of databases
for DB in ${DBLIST}
do
pg_dump -h$HOST -p$PORT -U$USER $DB -f $SRCDIR/$DB.sql
done

# tar all the databases into $NOWDATE-backups.tar.gz
cd $SRCDIR
tar -czPf $NOWDATE-backup.tar.gz *.sql

# upload backup to s3
aws s3 cp $SRCDIR/$NOWDATE-backup.tar.gz s3://$BUCKET/$DESTDIR/

# delete old backups from s3
aws s3 rm --recursive s3://$BUCKET/$DESTDIR/$LASTDATE-backup.tar.gz

# remove all files in our source directory
cd
rm -f $SRCDIR/*
