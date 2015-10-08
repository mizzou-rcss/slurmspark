#!/bin/bash - 
#===============================================================================
#
#          FILE: sbatch-srun-spark.sh
# 
#         USAGE: sbatch -k sbatch-srun-spark.sh 
# 
#   DESCRIPTION: SBATCH job file for starting a spark cluster in slurm
# 
#       OPTIONS: 
#  REQUIREMENTS: 
#          BUGS: Please Report
#         NOTES: 
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: RCSS
#       CREATED: 10/06/2015 04:05:58 PM CDT
#      REVISION: 0.1
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
## Location of slurmspark scripts
##   Options: Valid path to a directory containing slurmspark scripts
##     Notes: Should not need to change this unless you cloned this repo
##            outside your home directory.
SCRIPT_HOME="${HOME}/slurmspark/scripts"

#-------------------------------------------------------------------------------
#  EXPORT
#-------------------------------------------------------------------------------
export SCRIPT_HOME=${SCRIPT_HOME}

#-------------------------------------------------------------------------------
#  SRUN
#-------------------------------------------------------------------------------
srun --no-kill /bin/bash ${SCRIPT_HOME}/spark_run.sh
