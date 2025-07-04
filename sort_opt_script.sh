#!/bin/bash
#PBS -l nodes=2:ppn=24
#PBS -q default
#PBS -N Folder_Setup
#PBS -e setup.err
#PBS -o setup.out

# Define directories
POTCAR_SOURCE="/c11scratch/shikharkya/High_throughput/potpaw_PBE"
WORK_DIR="$PBS_O_WORKDIR"
SCRIPT_SOURCE="/c11scratch/shikharkya/High_throughput/script_nclV2.sh"

# Function to collect user inputs
collect_inputs() {
    # Initialize arrays
    BASES=()
    DOPANTS=()
    OPERATIONS=()

    echo "=== Enter BASES (0 to finish, 1 to continue) ==="
    while true; do
        read -p "Enter BASE (e.g., ZrSe2): " base
        if [[ "$base" == "0" ]]; then
            break
        elif [[ "$base" == "1" ]]; then
            continue
        else
            BASES+=("$base")
        fi
    done

    echo "=== Enter DOPANTS (0 to finish, 1 to continue) ==="
    while true; do
        read -p "Enter DOPANT (e.g., Au): " dopant
        if [[ "$dopant" == "0" ]]; then
            break
        elif [[ "$dopant" == "1" ]]; then
            continue
        else
            DOPANTS+=("$dopant")
        fi
    done

    echo "=== Enter OPERATIONS (0 to finish, 1 to continue) ==="
    while true; do
        read -p "Enter OPERATION (e.g., adsorption): " operation
        if [[ "$operation" == "0" ]]; then
            break
        elif [[ "$operation" == "1" ]]; then
            continue
        else
            OPERATIONS+=("$operation")
        fi
    done

    # Display collected inputs
    echo "Collected inputs:"
    echo "BASES: ${BASES[@]}"
    echo "DOPANTS: ${DOPANTS[@]}"
    echo "OPERATIONS: ${OPERATIONS[@]}"
}

# Create folder structure and organize files
create_structure() {
    echo "Creating folder structure and organizing files..."
    
    for BASE in "${BASES[@]}"; do
        # Extract elements from BASE (e.g., Zr and Se from ZrSe2)
        TM="${BASE:0:2}"  # Transition metal (first 2 chars)
        DC="${BASE:2}"    # Dichalcogen (remaining chars)
        
        # Verify POTCARs exist for base materials
        if [[ ! -f "${POTCAR_SOURCE}/${TM}/POTCAR" || ! -f "${POTCAR_SOURCE}/${DC}/POTCAR" ]]; then
            echo "Skipping ${BASE} - missing base POTCARs"
            continue
        fi
        
        for DOPANT in "${DOPANTS[@]}"; do
            # Verify dopant POTCAR exists
            if [[ ! -f "${POTCAR_SOURCE}/${DOPANT}/POTCAR" ]]; then
                echo "Skipping ${DOPANT} - missing POTCAR"
                continue
            fi
            
            for OPERATION in "${OPERATIONS[@]}"; do
                # Create directory path
                DIR_PATH="${WORK_DIR}/${BASE}/${DOPANT}/${OPERATION}"
                mkdir -p "$DIR_PATH"
                
                # Create combined POTCAR with original name
                POTCAR_ORIG_NAME="POTCAR_${DOPANT}_${BASE}_${OPERATION}"
                cat "${POTCAR_SOURCE}/${TM}/POTCAR" \
                    "${POTCAR_SOURCE}/${DC}/POTCAR" \
                    "${POTCAR_SOURCE}/${DOPANT}/POTCAR" > "${DIR_PATH}/${POTCAR_ORIG_NAME}"
                
                # Find and move corresponding CIF file
                CIF_ORIG_NAME="${DOPANT}_${BASE}_${OPERATION}.cif"
                find "$WORK_DIR" -maxdepth 1 -name "$CIF_ORIG_NAME" -exec mv {} "$DIR_PATH/" \;
                
                # Copy the VASP script
                if [[ -f "$SCRIPT_SOURCE" ]]; then
                    cp "$SCRIPT_SOURCE" "${DIR_PATH}/script_nclV2.sh"
                    chmod +x "${DIR_PATH}/script_nclV2.sh"
                else
                    echo "Warning: script_nclV2.sh not found at $SCRIPT_SOURCE"
                fi
                
                # Rename files to standard VASP names
                if [[ -f "${DIR_PATH}/${CIF_ORIG_NAME}" ]]; then
                    mv "${DIR_PATH}/${CIF_ORIG_NAME}" "${DIR_PATH}/POSCAR"
                    echo "Renamed ${CIF_ORIG_NAME} to POSCAR"
                fi
                
                if [[ -f "${DIR_PATH}/${POTCAR_ORIG_NAME}" ]]; then
                    mv "${DIR_PATH}/${POTCAR_ORIG_NAME}" "${DIR_PATH}/POTCAR"
                    echo "Renamed ${POTCAR_ORIG_NAME} to POTCAR"
                fi
                
                echo "Created ${DIR_PATH} with:"
                [[ -f "${DIR_PATH}/POSCAR" ]] && echo "  - POSCAR"
                [[ -f "${DIR_PATH}/POTCAR" ]] && echo "  - POTCAR"
                [[ -f "${DIR_PATH}/script_nclV2.sh" ]] && echo "  - script_nclV2.sh"
            done
        done
    done
}

# Main execution
echo "Starting interactive input collection..."
collect_inputs

echo "Starting folder structure creation..."
create_structure
echo "Folder structure creation completed."

# Generate a summary file
echo "Generating summary..."
find "$WORK_DIR" -type f \( -name "POSCAR" -o -name "POTCAR" \) -printf "%p\n" > "${WORK_DIR}/file_organization_summary.txt"
echo "Summary saved to ${WORK_DIR}/file_organization_summary.txt" 
