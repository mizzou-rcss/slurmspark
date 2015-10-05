#!/bin/bash - 
#===============================================================================
#
#          FILE: slurmsparkctl.sh
# 
#         USAGE: ./slurmsparkctl.sh 
# 
#   DESCRIPTION: Start or Stop a standalone Spark cluster within Slurm
# 
#       OPTIONS: start, stop, status
#  REQUIREMENTS: ---
#          BUGS: Please Report
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 09/29/2015 09:30:51 AM CDT
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#-------------------------------------------------------------------------------
#  CONFIG
#-------------------------------------------------------------------------------
SPARK="spark/spark-1.4.1"
SPARK_LOCAL_DIRS="/local/scratch/$USER"
SCRATCH="/scratch/$USER"
SSH_OPTS="-o StrictHostKeyChecking=no"
WORKING_DIR="$(pwd)"


#-------------------------------------------------------------------------------
#  EXPORT ENVIRONMENTAL VARIABLES
#-------------------------------------------------------------------------------
export SPARK=${SPARK}
export SPARK_LOCAL_DIRS=${SPARK_LOCAL_DIRS}
export SCRATCH=${SCRATCH}
export SSH_OPTS=${SSH_OPTS}


#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
slurmspark::start() {
  module load ${SPARK}

  local node_list=($( srun hostname | sort ))
  local num_nodes=${#node_list[@]}
  local last_node=
}
