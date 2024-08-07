#!/usr/bin/env python3

import pyzed.sl as sl
import os
import shutil
import json
import sys
import argparse
import warnings
from pathlib import Path
import coloredlogs, logging
from tqdm import tqdm
from typing import List

from scripts.utils_module import io_utils

def get_baseline(svo_path : str) -> float:
    
    input_type = sl.InputType()
    input_type.set_from_svo_file(svo_path)

    init = sl.InitParameters(input_t=input_type, svo_real_time_mode=False)
    init.coordinate_units = sl.UNIT.METER   

    zed = sl.Camera()
    status = zed.open(init)

    if status != sl.ERROR_CODE.SUCCESS:
        logging.error(f"Error while opening the SVO file: {repr(status)} --> [USING BASELINE AS 0.13]")
        return 0.13

    camera_information = zed.get_camera_information()
    zed_baseline =   camera_information.camera_configuration.calibration_parameters.get_camera_baseline()
    # Get camera information (calibration parameters)
    # calibration_params = zed.get_camera_information().camera_configuration.calibration_parameters
    # left_cam = calibration_params.left_cam
    # right_cam = calibration_params.right_cam

    # baseline = abs(right_cam.tx - left_cam.tx)
    zed.close()
    return zed_baseline


def generate_rig_json(rig_file : str, svo_file : str):

    '''
    updating rig.json with zed baseline
    '''    

    
    new_value = get_baseline(svo_file) 
    new_value = 0.15
    # Load the JSON data
    with open(rig_file, 'r') as file:
        data = json.load(file)

    # Update the rel_tvec's first value
    # new_value = 0.15  # Example new value
    
    for rig in data:
        for camera in rig['cameras']:
            if camera['camera_id'] == 1:
                camera['rel_tvec'][0] = new_value
            
    # Optionally, write the updated data back to the file
    # io_utils.delete_files([rig_file])
    # io_utils.create_folders([os.path.dirname(rig_file)])
    
    with open(rig_file, 'w') as file:
        json.dump(data, file, indent=4)

def extract_vo_stereo_images(filepath, output_folder, svo_step = 2):
    
    # logging.warning(f"[svo-to-stereo-images.py]")
    logging.info(f"Saving images at [{output_folder}] with a step of [{svo_step}]")
    filepath = os.path.abspath(filepath)
    output_path = os.path.abspath(output_folder)

    # logging.info(f"filepath: {filepath} output_path: {output_path}")

    # logging.info(f"svo_file: {filepath}")
    
    input_type = sl.InputType()
    input_type.set_from_svo_file(filepath)


    init = sl.InitParameters(input_t=input_type, svo_real_time_mode=False)
    init.coordinate_units = sl.UNIT.METER   

    zed = sl.Camera()
    status = zed.open(init)
    if status != sl.ERROR_CODE.SUCCESS:
        print(repr(status))
        exit()

    runtime_parameters = sl.RuntimeParameters()

    image_l = sl.Mat()
    image_r = sl.Mat()
    
    total_frames = zed.get_svo_number_of_frames()
    # logging.info(f"Extracting {(end - start) // svo_step} stereo-images from the SVO file!")
    logging.info(f"Extracting {total_frames // svo_step} stereo-images from the SVO file!")
    
    io_utils.delete_folders([os.path.join(output_path)])
    io_utils.create_folders([os.path.join(output_path)])
    

    for frame_idx in tqdm(range(0, total_frames, svo_step)):
        try:
            if zed.grab(runtime_parameters) == sl.ERROR_CODE.SUCCESS:
                zed.set_svo_position(frame_idx)
                zed.retrieve_image(image_l, sl.VIEW.LEFT)
                zed.retrieve_image(image_r, sl.VIEW.RIGHT)
                image_l.write( os.path.join(output_path, f'frame_{frame_idx}.png') )
        except Exception as e:
            logging.error(f"Error while processing svo frame: {e}")
            break
        # else:
        #     sys.exit(1)
    zed.close()



def get_camera_params(svo_file : str) -> dict: 
 
    input_type = sl.InputType()
    input_type.set_from_svo_file(svo_file)

    init = sl.InitParameters(input_t=input_type, svo_real_time_mode=False)
    init.coordinate_units = sl.UNIT.METER   

    zed = sl.Camera()
    status = zed.open(init)
    if status != sl.ERROR_CODE.SUCCESS:
        print(repr(status))
        exit()

    calibration_params = zed.get_camera_information().camera_configuration.calibration_parameters
    # Focal length of the left eye in pixels
    fx = calibration_params.left_cam.fx
    fy = calibration_params.left_cam.fy

    
    # Principal point of the left eye in pixels
    cx = calibration_params.left_cam.cx
    cy = calibration_params.left_cam.cy

    
    camera_params = {
        'fx' : fx, 
        'fy' : fy,
        'cx' : cx, 
        'cy' : cy 
    }

    return camera_params
    
if __name__ == "__main__":

    coloredlogs.install(level="DEBUG", force=True)  # install a handler on the root logger

    # parser = argparse.ArgumentParser(description='Script to process a SVO file')
    # parser.add_argument('--svo_path', type=str, required = True, help='target svo file path')
    # parser.add_argument('--output_dir', type=str, required = True, help='output directory path')
    # parser.add_argument('--svo_step', type=int, required = False, default = 2, help='frame skipping frequency')  
    # args = parser.parse_args()  

    svo_file = "input-backend/svo-files/vineyards/RJM/front_2024-06-05-09-48-13.svo"
    # generate_rig_json("config/rig.json", "input-backend/svo-files/vineyards/RJM/front_2024-06-05-09-48-13.svo")
    baseline = get_baseline(svo_file)
    logging.warning(f"baseline: {baseline}")
    # logging.warning(f"[svo-to-stereo-images.py]")
    # for key, value in vars(args).items():
    #     logging.info(f"{key}: {value}")
    
    # # main(Path(args.svo_path), Path(args.output_dir), args.svo_step)
    # logging.warning(f"svo_path: {args.svo_path}")
    # # {fx, fy, cx, cy}
    # camera_params = get_camera_params(args.svo_path)