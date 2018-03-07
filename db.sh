## This script will dump all databases one by one, inside a folder ##
## Run command as .\xxxxxx.sh -u 'YOUR_DB_USER' -p 'YOUR_DB_PASSWORD' -h 'YOUR_DB_HOST(OPTIONAL)' ##

NOW=$(date +"%Y%m%d%H%M%S");

## THE FOLDER WHERE THE BACKUPS WILL BE PLACED ##
BACKUP_BASEFOLDER='/var/www-backups'

## THE LATEST BACKUP WILL BE PLACED IN HERE ##
LATEST="$BACKUP_BASEFOLDER/latest_db"

## Commit changes - Set to true in order to really execute the commands ##
EXECUTE=true;

## Maximum history states to be saved ##
HISTORY_STATES=9

## Do not touch ##
BACKUP_SAVE_FOLDER="$BACKUP_BASEFOLDER/$NOW"

## Default value if not set by argumnets ##
MHOST="127.0.0.1"

## Get the password from argument ##
while getopts u:p: option
	do
		case "${option}"
	in
		u) MUSER=${OPTARG};;
		p) MPASS=${OPTARG};;
		h) MHOST=${OPTARG};;
	esac
done

## Create the temporary folder ##
if [ ! -d "$BACKUP_SAVE_FOLDER" ]; then
	if [ $EXECUTE = true ]; then    
		mkdir $BACKUP_SAVE_FOLDER
	else
		echo mkdir $BACKUP_SAVE_FOLDER
	fi
fi


 
## Get database list ##
DBS="$(mysql -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
for db in $DBS
do
	## Exlude databases ##
	if [ $db = 'SKIP_THIS_DATABASE' ] || [ $db = 'OR_SKIP_THIS_DATABASE' ]; then
		echo "****** Skipping database $db ******"
		continue
	fi    

	GZ_FILE="$BACKUP_SAVE_FOLDER/$db.gz";
	echo "----------------- DUMPING $db -----------------";
	if [ $EXECUTE = true ]; then    
		mysqldump -u $MUSER -h $MHOST -p$MPASS $db | gzip -9 > $GZ_FILE
    	else
		echo mysqldump -u $MUSER -h $MHOST -p$MPASS $db | gzip -9 > $GZ_FILE
	fi    
    
	echo "Finished dumping => $GZ_FILE"
done

echo '-------------------------------------------------------------------'

## Rename previous latest to date ##
if [ -d "$LATEST" ]; then
	if [ $EXECUTE = true ]; then
		mv $LATEST $BACKUP_BASEFOLDER/$(date -r "$LATEST" +"%Y%m%d%H%M%S")-db
  	else
		echo mv $LATEST $BACKUP_BASEFOLDER/$(date -r "$LATEST" +"%Y%m%d%H%M%S")-db
	fi
fi

## Rename current run to latest ##
if [ $EXECUTE = true ]; then
	mv $BACKUP_SAVE_FOLDER $LATEST
else
	echo mv $BACKUP_SAVE_FOLDER $LATEST
fi

## DELETE older files ##
cd $BACKUP_BASEFOLDER
counter=0

## List by Creation date ##
for onefolder in $(ls -td *-db/);  do    
	foldername=$(echo $onefolder | sed -e 's/\///g')
	
	if [ $counter -gt $HISTORY_STATES ]; then
		echo 'Removing old backup ' $BACKUP_BASEFOLDER/$foldername
    		if [ $EXECUTE = true ]; then
        		rm -r $BACKUP_BASEFOLDER/$foldername
    		else
        		echo rm -r $BACKUP_BASEFOLDER/$foldername
    		fi
	fi
    
	counter=$((counter+1))
done

echo 'Finished all processes'
