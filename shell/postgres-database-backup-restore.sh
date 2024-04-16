#!/usr/bin/env bash
set -uo pipefail 

echo -e "-------\n-------\n"
printf "Script execution started: $(date)\n"
echo -e "-------\n-------\n"

function unset_envvars {
  unset PGPASSWORD RESTORE_PORT RESTORE_HOST RESTORE_USERNAME RESTORE_PASSWORD RESTORE_DATABASE_NAME HOST USERNAME PASSWORD DATABASE_NAME PORT CONFIG_FILE_PATH
}

if [[ $# -eq 0 ]] ; then
    echo 'No arguments supplied to shell script'
    echo "Usage: "$0" <env>; where env can be: dev | demo"
    exit 1
fi

# Use env vars from .env or config file file 
CONFIG_FILE_PATH="/home/ubuntu/.env.json"
DEFAULT_POSTGRES_PORT=5432

# Set variables
PORT=$DEFAULT_POSTGRES_PORT
HOST=$(jq -r .production.host $CONFIG_FILE_PATH)
USERNAME=$(jq -r .production.username $CONFIG_FILE_PATH)
PASSWORD=$(jq -r .production.password $CONFIG_FILE_PATH)
DATABASE=$(jq -r .production.database $CONFIG_FILE_PATH)
DB_DUMP_FILE="automationproject_demo_$(date +"%d%b%Y").sql"

EXCLUDE_TABLES=(addresses   customers   carts   orders   order_details   bundle_order_details   user_discounts   newsletters   visitor_logs   customer_bundles   integrations customer_admin_integrations   user_reviews)

printf "\n#-------------------------------------#"
# Execute pg_dump command
printf "\nTaking database backup of DB $DATABASE from $HOST\n"
sleep 2
export PGPASSWORD=$PASSWORD; pg_dump -h $HOST -p $PORT -U $USERNAME -Fc -b -v -f $DB_DUMP_FILE -d automationproject
INPUT_FILE=$DB_DUMP_FILE

# Check if pg_dump was successful
if [ $? -eq 0 ]; then
  printf "Database dump successful. Output file: $DB_DUMP_FILE\n"
else
  printf "Error: Database dump failed.\n"
  unset_envvars
  exit 1 
fi
printf "#-------------------------------------#\n"
sleep 2


if [ "$1" == "dev" ];
then 
    # Set the database RESTORE connection parameters
    RESTORE_PORT=$DEFAULT_POSTGRES_PORT
    RESTORE_HOST=$(jq -r .development.host $CONFIG_FILE_PATH)
    RESTORE_USERNAME=$(jq -r .development.username $CONFIG_FILE_PATH)
    RESTORE_PASSWORD=$(jq -r .development.password $CONFIG_FILE_PATH)
    RESTORE_DATABASE_NAME="automationproject_$1_`date +%d%m%Y`"
    export PGPASSWORD=$RESTORE_PASSWORD;
elif [ "$1" == "demo" ];
then 
    # Set the database RESTORE connection parameters
    RESTORE_PORT=$DEFAULT_POSTGRES_PORT
    RESTORE_HOST=$(jq -r .demo.host $CONFIG_FILE_PATH)
    RESTORE_USERNAME=$(jq -r .demo.username $CONFIG_FILE_PATH)
    RESTORE_PASSWORD=$(jq -r .demo.password $CONFIG_FILE_PATH)
    RESTORE_DATABASE_NAME="automationproject_$1_`date +%d%m%Y`"
    export PGPASSWORD=$RESTORE_PASSWORD;
else
    sleep 0.1
    printf "Invalid argument passed."
    printf "Usage: "$0" <env>; where env can be: dev | demo"
    unset_envvars
    exit 1
fi 


# Execute the SQL command to create restoration DB in postgres 
psql -h $RESTORE_HOST -p $RESTORE_PORT -U $RESTORE_USERNAME -d automationproject -c "CREATE DATABASE $RESTORE_DATABASE_NAME;"

# Check if the command executed successfully
if [ $? -eq 0 ]; then
  printf "\nDatabase $RESTORE_DATABASE_NAME created successfully."
else
  printf "Error: Failed to create database $RESTORE_DATABASE_NAME."
  printf "Recreating database $RESTORE_DATABASE_NAME\n"
  psql -h $RESTORE_HOST -p $RESTORE_PORT -U $RESTORE_USERNAME -d automationproject -c "DROP DATABASE $RESTORE_DATABASE_NAME;"
  psql -h $RESTORE_HOST -p $RESTORE_PORT -U $RESTORE_USERNAME -d automationproject -c "CREATE DATABASE $RESTORE_DATABASE_NAME;"
fi

# Execute psql command for database restoration
printf "\n#-------------------------------------#"
printf  "\nRestoring Database $RESTORE_DATABASE_NAME on $1 environment on host $RESTORE_HOST...\n"
pg_restore --no-owner --no-privileges -v -h $RESTORE_HOST -p $RESTORE_PORT -U $RESTORE_USERNAME --role=$RESTORE_USERNAME -d $RESTORE_DATABASE_NAME $INPUT_FILE

# Check if psql command was successful
if [ $? -eq 0 ]; then
  printf "\nDatabase restoration successful.\n"
else
  printf "Error: Database restoration failed.\n"
fi
printf "#-------------------------------------#\n"

sleep 0.2

printf "\nTruncating data from unrequired tables...\n"
for each_table in ${EXCLUDE_TABLES[@]}
do
    sleep 1
    printf "Truncating table $each_table\n"
    # psql -h $RESTORE_HOST -p $RESTORE_PORT -U $RESTORE_USERNAME -d $RESTORE_DATABASE_NAME -c "DROP TABLE if exists $each_table cascade"
    psql -h $RESTORE_HOST -p $RESTORE_PORT -U $RESTORE_USERNAME -d $RESTORE_DATABASE_NAME -c "TRUNCATE $each_table CASCADE;"
    printf "Table $each_table truncated...\n"
done

printf "\n#-------------------------------------#\n"
printf  "\nDatabse $DATABASE restored successfully on $1 environment on host $RESTORE_HOST, DB: $RESTORE_DATABASE_NAME \n"
printf "Removing database backup file...\n"
rm -fv $DB_DUMP_FILE
unset_envvars
printf "Scipt completed.$(date) \n"%
