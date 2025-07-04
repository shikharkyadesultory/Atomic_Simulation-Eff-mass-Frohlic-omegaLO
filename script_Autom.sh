#!/bin/bash
#PBS -l nodes=2:ppn=24
#PBS -q default
#PBS -N Autom_script
#PBS -e test.err
#PBS -o test.out

echo PBS JOB id is $PBS_JOBID
echo PBS_NODEFILE is $PBS_NODEFILE
echo PBS_QUEUE is $PBS_QUEUE
cat $PBS_NODEFILE

cd $PBS_O_WORKDIR

# Loading the latest Python version to avoid execution jargon
. /opt/parallel_studio_xe_2016/start.sh intel64
module load python/3.6
echo "Remember the operations are of 3 types 1.) Adsorption 2.)Defect 3.)defsub ."
# Defining my OWN POTCAR directory user must specify his/her own
POTCAR_DIR="/c11scratch/shikharkya/High_throughput/potpaw_PBE"

# User input for creation of POTCAR
create_potcar() {
    read -p "Enter Transition Metal in TMDC (e.g., Zr_sv, Ti): " TM
    read -p "Enter Dichalcogen in TMDC (e.g., S, Se, Te): " DC
    read -p "Enter Dopant (e.g., Au, Pt, Bi): " DOPANT
    read -p "Enter Base Formula (e.g. ZrS2, ZrSe2,ZrTe2)"BASE
    read -p "Enter Operation being performed: " OPERATION
    
    # To favour the search and sort POTCAR filenames are kept unique
    POTCAR_FILE="POTCAR_${DOPANT}_${BASE}_${OPERATION}"
    
    # Verify POTCAR files existance
    if [[ ! -f "${POTCAR_DIR}/${TM}/POTCAR" ]]; then
        echo "Error: ${POTCAR_DIR}/${TM}/POTCAR not found check potpaw_PBE for some different format!"
        return 1
    fi
    if [[ ! -f "${POTCAR_DIR}/${DC}/POTCAR" ]]; then
        echo "Error: ${POTCAR_DIR}/${DC}/POTCAR not found check potpaw_PBE for some different format!"
        return 1
    fi
    if [[ ! -f "${POTCAR_DIR}/${DOPANT}/POTCAR" ]]; then
        echo "Error: ${POTCAR_DIR}/${DOPANT}/POTCAR not found check potpaw_PBE for some different format!"
        return 1
    fi
    
    # Create combined POTCAR
    cat "${POTCAR_DIR}/${TM}/POTCAR" \
        "${POTCAR_DIR}/${DC}/POTCAR" \
        "${POTCAR_DIR}/${DOPANT}/POTCAR" > "${POTCAR_FILE}"
    
    echo "Created POTCAR file: ${POTCAR_FILE}"
    return 0
}

while true; do
    echo "Starting new calculation..."
    

    while ! create_potcar; do
        echo "Please try again with valid elements."
    done
    
    # Execute Python script (convert notebook if needed ipynb -> py)
    if [[ -f "High_Throughput_Pythonscipt.ipynb" ]]; then
        jupyter nbconvert --to script High_Throughput_Pythonscript.ipynb
        python3.6 High_Throughput_Pythonscript.py
    else
        echo "Python script not found!"
        break
    fi
    
    #USER's choice 
    read -p "Do you want to run another calculation? (y/n): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        break
    fi
done

echo "Calculation Completed.... ;--) CHILL and run sort _opt_script."
