#!/bin/bash - 
#===============================================================================
#
#          FILE: spark_run.sh
# 
#         USAGE: ./spark_run.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/06/2015 04:19:52 PM CDT
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#-------------------------------------------------------------------------------
# CONFIG
#-------------------------------------------------------------------------------
source ${SCRIPT_HOME}/pre_setup.sh

MYHOSTNAME="$(hostname -s)"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
main() {
  if grep -q ${MYHOSTNAME} ${SPARK_CONF_DIR}/masters; then
    echo "$MYHOSTNAME is the master"
    echo "******************************************************"
    env
    echo "******************************************************"
  fi
}

main
