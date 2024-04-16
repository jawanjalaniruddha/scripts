# Database Backup restore procedure

### Prerequisites:

This script is tested on Ubuntu. 

You need to have below packages on system to run this script. You need to have homebrew installed on your Mac. 

* **Commands**: 

Install Homebrew: `/bin/bash -c "$(curl -fsSL raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

1. `psql`: Postgresql CLI client. Will be installed with `brew install libpq` & you might need to set path with 
    `echo 'export PATH="/usr/local/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc`
    `source ~/.zshrc`
2. `pg_dump`: Postgres command to take DB backup. Will be installed with `brew install libpq`
3. `pg_restore`: Postgres command to restore DB backup. Will be installed with `brew install libpq`
4. `jq`: A json parse tool `brew install jq`
5. `tee`: Copies screen output to file. Should be already present on Mac and Ubuntu
5. `sleep`: Add delay for specific amount of time. Seconds by default. Should be already present on Mac and Ubuntu

* **Config file**: 
Make sure to change below variables in the script 
1. CONFIG_FILE_PATH: Full path to db config json file which have database credentials for all required environments. Refer sample db config json file `.env.example.json`  


### Execution: 

* Command: 
    `bash database-backup-restore.sh ENV_NAME 2>&1 | tee -a db-backup-$(date +"%d%b%Y").log`
    Where ENV_NAME can be dev or demo.

* Source database: From where DB backup is created is set in below code snippet 

    Here source database is set to "production". If you want to change this, update the source env value to dev or demo. 

    ```
    # Set DB variables for source database
    PORT=$DEFAULT_POSTGRES_PORT
    HOST=$(jq -r .production.host $CONFIG_FILE_PATH)
    USERNAME=$(jq -r .production.username $CONFIG_FILE_PATH)
    PASSWORD=$(jq -r .production.password $CONFIG_FILE_PATH)
    DATABASE=$(jq -r .production.database $CONFIG_FILE_PATH)
    DB_DUMP_FILE="automationproject_demo_$(date +"%d%b%Y").sql"
    ```

* Destination database: Where DB backup is restored is taken as an commanline argument.

    For eg., to restore production data to demo database
    `bash database-backup-restore.sh demo 2>&1 | tee -a db-backup-$(date +"%d%b%Y").log`

    For eg, to restore production data to dev database
    `bash database-backup-restore.sh demo 2>&1 | tee -a db-backup-$(date +"%d%b%Y").log`

### Notes: 

* This will create a log file with date. For eg., "db-backup-12Apr2024.log"
    For each day, log file will get appended with latest logs while taking database backup

* Once the script if completed, you should get restored database details in logs message. 
    For eg., `Databse automationproject restored successfully on demo environment on host automationproject-demo.xxxxx.us-east-1.rds.amazonaws.com, DB: automationproject_demo_12042024`

* Please note that this script will create a database dump file with .sql extension and remove it once db restoration is completed. If you don't want to remove the database dump file, comment out `rm -fv $DB_DUMP_FILE` command.

* To truncate tables in restored database

    We don't want to keep data from production in dev or demo for sensetive tables. These tables are truncated as soon as DB restoration is completed. You can add tables to exclude in `EXCLUDE_TABLES` varible in script %

### Sample env.json file:

```
{
  "development": {
    "username": "xxx",
    "password": "xxx",
    "database": "xxx",
    "host": "xxx"
  },
  "demo": {
    "username": "xxx",
    "password": "xxx",
    "database": "xxx",
    "host": "xxx"
  },
  "production": {
    "username": "xxx",
    "password": "xxx",
    "database": "xxx",
    "host": "xxx"
  }
}
```
