#!/bin/bash

##################
# Variables
##################

# Path to a place to store your sites.
WEBSERVERROOT=[webroot] #no trailing slash
# Path to your lando configuration file for Drupal 7
LANDOCONFIG=templates/example.d7.lando.yml
# The shortname of the site you are cloning
SHORTNAME=$1
# ACSF "stack", e.g., leland, cardinalsites
STACK=$2
# Your sunet id
SUNETID=[sunetid]
# Lando DB User (Also used in settings.php)
DBUSER="drupal7"
# Lando DB Pass (Also used in settings.php)
DBPASS="drupal7"
# Lando DB Name (Also used in settings.php)
DBNAME="drupal7"
# Lando DB Server (Also used in settings.php)
DBSERVER="database"
# The user on your computer who should own the files.
OWNER=$USER
# The group on your computer who should own the files.
GROUP="staff"
# AH_SITE_GROUP variable on Acquia. Default to cardinald7. Can pass as a second
# argument to the script.
AH_SITE_GROUP="cardinald7"
# AH_SITE_ENVIRONMENT variable on Acquia. Default to cardinald7. Can pass as a second
# argument to the script.
AH_SITE_ENVIRONMENT="02live"
# URL of the site on ACSF
ACSFURL="https://$SHORTNAME.sites.stanford.edu/"
# Drupal major version. Toggled later for D8.
DRUPALVERSION="7"

#############
# Prompts
#############

# Must provide a shortname or you cannot continue.
if [ -z "$1" ]; then
  echo "You must provide a shortname in parameter #1"
  exit;
fi

# Set variables based on arguments.
if [ "$2" == "leland" ]; then
  AH_SITE_ENVIRONMENT="03live"
  AH_SITE_GROUP="leland"
  ACSFURL="https://$SHORTNAME.people.stanford.edu/"
elif [ "$2" == "cardinalsites" ]; then
  AH_SITE_ENVIRONMENT="01live"
  AH_SITE_GROUP="cardinalsites"
  DRUPALVERSION="8"
elif [ "$2" == "lelandd8" ]; then
  AH_SITE_ENVIRONMENT="01live"
  AH_SITE_GROUP="lelandd8"
  DRUPALVERSION="8"
fi

# Set variables based on Drupal major version.
if [ "$DRUPALVERSION" == "8"]; then
  DBUSER="drupal8"
  DBPASS="drupal8"
  DBNAME="drupal8"
  LANDOCONFIG="templates/example.d8.lando.yml"
fi

# If dir exists empty it.
if [ -d $WEBSERVERROOT/$SHORTNAME ]; then
  echo "Are you sure you want remove all files and rebuild in $WEBSERVERROOT/$SHORTNAME"
  select yepnope in "Yes, I know what I am doing!" "No way. Die die die."; do
  case $yepnope in
    'Yes, I know what I am doing!' )
      echo "Removing all files in $WEBSERVERROOT/$SHORTNAME"
      sudo rm -Rf $WEBSERVERROOT/$SHORTNAME
      break;;
    'No way. Die die die.' )
      echo 'Terminating.';
      exit;;
  esac
done
fi

####################
# DEFINE VARIABLES
####################
ACSFDBNAME=$(drush @acsf.$AH_SITE_GROUP.$SHORTNAME vget acsf_db_name --format=string)
#echo $ACSFDBNAME
PUBLICFILES=sites/g/files/$ACSFDBNAME/f
PRIVATEFILES=/mnt/files/cardinald7.02live/sites/g/files-private/$ACSFDBNAME
################
# RUN
################

# Get resources from server.
echo "Starting dump on server..."
if [ "$INCLUDEFILES" = "no-files" ]; then
  drush @acsf.$AH_SITE_GROUP.$SHORTNAME ard --destination=/mnt/files/$AH_SITE_GROUP$AH_SITE_ENVIRONMENT/tmp/$SUNETID-copy.tar.gz --tar-options="--exclude=$PUBLICFILES" --overwrite
  echo "Skipping files in drush ard"
else
  drush @acsf.$AH_SITE_GROUP.$SHORTNAME ard --destination=/mnt/files/$AH_SITE_GROUP$AH_SITE_ENVIRONMENT/tmp/$SUNETID-copy.tar.gz --overwrite
fi

# Get the files from the server.
echo "Copying archive to local..."
scp $AH_SITE_GROUP.$AH_SITE_ENVIRONMENT@$AH_SITE_GROUP$AH_SITE_ENVIRONMENT.ssh.enterprise-g1.acquia-sites.com:/mnt/files/$AH_SITE_GROUP$AH_SITE_ENVIRONMENT/tmp/$SUNETID-copy.tar.gz $WEBSERVERROOT/$SUNETID-copy.tar.gz

# Remove old unzipped directory.
if [ -d $WEBSERVERROOT/$SUNETID-copy ]; then
  echo "Cleaning up old archive expansion"
  sudo rm -Rf $WEBSERVERROOT/$SUNETID-copy
fi

# Expand in to new directory.
echo "Creating $WEBSERVERROOT/$SUNETID-copy"
mkdir $WEBSERVERROOT/$SUNETID-copy

# Expand
echo "Unzipping tar to $WEBSERVERROOT/$SUNETID-copy"
tar -zxf $WEBSERVERROOT/$SUNETID-copy.tar.gz -C $WEBSERVERROOT/$SUNETID-copy

# Move SUNETID-copy in to shortname dir.
echo "Copying $SUNETID-copy to $WEBSERVERROOT/$SHORTNAME"
sudo mv $WEBSERVERROOT/$SUNETID-copy $WEBSERVERROOT/$SHORTNAME

# Fix up a few permissions
echo "Fixing up a few file permissions"
sudo chown -Rf $OWNER:$GROUP $WEBSERVERROOT/$SHORTNAME
sudo chmod -Rf 0755 $WEBSERVERROOT/$SHORTNAME

# Create and chmod the files directory.
mkdir -p $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/files/private
if [ "$DRUPALVERSION" == "7" ]; then
  mkdir -p $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/files/css_injector
  mkdir -p $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/files/js_injector
fi
sudo chmod -Rf 0777 $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/files

# Clean up a few items
echo "Removing sites specific files."
sudo rm -Rf $WEBSERVERROOT/$SHORTNAME/.git
# TODO No such files
#sudo rm $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/settings.local.php
#sudo rm $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/settings.php

# Add the our files.
echo "Adding our configuration files."
cp $LANDOCONFIG $WEBSERVERROOT/$SHORTNAME/docroot/.lando.yml
cp $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/default.settings.php $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/settings.php

# Replace the shortname from RewriteBase.
sed -i .bak "s/\/$SHORTNAME/\//g" $WEBSERVERROOT/$SHORTNAME/docroot/.htaccess

# Comment out a setting that doesn't work with Lando's apache
sed -i .bak '/Header Set Cache-Control/s/^/#/' $WEBSERVERROOT/$SHORTNAME/docroot/.htaccess

# Copy the DB over from the extraction so we can import it later.
DBSHORT=$(echo $SHORTNAME | sed 's/\-/_/g')
DBDUMP="$DBSHORT.sql"
echo "Copying database dump to $WEBSERVERROOT/$SHORTNAME/db.sql"
# TODO: is this database name stack-specific?
cp $WEBSERVERROOT/$SHORTNAME/cardinalddb*.sql $WEBSERVERROOT/$SHORTNAME/docroot/db.sql

# Set the DB credentials in settings.php
echo "Appending database credentials to settings.php"
cat << FOE >> ${WEBSERVERROOT}/${SHORTNAME}/docroot/sites/default/settings.php
\$databases = array(
  'default' =>
  array (
    'default' =>
    array (
      'database' => '${DBNAME}',
      'username' => '${DBUSER}',
      'password' => '${DBPASS}',
      'host' => '${DBSERVER}',
      'port' => '3306',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);

FOE


# Navigate to the directory
cd $WEBSERVERROOT/$SHORTNAME/docroot/

# Replace lando shortname
echo "Changing shortname in lando config file."
LANDONAME=$(echo $DBSHORT | sed 's/\_//g')
sed -i .bak "s/\[shortname\]/${LANDONAME}/g" $WEBSERVERROOT/$SHORTNAME/docroot/.lando.yml
rm $WEBSERVERROOT/$SHORTNAME/docroot/.lando.yml.bak

# Set $base_url
printf "\n" >> ${WEBSERVERROOT}/${SHORTNAME}/docroot/sites/default/settings.php
echo "\$base_url = 'https://"$LANDONAME".lndo.site';" >> ${WEBSERVERROOT}/${SHORTNAME}/docroot/sites/default/settings.php
printf "\n" >> ${WEBSERVERROOT}/${SHORTNAME}/docroot/sites/default/settings.php

# Download stage_file_proxy
drush dl stage_file_proxy

# Copy CSS Injector and JS Injector files.
if [ "$DRUPALVERSION" == "7" ]; then
  rsync -azq $AH_SITE_GROUP.$AH_SITE_ENVIRONMENT@$AH_SITE_GROUP$AH_SITE_ENVIRONMENT.ssh.enterprise-g1.acquia-sites.com:/mnt/files/$AH_SITE_GROUP$AH_SITE_ENVIRONMENT/$PUBLICFILES/css_injector/* $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/files/css_injector/
  rsync -azq $AH_SITE_GROUP.$AH_SITE_ENVIRONMENT@$AH_SITE_GROUP$AH_SITE_ENVIRONMENT.ssh.enterprise-g1.acquia-sites.com:/mnt/files/$AH_SITE_GROUP$AH_SITE_ENVIRONMENT/$PUBLICFILES/js_injector/* $WEBSERVERROOT/$SHORTNAME/docroot/sites/default/files/js_injector/
fi

# Start lando
lando stop
lando rebuild -y
lando start

# Import DB using lando
lando db-import db.sql

# Add custom fixes in order to get the site to work in the lando box.
echo "Starting Lando Drush Command Fixups."
lando --clear
lando drush cc drush
lando drush vset stage_file_proxy_hotlink TRUE
lando drush vset stage_file_proxy_origin $ACSFURL
lando drush -y en stage_file_proxy
lando drush rr
# lando drush dis stanford_sites_systemtools -y
# lando drush dis stanford_sites_helper -y

# drush uli; tr to strip the carriage return
ULI=$(lando drush uli | tr -d '\r')
open $ULI
