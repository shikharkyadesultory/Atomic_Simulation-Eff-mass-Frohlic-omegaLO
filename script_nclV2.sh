#PBS -l nodes=2:ppn=24
#PBS -q default
#PBS -N Script_nclV2.sh
#PBS -e Auto_job.err
#PBS -o Auto_job.out

echo "PBS JOB ID is $PBS_JOBID"
echo "PBS NODEFILE is $PBS_NODEFILE"
echo "PBS QUEUE is $PBS_QUEUE"
cat $PBS_NODEFILE

cd $PBS_O_WORKDIR
. /opt/parallel_studio_xe_2016/start.sh intel64

VASP=/c11scratch/vasp.5.4.1/build/ncl/vasp
NP=48
MPI="/opt/intel/parallel_studio_xe_2016/compilers_and_libraries_2016.2.181/linux/mpi/intel64/bin/mpirun -hostfile $PBS_NODEFILE -np $NP"

run_vasp() {
    step_dir=$1
    echo "Running VASP in $step_dir ..."
    cd $step_dir
    cp ../POTCAR .
    $MPI $VASP | tee vasp.out
    cd ..
}


run_vasp 01_OPTIM

cp 01_OPTIM/CONTCAR 02_SCF/POSCAR
run_vasp 02_SCF

cp 02_SCF/CHGCAR 03_DOS/
cp 02_SCF/WAVECAR 03_DOS/
run_vasp 03_DOS

cp 02_SCF/CHGCAR 04_BANDS/
cp 02_SCF/WAVECAR 04_BANDS/
run_vasp 04_BANDS

echo "All VASP steps completed successfully."


