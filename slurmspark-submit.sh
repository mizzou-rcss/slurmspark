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
source scripts/spinner.sh
#===============================================================================

#-------------------------------------------------------------------------------
#  CONFIG
#-------------------------------------------------------------------------------
SBATCH_JOB_FILE="job_files/sbatch-srun-spark.sh"
WAITTIME="60"

## DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
DATE="$(date +%m%d%y_%N)"
CURRENT_JOB_ID_FILE=".current_jobid_${DATE}"

#-------------------------------------------------------------------------------
#  FUNCTIONS
#-------------------------------------------------------------------------------
trap::ctrl_c() {
  echo::error "Control-C pressed.  Exiting."
  echo::error "Please ensure your SLURM jobs have ended."
  stop_spinner 1
}
echo::error() {
  echo "$@" 1>&2;
}

build::cluster() {
  local sbatch_job_file="$1"
  
  sbatch -k ${sbatch_job_file} | tee ${CURRENT_JOB_ID_FILE}
}


waitfor::cluster() {
  local slurmspark_out_file="$1"

  until [[ -f "${slurmspark_out_file}" ]] && grep -q "run-example" ${slurmspark_out_file}; do
    sleep 1
  done
}

destroy::cluster() {
  local sbatch_job_id="$1"

  scancel ${sbatch_job_id}
}

check::cluster_status() {
  local sbatch_job_id="$1"
  local check="$(sacct -X -n -P -j ${sbatch_job_id} -s R -o jobid)"

  if [[ "$check" != "" ]]; then
    return 
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
    echo::error "Problem locating the current running SlurmSpark cluster. Exiting" 
  fi
}

get::slurmspark_master() {
  local slurm_job_out="$1"

  slurm_master_ip="$(grep "IP :" ${slurm_job_out} | awk '{print $3}')"
  slurm_master_port="$(grep "Master Port :" ${slurm_job_out} | awk '{print $4}')"

  if [[ "$slurm_master_ip" != "" ]] && [[ "$slurm_master_port" != "" ]]; then
    echo "spark://${slurm_master_ip}:${slurm_master_port}"
  else
    echo::error "Spark Master not found at ${slurm_job_out}.  Exiting."
  fi
}

slurmspark::submit() {
  module load java/openjdk/java-1.7.0-openjdk
  module load spark/spark-1.6.0-bin-hadoop2.6

  spark-submit $@
}

main() {
  local slurm_jobid=""
  ## Check if we have a jobid file already, and if we do, check the jobs status
  if [[ -f ${CURRENT_JOB_ID_FILE} ]]; then
    slurm_jobid="$(get::current_jobid "${CURRENT_JOB_ID_FILE}")"
    if [[ "${slurm_jobid}" == "" ]]; then
       exit 3
    fi
    check::cluster_status "${slurm_jobid}"
    ## If the job under the jobid witin CURRENT_JOB_ID_FILE is still running,
    ## run away screaming.
    if [[ "$?" -gt "0" ]]; then
      echo::error "SlurmSpark cluster is already running under the Slurm JobID ${slurm_jobid}"
      echo::error "Please complete or cancel this job before trying again."
      exit 1
    ## Else, we are clear to start the SlurmSpark cluster
    else
      build::cluster "${SBATCH_JOB_FILE}"

      slurm_jobid="$(get::current_jobid "${CURRENT_JOB_ID_FILE}")"
      if [[ "${slurm_jobid}" == "" ]]; then
         exit 3
      fi
      
      start_spinner "Waiting for SlurmSpark cluster..."
      waitfor::cluster "${slurm_jobid}.out"
      wait_exitcode="$?"
      stop_spinner ${wait_exitcode}
      if [[ "${wait_exitcode}" -gt "0" ]]; then
        echo::error "Waited ${WAITTIME} seconds for the SlurmSpark master, but none found.  Exiting"
        exit 2
      else
        local slurmspark_master="$(get::slurmspark_master "${slurm_jobid}.out")"
        if [[ "${slurmspark_master}" == "" ]]; then
          exit 4
        fi
        export MASTER="${slurmspark_master}"
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
      if [[ "${slurm_jobid}" == "" ]]; then
         exit 3
      fi
      
      start_spinner "Waiting for SlurmSpark cluster..."
      waitfor::cluster "${slurm_jobid}.out"
      wait_exitcode="$?"
      stop_spinner ${wait_exitcode}
      if [[ "${wait_exitcode}" -gt "0" ]]; then
        echo::error "Waited ${WAITTIME} seconds for the SlurmSpark master, but none found.  Exiting"
        exit 2
      else
        local slurmspark_master="$(get::slurmspark_master "${slurm_jobid}.out")"
        if [[ "${slurmspark_master}" == "" ]]; then
          exit 4
        fi
        export MASTER="${slurmspark_master}"
        echo "Found the SlurmSpark master at ${slurmspark_master}"
        echo "Submitting \"$@\" via spark-submit"
        slurmspark::submit $@
        start_spinner "Destroying SlurmSpark cluster..."
        destroy::cluster "${slurm_jobid}"
        destroy_exitcode="$?"
        stop_spinner ${destroy_exitcode}
      fi
  fi
}


#-------------------------------------------------------------------------------
#  MAIN
#-------------------------------------------------------------------------------
## Ensure MASTER is empty before calling the main function
unset MASTER
trap 'trap::ctrl_c' SIGINT
main $@
