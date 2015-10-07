#!/bin/bash - 
#===============================================================================
#
#          FILE: helper_functions.sh
# 
#         USAGE: ./helper_functions.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/06/2015 03:56:25 PM CDT
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
slurm::walltime_to_min () {
    local walltime="$1"
    local numcolons="$(echo ${walltime} | awk -F: '{print NF-1}')"
    local fallback_walltime="$(sacctmgr -n list association account=general format="MaxWall" | head -n1 | sed 's/\-/\:/g')"
    local walltimetominutes=""

    case $numcolons in
      '0' ) if [[ "$walltime" == "UNLIMITED" ]]; then
              walltimetominutes=$(echo ${fallback_walltime} | awk -F':' '{print $1 * 24 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f")
            fi
        ;;
      '1' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 + $2 / 60}' | xargs printf "%1.0f");;
      '2' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f");;
    esac
    echo "$walltimetominutes"
}

slurm::wait() {
  local waittime="$1"
  local iterations="$(($waittime * 2))"

  for ((i = 1; i <= ${iterations}; i++)); do
    sleep 30
  done
}

