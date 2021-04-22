# SUNRGBD_COCO
A small set of tools to convert SUNRGBD matlab files to coco annotation format

## Prerequisites: 

1. Download all the [SUNRGBD](https://rgbd.cs.princeton.edu/) zip files from  including updated annotation files
   - [https://rgbd.cs.princeton.edu/data/SUNRGBDtoolbox.zip](https://rgbd.cs.princeton.edu/data/SUNRGBDtoolbox.zip)
   - [https://rgbd.cs.princeton.edu/data/SUNRGBD.zip](https://rgbd.cs.princeton.edu/data/SUNRGBD.zip)
   - [https://rgbd.cs.princeton.edu/data/SUNRGBDMeta2DBB_v2.mat](https://rgbd.cs.princeton.edu/data/SUNRGBDMeta2DBB_v2.mat)

2. Download [cocoapi](https://github.com/cocodataset/cocoapi)

## Running the script

```
SUNRGB_to_COCO(SUNRGBDtoolbox_root, SUNRGBDdata_root, COCOAPI_MatlabAPI, savedir)
Parameters:  SUNRGBDtoolbox_root      root directory of SUNRGBDtoolbox 
             SUNRGBDdata_root         root directory of SUNRGBD dataset
             COCOAPI_root             root directory of cocoapi
             savedir                  directory where the coco annoations should be
                                      saved
```