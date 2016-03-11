#!/bin/bash - 
#===============================================================================
#
#          FILE: slurmspark-submit.sh
# 
#         USAGE: ./slurmspark-submit.sh
# 
#   DESCRIPTION: Script to start a SlumSpark cluster, submit a job using 
#                spark-submit to said cluster, then tear down the cluster.
#
#                This script expects to be run from within the top level 
#                of the slurmspark repo!
# 
#       OPTIONS: 
#  REQUIREMENTS: ---
#          BUGS: Please report to rcss-support@missouri.edu
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 03/10/2016 03:36:51 PM CST
#      REVISION: 0.1
#===============================================================================

set -o nounset                              # Treat unset variables as an error


#-------------------------------------------------------------------------------
#  CONFIG
#-------------------------------------------------------------------------------
SBATCH_JOB_FILE="job_files/sbatch-srun-spark.sh"

## DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_JOB_ID_FILE=".current_jobid"
SLURMSPARK_MASTER_FILE=".slurmspark_master"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
build::cluster() {
  local sbatch_job_file="$1"
  
  sbatch -k ${sbatch_job_file} | tee .current_jobid
}

waitfor::cluster() {
  local slurmspark_master_file="$1"

  for i in {1..45}; do
    if [[ -f "${slurmspark_master_file}" ]]; then
      return 0
    fi
    sleep 1
  done
  
  return 1
}

destroy::cluster() {
  local sbatch_job_id="$1"

  scancel ${sbatch_job_id}
}

check::cluster_status() {
  local sbatch_job_id="$1"
  local check="$(sacct -X -n -P -j ${sbatch_job_id} -s R -o jobid)"

  if [[ "$check" != "" ]]; then
    return 1
  else
    return 0
  fi
}

get::current_jobid() {
  local current_job_id_file="$1"

  check="$(grep -E "^Submitted batch job" ${current_job_id_file})"
  if [[ "${check}" != "" ]]; then
    jobid="$(awk '{print $4}' ${current_job_id_file})"
    echo "${jobid}"
  else
    echo "Problem locating the current running SlurmSpark cluster.  Exiting"
    exit 3
  fi
}

slurmspark::submit() {
  module load java/openjdk/java-1.7.0-openjdk
  module load spark/spark-1.6.0-bin-hadoop2.6

  spark-submit $@
}

clean::up() {
  if [[ -f "${SLURMSPARK_MASTER_FILE}" ]]; then
    rm -f ${SLURMSPARK_MASTER_FILE}
  fi
}

main() {
  local slurm_jobid=""
  ## Ensure our working directory is clean of some of the hidden files
  ## before starting.
  clean::up

  ## Check if we have a jobid file already, and if we do, check the jobs status
  if [[ -f ${CURRENT_JOB_ID_FILE} ]]; then
    slurm_jobid="$(get::current_jobid "${CURRENT_JOB_ID_FILE}")"
    check::cluster_status "${slurm_jobid}"
    ## If the job under the jobid witin CURRENT_JOB_ID_FILE is still running,
    ## run away screaming.
    if [[ "$?" -gt "0" ]]; then
      echo "SlurmSpark cluster is already running under the Slurm JobID ${slurm_jobid}"
      exit 1
    ## Else, we are clear to start the SlurmSpark cluster
    else
      build::cluster "${SBATCH_JOB_FILE}"

      slurm_jobid="$(get::current_jobid "${CURRENT_JOB_ID_FILE}")"

      waitfor::cluster "${SLURMSPARK_MASTER_FILE}"
      if [[ "$?" -gt "0" ]]; then
        echo "Waited 30 seconds for the SlurmSpark master, but none found.  Exiting"
        exit 2
      else
        local slurmspark_master="$(cat ${SLURMSPARK_MASTER_FILE})"
        export MASTER="spark://${slurmspark_master}"
        echo "Found the SlurmSpark master at ${slurmspark_master}"
        echo "Submitting \"$@\" via spark-submit"
        slurmspark::submit $@
        destroy::cluster "${slurm_jobid}"
      fi
    fi
  ## If the jobid file is missing, assume we are free and clear
  else
      build::cluster "${SBATCH_JOB_FILE}"
      
      slurm_jobid="$(get::current_jobid "${CURRENT_JOB_ID_FILE}")"
      
      waitfor::cluster "${SLURMSPARK_MASTER_FILE}"
      if [[ "$?" -gt "0" ]]; then
        echo "Waited 30 seconds for the SlurmSpark master, but none found.  Exiting"
        exit 2
      else
        local slurmspark_master="$(cat ${SLURMSPARK_MASTER_FILE})"
        export MASTER="spark://${slurmspark_master}"
        echo "Found the SlurmSpark master at ${slurmspark_master}"
        echo "Submitting \"$@\" via spark-submit"
        slurmspark::submit $@
        destroy::cluster "${slurm_jobid}"
      fi
  fi
}


#-------------------------------------------------------------------------------
#  MAIN
#-------------------------------------------------------------------------------
main $@
