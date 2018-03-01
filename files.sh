NOW=$(date +"%Y%m%d%H%M%S");

## THE FOLDER WHERE THE BACKUPS WILL BE PLACED ##
BACKUP_BASEFOLDER='/var/www-backups'

## THE LATEST BACKUP WILL BE PLACED IN HERE ##
LATEST="$BACKUP_BASEFOLDER/latest_files"

## THE FOLDER WE WANT TO BACKUP ##
BACKUP_THIS_FOLDER='/var/www/';

## Commit changes - Set to true in order to really execute the commands ##
EXECUTE=false;

## Maximum history states to be saved ##
HISTORY_STATES=9

BACKUP_SAVE_FOLDER="$BACKUP_BASEFOLDER/$NOW"

## Create the temporary folder ##
if [ ! -d "$BACKUP_SAVE_FOLDER" ]; then
    if [ $EXECUTE = true ]; then    
		mkdir $BACKUP_SAVE_FOLDER
    else
    	echo mkdir $BACKUP_SAVE_FOLDER
    fi    
fi

cd $BACKUP_THIS_FOLDER
## Loop through the folders ##
for onefolder in $(ls -d */);  do    	
    # Replace slash at the end of the filename
    foldername=$(echo $onefolder | sed -e 's/\///g')
    echo '-------------------------------------------------------------------'
    
    ## Exclude folders ##
    if [ $foldername = 'SKIP_THIS_FOLDER' ] || [ $foldername = 'OR_SKIP_THIS_FOLDER' ]; then
    	echo '****** Skipping folder' $foldername '******'
        continue
    fi    
    
    echo 'Compressing :' $BACKUP_THIS_FOLDER$foldername
    
    GZ_FILE="$BACKUP_SAVE_FOLDER/$foldername.tar.gz"
    if [ $EXECUTE = true ]; then    	
       	tar -pczf $GZ_FILE $BACKUP_THIS_FOLDER$foldername
    else 
    	echo tar -pczf $GZ_FILE $BACKUP_THIS_FOLDER$foldername
    fi
        
  	echo 'Finished compression =>' $GZ_FILE
done

echo '-------------------------------------------------------------------'

## Rename previous latest to date ##
if [ -d "$LATEST" ]; then
	if [ $EXECUTE = true ]; then
		mv $LATEST $BACKUP_BASEFOLDER/$(date -r "$LATEST" +"%Y%m%d%H%M%S")-files
  	else
    	echo mv $LATEST $BACKUP_BASEFOLDER/$(date -r "$LATEST" +"%Y%m%d%H%M%S")-files
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
for onefolder in $(ls -td *-files/);  do 
    counter=$((counter+1))
    foldername=$(echo $onefolder | sed -e 's/\///g')
	
    if [ $counter -gt $HISTORY_STATES ]; then
      	echo 'Removing old backup ' $BACKUP_BASEFOLDER/$foldername
    	if [ $EXECUTE = true ]; then
        	rm -r $BACKUP_BASEFOLDER/$foldername
    	else
        	echo rm -r $BACKUP_BASEFOLDER/$foldername
    	fi
    fi
done
