# SUNRGBD_COCO
A small set of tools to convert SUNRGBD matlab files to coco annotation format

## Introduction 

The [coco dataset](https://cocodataset.org/) defines a [json structured data format](https://cocodataset.org/#format-data) which can represent several different annotation formats. Many dataset loaders exist for coco such as the [cocoapi](https://github.com/cocodataset/cocoapi) which make it a convenient annotation format to use. 

The SUNRGBD dataset is stored as a complicated file structure and a couple of large Matlab files. It's not convenient to use. 

This repo does the following 

- Creates struct arrays to correspond to the complete coco json data format for object detection annotation. 
- Uses the cocoapi Mask tools to convert the segmentation masks from each SUNRGBD image's seg.mat file into RLE masks. The seg.mat file contains instance segmentation.
- Manually cleans up the seglistall segmentation labels with some basic spell checking (seglistall.csv)

Demo.ipynb contains a short example of loading the resulting json files with the cocoapi

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

If you have encoding errors when loading the resulting json files with coco, you can use this python snippet to re-encode the files with utf8

```
with open('instances_val.json', 'r', encoding='iso-8859-1') as f:
    jsonstr = f.read()

with open('instances_val.json', 'w') as f:
    f.write(jsonstr)
```

## Download processed data

If you just want a copy of the coco annotations, you can download the json files from the following links.

- [instances_train.json](https://drive.google.com/file/d/1YLReQfsbA2BZ0BKebBsrCCiqSbMypXCI/view?usp=sharing)
- [instances_val.json](https://drive.google.com/file/d/175rAn0JWpy78mVbro4UzjDyd9Psm463O/view?usp=sharing)
- [instances_test.json](https://drive.google.com/file/d/1igBAX1Z1Nl3dgJ5AtW5mm6fnOBvc1Frk/view?usp=sharing)

## Details of resulting annotation 

Here are the details for each json field and where they differ from the coco annotation format

```
image[{
	"id": int, 		# Same as original index in SUNRGBD2Dseg.mat or SUNRGBDMeta2DBB_v2.mat
	"width": int,
	"height": int,
	"file_name": str, 	# SUNRGBDMeta2DBB(id).sequenceName + /image/ + SUNRGBDMeta2DBB(id).rgbname
	"depth_file_name": str, 	# Not part of COCO annotation
				# SUNRGBDMeta2DBB(id).sequenceName + /depth/ +  SUNRGBDMeta2DBB(id).depthname
}]
```

The image field does not include the coco fields "license", "flickr_url", "coco_url", or "date_captured".

```
categories[{
	"id": int, 		# 0 is unknown, 1-37 correspond to seg37list, >37 contain rest of seglistall.csv labels
	"name": str, 		# cleaned name from seglistall.csv
	"supercategory": str, 	# seg37list category if it exists
	"seglist_all_name": list(str),	# Not part of COCO annotation, all un-cleaned names from seglistall which correspond to this entry
	"seglist_all_id": list(int)	# Not part of COCO annotation, all index in seglistall which correspond to this entry
}]
```

Some category ids occur multiple times as they correspond to the same clean `name` but different `seglist_all_id`s.


```
annotations[{
	"id": int, 			# "<image_id>_<seg_index>" where seg_index is the index in seg.mat
	"image_id": int,
	"category_id": int, 		# Explained in more detail above
	"segmentation": RLE,
	"area": float,
	"bbox": [x,y,width,height], 	# Calculated from segmentation mask
	"iscrowd": False 		# No iscrowd annotations exist for SUNRGBD, but I believe all seg.mat masks are instance annotations
	"mask_name": 			# Not part of COCO annotation, SUNRGBDMeta2DBB(image_id).sequenceName
}]
```

### (Optional) Choose your own clean labels

I started the cleaning process by loading the csv file in Excel and using the spell correction tools. 
I also changed some frequent and obvious synonyms (bookcase vs bookshelf), standardized spacing (bookcase vs book case), and removed some adjectives (white book).

There are still many incorrect labels. You can further clean the category labels by updating seglistall.csv

WARNING: Be cautious about labels that you are unfamiliar with! "teapoi" is a three legged table, not a misspelling of "teapot". "airpot" is a kind of coffee thermos. I did not look at the source images while doing my round of spelling corrections, so I may have made some false assumptions, but I tried to be very conservative. 

One other idea that I had, but haven't gotten around to, is using WordNet or some other resource to hierarchically cluster labels into super-categories. 