#!/bin/bash

# Exit if we fail. See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#The-Set-Builtin
set -e

read -p "Enter your SUNetID (e.g., 'jbickar'): " SUNETID
read -p "Enter the directory where you want your sites to be cloned (e.g. '\$HOME/Sites', no trailing slash): " WEBROOT
cp templates/example.acsf-clone-lando.sh $PWD/acsf-clone-lando.sh
sed -i '' "s/\[sunetid\]/$SUNETID/g" $PWD/acsf-clone-lando.sh
# Our $WEBROOT contains forward slashes, so use "~" as the delimiter for sed.
sed -i '' "s~\[webroot\]~$WEBROOT~g" $PWD/acsf-clone-lando.sh

printf "\nalias acsf-clone-lando=\'$PWD/acsf-clone-lando.sh\'\n" >> $HOME/.bashrc
source ~/.bashrc
