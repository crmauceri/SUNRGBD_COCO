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

## Download processed data

If you just want a copy of the coco annotations, you can download the json files from the following links.

- [instance_train.json](https://drive.google.com/file/d/1YLReQfsbA2BZ0BKebBsrCCiqSbMypXCI/view?usp=sharing)
- [instance_val.json](https://drive.google.com/file/d/175rAn0JWpy78mVbro4UzjDyd9Psm463O/view?usp=sharing)
- [instance_test.json](https://drive.google.com/file/d/1igBAX1Z1Nl3dgJ5AtW5mm6fnOBvc1Frk/view?usp=sharing)