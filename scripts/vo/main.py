#! /usr/bin/env python3

import os

import numpy as np
import cv2
import argparse
import yaml
import logging, coloredlogs
from tqdm import tqdm

from utils.tools import plot_keypoints
from utils.vis_helpers import plot_histograms
from utils.io_utils import create_folders, delete_folders

from DataLoader import create_dataloader
from Detectors import create_detector
from Matchers import create_matcher
from VO.VisualOdometry import VisualOdometry, AbosluteScaleComputer
from DataLoader import ZEDLoader
import time
import matplotlib.pyplot as plt
import fnmatch
import shutil
import random
 



def keypoints_plot(img, vo):
    if img.shape[2] == 1:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)
    return plot_keypoints(img, vo.kptdescs["cur"]["keypoints"], vo.kptdescs["cur"]["scores"])


'''
[TO-DO]
- tune script
- error-handling
  - vineyards/front_2024-06-05-09-48-13.svo
- add image extraction for selected segments
- abstract frame sequence extraction to support different interfaces
- implement class interface
- support for multiple base folders in testing
- prepare final demo-test case folder with well-distributed dataset
- make testing end to end
- handling large continuos valid segment
- single / multiple svo viable patch extraction 
- add visualization functions
- visualisze + extract the viable patch lengths 
- sampling viable segments
- integrate with main.sh
'''


''''
[TESTING STATUS]
- miscellaneous [IN PROGRESS]
- vineyards * 
  - RJM -> []
  - wente-test -> []
  - gallo -> []
- blueberry
    - 1A -> []
    - 1B -> []
- apple
    - agrimacs 
    - quincy_fresh
    - rj_orchards
    - wsu_washington
- raisins
- dairy 
'''

'''
DEMO SVO FILES
- front_2023-11-03-10-51-17.svo [miscellaneous]
- add one camera crash
'''


'''
[IMPORTANT SVO FILES]
    
- CAMERA COVER CRASH / E-CRASH
    - vineyards/RJM/
        - front_2024-06-05-09-48-13.svo
'''


def write_seq_to_disk(input_dir : str, sequences : tuple, output_dir = "outputs"):
    
    input_dir_ = os.path.join("test_imgs/sequences/00/", input_dir)

    img_N = len([file for file in os.listdir(input_dir_) if file.endswith('.png')]) 
    # logging.info(f"num_images: {img_N}")   
    
    images_list = os.listdir(input_dir_)
    filtered_files = fnmatch.filter(images_list, "left_*.png")
    sorted_images = sorted(filtered_files, key=lambda x: int(x.split('_')[1].split('.')[0]))
    
    # updating sorted images with full path
    for i, image in enumerate(sorted_images):
        image = os.path.join(input_dir_, image) 
        sorted_images[i] = image

    output_dir = os.path.join(output_dir, input_dir)
    for (st,en) in tqdm(sequences):
        output_dir_ = os.path.join(output_dir, f"{st}_{en}")
    
        # logging.warning(f"output_dir: {output_dir_}")
        
        delete_folders([output_dir_])
        create_folders([output_dir_])
        
        for i in range(st, en + 1):
            # logging.info(f"{i}: {sorted_images[i]}")
            shutil.copy(sorted_images[i], output_dir_)    
    


def run(args, svo_folder_path):
    with open(args.config, 'r') as f:
        config = yaml.load(f, Loader=yaml.FullLoader)
        # config = yaml.load(f)

    # loader = create_dataloader(config["dataset"], INPUT_FOLDER_PATH)
    # dataloader_config = {
    #     "prefix_input_folder" : "output-backend/vo",
    #     "input_folder" : "escalon"
    # }

    loader = ZEDLoader.KITTILoader(config, svo_folder_path)
    
    detector = create_detector(config["detector"])
    matcher = create_matcher(config["matcher"])

    absscale = AbosluteScaleComputer()
    # traj_plotter = TrajPlotter(RESET_IDX)

    # log
    # fname = args.config.split('/')[-1].split('.')[0]
    # log_fopen = open("results/" + fname + ".txt", mode='a')

    logging.warning("=======================")
    # logging.info(f"fname: {fname}")
    zed_camera = loader.cam
    for attr, value in zed_camera.__dict__.items():
        logging.info(f"{attr}: {value}")
    logging.warning("=======================")
                
    # vo = VisualOdometry(detector, matcher, loader.cam)
    # vo = VisualOdometry(detector, matcher, zed_camera, RESET_IDX)
    total_frames = len(loader)
    vo = VisualOdometry(detector, matcher, zed_camera, total_frames)

    
    # x = enumerate(loader)
    
    # for i, img in tqdm(enumerate(loader), total=len(loader)):
    for i, img in enumerate(loader):
        # gt_pose = loader.get_cur_pose()
        # R, t = vo.update(img, absscale.update(gt_pose))
        
        # logging.warning(f"{i} / {total_frames} img.shape: {img.shape} ")
        logging.warning(f"PROCESSING [{i} / {total_frames}] FRAME")
        
       
        
        R, t = vo.update(img)
        
        img1 = keypoints_plot(img, vo)
        # img2 = traj_plotter.update(t)

        cv2.imshow("keypoints", img1)
        # cv2.imshow("trajectory", img2)
        if cv2.waitKey(10) == 27:
            break

    cv2.destroyAllWindows()
    
    logging.info("=======================")
    logging.info("VO HAS FINISHED!")
    logging.info("=======================")
    
    return vo


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='python_vo')    
    parser.add_argument('--config', type=str, default='scripts/vo/params/kitti_superpoint_flannmatch.yaml',
                        help='config file')
    
    args = parser.parse_args()
    coloredlogs.install(level='INFO', force=True)
    
    with open(args.config, 'r') as f:
        config = yaml.load(f, Loader=yaml.FullLoader)
    
    # ROOT_FOLDER ="output-backend/vo/"s
    ROOT_FOLDER = config['dataset']['root_folder']
    logging.warning(f"ROOT_FOLDER: {ROOT_FOLDER}")
    PREFIX_FOLDER = "escalon/"
    INPUT_PATH = os.path.join(ROOT_FOLDER, PREFIX_FOLDER)

    # relative paths for svo files w.r.t. {PREFIX_FOLDER}/{IMAGES_FOLDER}
    svo_folders_rel = []

    for dirpath, dirnames, filenames in os.walk(INPUT_PATH):
        # Check if the current directory is a base folder (no sub-folders)
        if not dirnames:
            # Calculate the relative path of the base folder
            relative_path = os.path.relpath(dirpath, os.path.join(ROOT_FOLDER))
            # logging.info(f"Relative path of base folder: {relative_path}")       
            svo_folders_rel.append(relative_path)

    # number of svo folders to test
    CUTOFF_NUM_FOLDERS = 5
        
    random.shuffle(svo_folders_rel)

    logging.info("=======================")
    logging.info("FOLLOWING SVO FOLDERS WILL BE TESTED")
    
    for i, folder in enumerate(svo_folders_rel):
        if i > CUTOFF_NUM_FOLDERS:
            break
        logging.info(f"[{i}] {folder}")
    
    logging.info("=======================\n")
        
    time.sleep(2)
    # exit(1)
    for i, svo_folder in enumerate(svo_folders_rel):
        logging.error("=======================")
        logging.error(f"STARTING VO FOR [{i} / {len(svo_folders_rel)}] FOLDER!")
        logging.error("=======================")
        time.sleep(5)
        
        vo  = run(args, svo_folder)  
        # seq_list = vo.get_viable_sequences()
        # plot_histograms(seq_list)

        # (st1, en1), (st2, en2), ...
        seq_tuples = vo.get_sequence_pairs()

        logging.info("=======================")
        logging.info("SAVING SEQUENCES TO DISK!")
        logging.info("=======================")
        
        time.sleep(1)
        
        # write_seq_to_disk(folder, seq_tuples)

    logging.info("=======================")
    logging.info("DELETING THE INPUT SVO FOLDERS!")
    logging.info("=======================")
    
    # delete_folders(svo_folders_abs)
        