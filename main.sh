#!/bin/bash

<<comment
[TO-DO]
- implement svo-filter.py
- integrate svo-filter.py with main.sh	

[LATER]
- add colmap cmake update to support pycolmap installtion 
- retag colmap , pycolmap
- update requirements.txt
- update pipeline tag
- documentation
	- update release notes
	- update installation steps
	- add + update setup.md
	- add readme.md
	- update colmap installation steps in setup.md
- refactoring
	- add python-scripts / bash-scripts
	- refactor script folders into separate modules
- new scripts
	- add main-ws.sh, main-aws.sh
	- aws integration
	- add status-processed / unprocessed folders for user feeback
	- add segmentation inference script
	- move output-backend ---> output script
	- add folder / file support
	- add parent + child config file/script
	- python for config parsing
	- output/input-backend clean-up
- add images / video support
- check if script is being executed from the project root
- dense reconstruction support for multiple gpus
- [error-handling / folder deletion] for Ctrl-C / unexpected script termination 
- update default bb params for pointcloud cropping
- extract baseline from the svo file
- user feedback mechanism 
- temp file deletion sttrategy
- include zed baseline extraction

comment

# ---------------------------------------------
# [GLOBAL PARAMS]
# ---------------------------------------------
EXIT_FAILURE=1
EXIT_SUCCESS=0
COLMAP_EXE_PATH=/usr/local/bin

# ---------------------------------------------
# [PIPELINE PARAMS]
# ---------------------------------------------
PIPELINE_SCRIPT_DIR="scripts"
PIPELINE_CONFIG_DIR="config"

PIPELINE_INPUT_BACKEND_FOLDER="input-backend"
PIPELINE_OUTPUT_BACKEND_FOLDER="output-backend"


# =============================================
# [PIPELINE EXECUTION STARTS FROM HERE]
# =============================================


# ---------------------------------------------
# [VIRTUAL ENVIRONMENT CHECK]
# ---------------------------------------------
if [[ "$VIRTUAL_ENV" == "" ]]
then
    echo "No virtual environment found. Terminating script."
    exit 1
fi

# ---------------------------------------------
# [PARSING CONFIG FILE]
# ---------------------------------------------
USER_INPUT=$(python -c '
import config.config as cfg
print(cfg.SVO_FILENAME)
')



INPUT_PATH="${PIPELINE_INPUT_BACKEND_FOLDER}/svo-files/${USER_INPUT}"


echo "INPUT_PATH: $INPUT_PATH"

# FILES_TO_PROCESS=()
# # Check if USER_INPUT is a directory or a file
# if [ -d "$INPUT_PATH" ]; then
#     # It's a directory, find all .svo files and append them to the FILES_TO_PROCESS array
#     while IFS= read -r -d '' file; do
#         FILES_TO_PROCESS+=("$file")
#     done < <(find "$INPUT_PATH" -type f -name "*.svo" -print0)
# elif [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" == *.svo ]]; then
#     # It's a single file ending with .svo, append it directly
#     FILES_TO_PROCESS+=("$USER_INPUT")
# else
#     echo "USER_INPUT is not a .svo file or a directory."
#     exit 1
# fi

# python3 scripts.utils_module.io_utils.get --input_path=$INPUT_PATH

echo "HELLO"

output=$(python3 -c "
import scripts.utils_module.io_utils as io; 
print(io.get_file_list('${INPUT_PATH}'))
")

IFS=',' read -r -a OUTPUT_ARRAY <<< "$output"

# Iterate over the array and echo each string
for item in "${OUTPUT_ARRAY[@]}"; do
    echo "$item"
done

exit 1


# =============================================
# [STEP #1 ==> EXTRACT STEREO-IMAGES FROM SVO FILE]
# =============================================

INPUT_FOLDER_SVO="${PIPELINE_INPUT_BACKEND_FOLDER}/svo-files"
OUTPUT_FOLDER_SVO="${PIPELINE_INPUT_BACKEND_FOLDER}/stereo-images"

INPUT_PATH_SVO="${INPUT_FOLDER_SVO}/${SVO_FILENAME}"
OUTPUT_PATH_SVO="${OUTPUT_FOLDER_SVO}/${SVO_FILENAME}"

# ---------------------------------------------
# EXTARCTING 1 SVO FRAME per {SVO_STEP} FRAMES
# ---------------------------------------------
SVO_STEP=2

echo -e "\n"
echo "==============================="
echo "[SVO PROCESSING --> EXTRACTING IMAGES]"
echo "INPUT_FOLDER_SVO: $INPUT_FOLDER_SVO"
echo "OUTPUT_FOLDER_SVO: $OUTPUT_FOLDER_SVO"
echo "INPUT_PATH_SVO: $INPUT_PATH_SVO"
echo "OUTPUT_PATH_SVO: $OUTPUT_PATH_SVO"
echo "==============================="
echo -e "\n"

# ---------------------------------------------
# IGNORE IF $OUTPUT_PATH_SVO ALREADY EXISTS
# ---------------------------------------------
if [ ! -d "$OUTPUT_PATH_SVO" ]; then

	START_TIME=$(date +%s) 
	python3 "${PIPELINE_SCRIPT_DIR}/svo-to-stereo-images.py" \
		--svo_path=$INPUT_PATH_SVO \
		--output_dir=$OUTPUT_PATH_SVO \
		--svo_step=$SVO_STEP

	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME)) 

	if [ $? -eq 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "Time taken for SVO TO STEREO-IMAGES generation: ${DURATION} seconds"
		echo "==============================="
		echo -e "\n"
	else
		echo -e "\n"
		echo "[ERROR] SVO TO STEREO-IMAGES FAILED ==> EXITING PIPELINE!"
		echo -e "\n"
		rm -rf ${SVO_IMAGES_DIR}
		exit $EXIT_FAILURE
	fi
else
	echo -e "\n"
	echo "[WARNING] SKIPPING svo to stereo-images generation as ${SVO_IMAGES_DIR} already exists."
	echo "[WARNING] Delete [${SVO_IMAGES_DIR}] folder and try again!"
	echo -e "\n"
fi



# =============================================
# [STEP #A ==> EXTRACT STEREO-IMAGES FROM SVO FILE]
# =============================================
INPUT_FOLDER_SVO="${PIPELINE_INPUT_BACKEND_FOLDER}/svo-files"
OUTPUT_FOLDER_SVO="${PIPELINE_OUTPUT_BACKEND_FOLDER}/stereo-images"

INPUT_PATH_SVO="${INPUT_FOLDER_SVO}/${SVO_FILENAME}"
OUTPUT_PATH_SVO="${OUTPUT_FOLDER_SVO}/${SVO_FILENAME}"

# ---------------------------------------------
# EXTARCTING 1 SVO FRAME per {SVO_STEP} FRAMES
# ---------------------------------------------
SVO_STEP=2

echo -e "\n"
echo "==============================="
echo "[SVO PROCESSING --> EXTRACTING IMAGES]"
echo "INPUT_FOLDER_SVO: $INPUT_FOLDER_SVO"
echo "OUTPUT_FOLDER_SVO: $OUTPUT_FOLDER_SVO"
echo "INPUT_PATH_SVO: $INPUT_PATH_SVO"
echo "OUTPUT_PATH_SVO: $OUTPUT_PATH_SVO"
echo "==============================="
echo -e "\n"

# ---------------------------------------------
# IGNORE IF $OUTPUT_PATH_SVO ALREADY EXISTS
# ---------------------------------------------
if [ ! -d "$OUTPUT_PATH_SVO" ]; then

	START_TIME=$(date +%s) 
	python3 "${PIPELINE_SCRIPT_DIR}/svo-to-stereo-images.py" \
		--svo_path=$INPUT_PATH_SVO \
		--output_dir=$OUTPUT_PATH_SVO \
		--svo_step=$SVO_STEP

	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME)) 

	if [ $? -eq 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "Time taken for SVO TO STEREO-IMAGES generation: ${DURATION} seconds"
		echo "==============================="
		echo -e "\n"
	else
		echo -e "\n"
		echo "[ERROR] SVO TO STEREO-IMAGES FAILED ==> EXITING PIPELINE!"
		echo -e "\n"
		rm -rf ${SVO_IMAGES_DIR}
		exit $EXIT_FAILURE
	fi
else
	echo -e "\n"
	echo "[WARNING] SKIPPING svo to stereo-images generation as ${SVO_IMAGES_DIR} already exists."
	echo "[WARNING] Delete [${SVO_IMAGES_DIR}] folder and try again!"
	echo -e "\n"
fi


# =============================================
# [STEP #2 ==> EXTRACT VIABLE SEGMENTS USING VO]
# =============================================




# [STEP #2 --> SPARSE-RECONSTRUCTION FROM STEREO-IMAGES] 
SPARSE_RECON_INPUT_DIR="${PIPELINE_INPUT_BACKEND_FOLDER}/sparse-reconstruction/${SVO_FILENAME}/${SUB_FOLDER_NAME}"
SPARSE_RECON_OUTPUT_DIR="${PIPELINE_OUTPUT_BACKEND_FOLDER}/sparse-reconstruction/${SVO_FILENAME}/${SUB_FOLDER_NAME}"

echo -e "\n"
echo "==============================="
echo "[SVO STEREO IMAGES --> SPARSE RECONSTRUCTION]"
echo "SPARSE_RECON_INPUT_DIR: $SPARSE_RECON_INPUT_DIR"
echo "SPARSE_RECON_OUTPUT_DIR: $SPARSE_RECON_OUTPUT_DIR"
echo "==============================="
echo -e "\n"

if [ ! -d "$SPARSE_RECON_OUTPUT_DIR" ]; then

	START_TIME=$(date +%s) 

	python3 "${PIPELINE_SCRIPT_DIR}/sparse-reconstruction.py" \
	    --svo_images=$SVO_IMAGES_DIR \
		--input_dir=$SPARSE_RECON_INPUT_DIR \
		--output_dir=$SPARSE_RECON_OUTPUT_DIR \
		--svo_file=$SVO_FILE_PATH  

	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME)) 

	# [SPARSE-RECONSTRUCTION CHECK]
	if [ $? -eq 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "Time taken for SPARSE-RECONSTRUCTION: ${DURATION} seconds"
		echo "==============================="
		echo -e "\n"
	else
		echo -e "\n"
		echo "[ERROR] STEREO-RECONSTRUCTION FAILED ==> EXITING PIPELINE!"
		echo -e "\n"
		rm -rf ${SPARSE_RECON_OUTPUT_DIR}
		return $EXIT_FAILURE
	fi
else 
	echo -e "\n"
	echo "[WARNING] SKIPPING stereo-images to sparse-reconstruction as ${SPARSE_RECON_OUTPUT_DIR} already exists."
	echo "[WARNING] Delete [${SPARSE_RECON_OUTPUT_DIR}] folder and try again!"
	echo -e "\n"
fi

# [STEP #3 --> RIG-BUNDLE-ADJUSTMENT]
RBA_INPUT_DIR="${SPARSE_RECON_OUTPUT_DIR}/ref_locked/"
RBA_OUTPUT_DIR="${PIPELINE_OUTPUT_DIR}/rig-bundle-adjustment/${SVO_FILENAME}/${SUB_FOLDER_NAME}"
RBA_CONFIG_PATH="${PIPELINE_CONFIG_DIR}/rig.json"

echo -e "\n"
echo "==============================="
echo "[RIG BUNDLE ADJUSTMENT]"
echo "RBA_INPUT_DIR: $RBA_INPUT_DIR"
echo "RBA_OUTPUT_DIR: $RBA_OUTPUT_DIR"
echo "RBA_CONFIG_PATH: $RBA_CONFIG_PATH"
echo "==============================="
echo -e "\n"

if [ ! -d "$RBA_OUTPUT_DIR" ]; then

	rm -rf "${RBA_OUTPUT_DIR}"
	mkdir -p "${RBA_OUTPUT_DIR}"

	START_TIME=$(date +%s) 

	$COLMAP_EXE_PATH/colmap rig_bundle_adjuster \
		--input_path $RBA_INPUT_DIR \
		--output_path $RBA_OUTPUT_DIR \
		--rig_config_path $RBA_CONFIG_PATH \
		--BundleAdjustment.refine_focal_length 0 \
		--BundleAdjustment.refine_principal_point 0 \
		--BundleAdjustment.refine_extra_params 0 \
		--BundleAdjustment.refine_extrinsics 1 \
		--BundleAdjustment.max_num_iterations 500 \
		--estimate_rig_relative_poses False

	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME)) 

	# [RBA CONVERGENCE CHECK]
	if [ $? -ne 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "RBA FAILED ==> EXITING PIPELINE!"
		echo "==============================="
		echo -e "\n"
		rm -rf "${RBA_OUTPUT_DIR}"
		exit $EXIT_FAILURE
	fi

	# [VERIFYING RBA RESULTS]
	python3 "${PIPELINE_SCRIPT_DIR}/rba_check.py" \
		--rba_output=$RBA_OUTPUT_DIR

	# [RBA RESULTS CHECK]
	if [ $? -eq 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "Time taken for RIG-BUNDLE-ADJUSTMENT: ${DURATION} seconds"
		echo "==============================="
		echo -e "\n"
	else
		echo -e "\n"
		echo "[ERROR] RIG-BUNDLE-ADJUSTMENT FAILED ==> EXITING PIPELINE!"
		echo -e "\n"
		rm -rf "${RBA_OUTPUT_DIR}"
		exit $EXIT_FAILURE
	fi

else
	echo -e "\n"
	echo "[WARNING] SKIPPING rig-bundle-adjustment as ${RBA_OUTPUT_DIR} already exists."
	echo "[WARNING] Delete [${RBA_OUTPUT_DIR}] folder and try again!"
	echo -e "\n"
fi

# [STEP #4 --> DENSE RECONSTRUCTION]
DENSE_RECON_OUTPUT_DIR="${PIPELINE_OUTPUT_DIR}/dense-reconstruction/${SVO_FILENAME}/${SUB_FOLDER_NAME}"

if [ ! -d "$DENSE_RECON_OUTPUT_DIR" ]; then

	START_TIME=$(date +%s) 

	python3 "${PIPELINE_SCRIPT_DIR}/dense-reconstruction.py" \
	--mvs_path="$DENSE_RECON_OUTPUT_DIR" \
	--output_path="$RBA_OUTPUT_DIR" \
	--image_dir="$SPARSE_RECON_INPUT_DIR"

	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME)) 

	if [ $? -eq 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "Time taken for dense-reconstruction: ${DURATION} seconds"
		echo "==============================="
		echo -e "\n"
	else
		echo -e "\n"
		echo "[ERROR] DENSE-RECONSTRUCTION FAILED ==> EXITING PIPELINE!"
		echo -e "\n"
		rm -rf ${DENSE_RECON_OUTPUT_DIR}
		return $EXIT_FAILURE
	fi

else 
	echo -e "\n"
	echo "[WARNING] SKIPPING dense-reconstruction as ${DENSE_RECON_OUTPUT_DIR} already exists."
	echo "[WARNING] Delete [${DENSE_RECON_OUTPUT_DIR}] folder and try again!"
	echo -e "\n"
fi

# [STEP #5 --> FRAME-TO-FRAME (CROPPED) POINTCLOUD GENERATION]
P360_MODULE="p360"
BOUNDING_BOX="-5 5 -1 1 -1 1"
CAMERA_FRAME_PCL="${PIPELINE_OUTPUT_DIR}/pointcloud-camera-frame/${SVO_FILENAME}/${SUB_FOLDER_NAME}"
CAMERA_FRAME_PCL_CROPPED="${PIPELINE_OUTPUT_DIR}/pointcloud-cropped-camera-frame/${SVO_FILENAME}/${SUB_FOLDER_NAME}"

if [ -d "$CAMERA_FRAME_PCL" ] && [ -d "$CAMERA_FRAME_PCL_CROPPED" ]; then
	echo -e "\n"
	echo "[WARNING] SKIPPING frame-wise pointcloud generation as ${CAMERA_FRAME_PCL} and ${CAMERA_FRAME_PCL_CROPPED} already exist."
	echo "[WARNING] Delete [${CAMERA_FRAME_PCL}] or [${CAMERA_FRAME_PCL_CROPPED}] and try again!"
	echo -e "\n"
else 
	START_TIME=$(date +%s) 

	python3 -m ${PIPELINE_SCRIPT_DIR}.${P360_MODULE}.main \
	--bounding_box $BOUNDING_BOX \
	--dense_reconstruction_folder="${DENSE_RECON_OUTPUT_DIR}" \
	--pcl_folder="${CAMERA_FRAME_PCL}" \
	--pcl_cropped_folder="${CAMERA_FRAME_PCL_CROPPED}"
	
	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME)) 

	if [ $? -eq 0 ]; then
		echo -e "\n"
		echo "==============================="
		echo "Time taken for generating frame-wise pointclouds: ${DURATION} seconds"
		echo "==============================="
		echo -e "\n"
	else
		echo -e "\n"
		echo "[ERROR] FRAME-BY-FRAME POINTCLOUD GENERATION FAILED ==> EXITING PIPELINE!"
		echo -e "\n"
		rm -rf ${CAMERA_FRAME_PCL}
		rm -rf ${CAMERA_FRAME_PCL_CROPPED}
		exit $EXIT_FAILURE
	fi
fi

exit $EXIT_SUCCESS