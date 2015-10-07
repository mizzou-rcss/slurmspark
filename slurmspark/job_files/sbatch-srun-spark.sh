#!/bin/bash - 
#===============================================================================
#
#          FILE: sbatch-srun-spark.sh
# 
#         USAGE: ./sbatch-srun-spark.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 10/06/2015 04:05:58 PM CDT
#      REVISION:  ---
#===============================================================================
#-------------------------------------------------------------------------------
#  SBATCH CONFIG
#-------------------------------------------------------------------------------
#SBATCH --nodes=3
#SBATCH --output="%j.out"
#SBATCH --time=128
#SBATCH --job-name=testing
#SBATCH --partition=Mem128
#SBATCH --mem=60000

#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --no-kill


#-------------------------------------------------------------------------------
#  CONFIG
#-------------------------------------------------------------------------------
SCRIPT_HOME="${HOME}/slurmspark/scripts"


#-------------------------------------------------------------------------------
#  EXPORT
#-------------------------------------------------------------------------------
export SCRIPT_HOME=${SCRIPT_HOME}

#-------------------------------------------------------------------------------
#  SRUN
#-------------------------------------------------------------------------------
srun --no-kill /bin/bash ${SCRIPT_HOME}/spark_run.sh
