function [annotate]=encode_coco_mask(mask, ii_idx, ann_id, SUNRGBDMeta2DBB)
    annotate = struct('category_id', [], 'area', [], 'bbox', [], 'id', [], 'image_id', [], ...
        'mask_name', [], 'segmentation', [], 'iscrowd', false);
    
    annotate.area = sum(mask(:));
    if(annotate.area > 1)
        [y, x] = find(mask);
        annotate.bbox = [min(x), min(y), max(x)-min(x), max(y)-min(y)];

        if(max(x)-min(x) > 0 && max(y)-min(y)>0)
            annotate.image_id = ii_idx;
            annotate.mask_name = SUNRGBDMeta2DBB(ii_idx).sequenceName;
            annotate.segmentation =  MaskApi.encode(uint8(mask));
            annotate.id = ann_id;
        end
    end
end