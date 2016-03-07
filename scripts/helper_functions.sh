#!/bin/bash - 
#===============================================================================
#
#          FILE: helper_functions.sh
# 
#         USAGE: ./helper_functions.sh 
# 
#   DESCRIPTION: Collection of helper functions for use in other scripts within
#                slurmspark
# 
#       OPTIONS: 
#  REQUIREMENTS: 
#          BUGS: Please Report
#         NOTES: 
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 10/06/2015 03:56:25 PM CDT
#      REVISION: 1.5
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  slurm::walltime_to_min
#   DESCRIPTION:  Converts the walltime value to minutes
#    PARAMETERS:  $1 = The Walltime
#       RETURNS:  Prints result of conversion to stdout
#-------------------------------------------------------------------------------
slurm::walltime_to_min () {
    local walltime="$1"
    local numcolons="$(echo ${walltime} | awk -F: '{print NF-1}')"
    local days=""
    local fallback_walltime="$(sacctmgr -n list association account=general format="MaxWall" | head -n1 | sed 's/\-/\:/g')"
    local walltimetominutes=""

    ## Only awk days if - exists in walltime, else days are 0
    if [[ "$walltime" =~ '-' ]]; then
      days="$(echo ${walltime} | awk -F\- '{print $1}')"
    else
      days="0"
    fi

    if [[ "$days" -gt "0" ]]; then
      walltime=$(echo $walltime | sed 's/\-/\:/g')
      walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 * 24 * 60 + $2 * 60 + $3 + $4 / 60}' | xargs printf "%1.0f")
    else
      case $numcolons in
        '0' ) if [[ "$walltime" == "UNLIMITED" ]]; then
                walltimetominutes=$(echo ${fallback_walltime} | awk -F':' '{print $1 * 24 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f")
              fi
          ;;
        '1' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 + $2 / 60}' | xargs printf "%1.0f");;
        '2' ) walltimetominutes=$(echo ${walltime} | awk -F':' '{print $1 * 60 + $2 + $3 / 60}' | xargs printf "%1.0f");;
      esac
    fi
    echo "$walltimetominutes"
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  slurm::wait
#   DESCRIPTION:  Waits X ammount of time.  This is what keeps the slurmspark
#                 job from exiting before it's time is up.
#    PARAMETERS:  $1 = How long to wait in minutes
#       RETURNS:  NONE
#-------------------------------------------------------------------------------
slurm::wait() {
  local waittime="$1"
  local iterations="$(($waittime * 2))"

  for ((i = 1; i <= ${iterations}; i++)); do
    sleep 30
  done
}

