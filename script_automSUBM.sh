 -l nodes=1:ppn=1
#PBS -q default
#PBS -N Job_Submitter
#PBS -j oe

# (My High_throughput directory)/ user should update by his/her own ;-)
ROOT_DIR="/c11scratch/shikharkya/High_throughput"

# Job submission counter
TOTAL_JOBS=0
SUCCESS_JOBS=0
FAILED_JOBS=0

# Main submission function
submit_jobs() {
    # Find all optim directories and submit jobs
    find "$ROOT_DIR" -type d -name "optim" | while read -r OPTIM_DIR; do
        (
            # Change to the optim directory
            cd "$OPTIM_DIR" || exit
            
            # Check if the script exists and hasn't been run before
            if [[ -f "script_nclV2.sh" && ! -f "job_completed.flag" ]]; then
                echo "Submitting job in directory: $OPTIM_DIR"
                
                # Submit the job and capture the job ID
                JOB_ID=$(qsub script_nclV2.sh)
                
                # Create job tracking files
                echo "Job submitted at $(date)" > job_submission.log
                echo "Job ID: $JOB_ID" >> job_submission.log
                echo "Directory: $(pwd)" >> job_submission.log
                
                # Increment counters
                ((TOTAL_JOBS++))
                ((SUCCESS_JOBS++))
                
                echo "Successfully submitted job $JOB_ID"
            elif [[ -f "job_completed.flag" ]]; then
                echo "Skipping already completed job in: $OPTIM_DIR"
                ((TOTAL_JOBS++))
            else
                echo "Warning: script_nclV2.sh not found in $OPTIM_DIR"
                ((TOTAL_JOBS++))
                ((FAILED_JOBS++))
            fi
        )
    done
}

# Main execution
echo "Starting job submission process from $ROOT_DIR..."
echo "Searching for all optim directories..."

submit_jobs

echo ""
echo "Job submission summary:"
echo "Total directories processed: $TOTAL_JOBS"
echo "Successfully submitted jobs: $SUCCESS_JOBS"
echo "Failed submissions: $FAILED_JOBS"
echo "Already completed jobs: $((TOTAL_JOBS - SUCCESS_JOBS - FAILED_JOBS))"
echo ""
echo "Job submission process completed."

