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
#      REVISION: 1.6-slurmspark-submit
#===============================================================================
#-------------------------------------------------------------------------------
#  SBATCH CONFIG
#-------------------------------------------------------------------------------
## The number of nodes for your Spark Cluster
#SBATCH --nodes=3

## Output file location.  This is where information on your cluster
## Will be written.  If this path is not full, it will be relative to the
## current working directory
#SBATCH --output="%j.out"

## The number of cores used by each executor
#SBATCH --cpus-per-task=8

## How long the Spark cluster will last (in minutes)
#SBATCH --time=128

## The name for the job
#SBATCH --job-name=testing

## The Slurm partition to run on
#SBATCH --partition=Compute

## How much memory to use for the job (in megabytes)
#SBATCH --mem=10000

## The following settings are in place for SlurmSpark to work.
## Please do not change these unless you have a good reason
#SBATCH --ntasks-per-node=1
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
## Export SCRIPT_HOME so it is available to the rest of the SlurmSpark
## scripts.
export SCRIPT_HOME=${SCRIPT_HOME}

#-------------------------------------------------------------------------------
#  SRUN
#-------------------------------------------------------------------------------
## Use srun to start the Spark Cluster
srun --no-kill /bin/bash ${SCRIPT_HOME}/spark_run.sh
