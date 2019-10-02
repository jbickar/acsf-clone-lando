#!/bin/bash

# Exit if we fail. See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#The-Set-Builtin
set -e

read -p "Enter your SUNetID (e.g., 'jbickar'): " SUNETID
read -p "Enter the directory where you want your sites to be cloned (e.g. '\$HOME/Sites'): " WEBROOT

