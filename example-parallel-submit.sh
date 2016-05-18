#!/bin/bash - 
#===============================================================================
#
#          FILE: example-parallel-submit.sh
# 
#   DESCRIPTION: EXAMPLE Wrapper script to submit multiple SlurmSpark jobs
#                You will most likely need to modify this to suit your needs
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Micheal Quinn (), quinnm@missouri.edu
#  ORGANIZATION: 
#       CREATED: 05/18/2016 11:18:22 AM CDT
#      REVISION:  ---
#===============================================================================
#-------------------------------------------------------------------------------
#  EXAMPLE: Calculating Pi via sparksubmit on 2 different slurmspark clusters
#-------------------------------------------------------------------------------
### Start our first SlurmSpark cluster, redirecting all output to 'slurmspark_job_1.out'
### and sending the script to the background '&'

./slurmspark-submit.sh --class org.apache.spark.examples.SparkPi --executor-memory 1G --total-executor-cores 10 /cluster/software/spark/spark-1.6.0-bin-hadoop2.6/lib/spark-examples-1.6.0-hadoop2.6.0.jar 10 &> slurmspark_job_1.out &

### Start our second SlurmSpark cluster, redirecting all output to 'slurmspark_job_1.out'
### and sending the script to the background '&'

./slurmspark-submit.sh --class org.apache.spark.examples.SparkPi --executor-memory 1G --total-executor-cores 10 /cluster/software/spark/spark-1.6.0-bin-hadoop2.6/lib/spark-examples-1.6.0-hadoop2.6.0.jar 10 &> slurmspark_job_2.out &


#-------------------------------------------------------------------------------
#  EXAMPLE: Same as above, but in a for loop
#-------------------------------------------------------------------------------
for i in {1..2}; do
  ./slurmspark-submit.sh --class org.apache.spark.examples.SparkPi --executor-memory 1G --total-executor-cores 10 /cluster/software/spark/spark-1.6.0-bin-hadoop2.6/lib/spark-examples-1.6.0-hadoop2.6.0.jar 10 &> slurmspark_job_${i}.out &
done
