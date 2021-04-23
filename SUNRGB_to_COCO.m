function SUNRGB_to_COCO(SUNRGBDtoolbox_root, SUNRGBDdata_root, COCOAPI_MatlabAPI, savedir)
%% SUNRGB_to_COCO converts SUNRGBD segmentation annotations to COCO annotation format
% Prerequisites: 
% 1. Download all the SUNRGBD zip files from https://rgbd.cs.princeton.edu/
% including updated annotation files
%   - https://rgbd.cs.princeton.edu/data/SUNRGBDtoolbox.zip
%   - https://rgbd.cs.princeton.edu/data/SUNRGBD.zip
%   - https://rgbd.cs.princeton.edu/data/SUNRGBDMeta2DBB_v2.mat
% 2. Download cocoapi
%   - https://github.com/cocodataset/cocoapi
%
% Parameters:  SUNRGBDtoolbox_root      root directory of SUNRGBDtoolbox 
%              SUNRGBDdata_root         root directory of SUNRGBD dataset
%              COCOAPI_root             root directory of cocoapi
%              savedir                  directory where the coco annoations should be
%                                       saved

% Add paths to helper functions
addpath(genpath(SUNRGBDtoolbox_root));
addpath([COCOAPI_MatlabAPI '/MatlabAPI']);

% Template for annotation dictionary
annotate = struct('category_id', [], 'area', [], 'bbox', [], 'id', [], 'image_id', [], ...
    'mask_name', [], 'segmentation', [], 'iscrowd', false);
% Template for categories dictionary
category = struct('supercategory', [], 'id', [], 'name', [], 'seglist_all_name', [], 'seglist_all_id', []);

% Load SUNRGBD data
load([SUNRGBDtoolbox_root, '/Metadata/SUNRGBDMeta2DBB_v2.mat']);
load([SUNRGBDtoolbox_root, '/traintestSUNRGBD/allsplit.mat']);

%% Cleaned category labels
% Load cleaned labels
seg_ids = readtable('seglistall.csv');
categories(size(seg_ids, 1)) = category;

% Index unique clean labels which maintaining order of first 37 labels
% These 37 are the seg37list prioritized by Song et al. 
clean_names = unique(lower(seg_ids.clean_label), 'stable');
clean_names = ['unknown'; clean_names];

% Add unknown label for id == 0
categories(1).supercategory = 'unknown';
categories(1).id = 0;
categories(1).seglist_all_id = 0;
categories(1).name = 'unknown';
categories(1).seglist_all_name = {'unknown'};

% For each original label in seglistall, create an entry in `categories`
ii = 2;
for jj = 1:size(seg_ids,1)
    id = seg_ids(jj, :);
    % Find the new label id in the clean_names list
    [~,Locb] = ismember(lower(id.clean_label), clean_names);
    if Locb < ii
        % This category is has the same clean_name as a category that has
        % already been processed
        categories(Locb).seglist_all_name = [categories(Locb).seglist_all_name, id.original_labels{1}]; % Uncleaned label
        categories(Locb).seglist_all_id = [categories(Locb).seglist_all_id, id.seglistallIndex]; % Uncleaned label id
    else
        % First time we add this category to the list
        categories(ii).id = ii-1;
        categories(ii).name = id.clean_label{1};
        categories(ii).seglist_all_name = {id.original_labels{1}}; % Uncleaned label
        categories(ii).seglist_all_id = id.seglistallIndex; % Uncleaned label id
        if Locb <= 37
            % If it is a member of the orginal 37, assign it a supercategory name
            % TODO map supercategories for the fine-grained labels
            categories(ii).supercategory = clean_names{Locb};
        end
        ii = ii + 1;
    end
end

%% Split data into train/val/test based on contents of '/traintestSUNRGBD/allsplit.mat'
train = find(ismember({SUNRGBDMeta2DBB.sequenceName}, replace(trainvalsplit.train, '/n/fs/sun3d/data/', '')));
test = find(ismember({SUNRGBDMeta2DBB.sequenceName}, replace(alltest, '/n/fs/sun3d/data/', '')));
val = find(ismember({SUNRGBDMeta2DBB.sequenceName}, replace(trainvalsplit.val, '/n/fs/sun3d/data/', '')));
datasets = {test, train, val};
splits = {'test', 'train', 'val'};

% Process each split 
for set_idx= 1:3
    annotations_idx = 0;
    
    split_name = splits{set_idx};
    split_data = datasets{set_idx};

    % Initialize empty images table with size of split
    n_images = length(split_data);
    images = table(cell(n_images, 1), cell(n_images, 1), zeros(n_images, 1), zeros(n_images, 1), zeros(n_images, 1), 'VariableNames', {'file_name', 'depth_file_name', 'height', 'width', 'id'});

    % Estimate number of annotations in dataset by loading each seg.mat
    % file and counting number of labeled segments
    n_objects = 0;
    for ii = split_data
        segpath = sprintf('%s/%s/seg.mat', SUNRGBDdata_root, SUNRGBDMeta2DBB(ii).sequenceName);
        seg = load(segpath);
        n_objects = n_objects + length(seg.names);
    end
    % Initialize empty annotations struct array with number of objects
    annotations(n_objects) = annotate;

    % For each image in the split
    for ii = 1:length(split_data)
        img_idx = split_data(ii);
        if(mod(ii, 100)==0)
            fprintf('Processed %d images\n', ii);
        end

        % Load the segmentation file
        % The seg.mat file contains instance segmentation
        segpath = sprintf('%s/%s/seg.mat', SUNRGBDdata_root, SUNRGBDMeta2DBB(img_idx).sequenceName);
        seg = load(segpath);

        % Load the image file
        imfile = {sprintf('%s/image/%s', SUNRGBDMeta2DBB(img_idx).sequenceName, SUNRGBDMeta2DBB(img_idx).rgbname)};
        depthfile = {sprintf('%s/depth/%s', SUNRGBDMeta2DBB(img_idx).sequenceName, SUNRGBDMeta2DBB(img_idx).depthname)};
        I = imread([SUNRGBDdata_root imfile{1}]);
        assert(size(seg.seglabel,1) == size(I,1) && size(seg.seglabel,2) == size(I,2), ...
            sprintf('Dimention missmatch with image %d', img_idx));

        % Complete the image table entries 
        images(ii, :) = table(imfile, depthfile, ...
            size(seg.seglabel, 1), size(seg.seglabel, 2), img_idx, ...
            'VariableNames', {'file_name', 'depth_file_name', 'height', 'width', 'id'});

        % For each segment in the image
        jj_list = 1:length(seg.names);
        for jj=jj_list
            % Convert to a COCO mask annotation
            annotate = encode_coco_mask(seg.seglabel==jj, img_idx, sprintf('%d_%d_seg', img_idx, jj), SUNRGBDMeta2DBB);
            if ~isempty(annotate.id)
                annotations(annotations_idx+1) = annotate;
                annotations_idx = annotations_idx + 1;
            end
        end
    end
    % Remove extra rows from annotations array
    annotations(annotations_idx+1:end) = [];

    %% Collect segment labels
    % We do this seperately than the COCO mask annotation convertion
    % because SUNRGBDMeta2DBB and SUNRGBD2Dseg are too big to both be
    % loaded in memory at the same time
    clear SUNRGBDMeta2DBB;
    load([SUNRGBDtoolbox_root, '/Metadata/SUNRGBD2Dseg.mat']);

    % For each annotation
    for ii = 1:length(annotations)
        if(mod(ii, 100)==0)
            fprintf('Processed %d annotations\n', ii);
        end
        % Decode the mask
        mask = MaskApi.decode(annotations(ii).segmentation);
        % Check what category is assigned to this annotation in SUNRGBD2Dseg
        category = unique(SUNRGBD2Dseg(annotations(ii).image_id).seglabelall(mask==1));
        % If there is more than one category, there is a mismatch
        % between the seg.mat file and the SUNRGBD2Dseg file.
        % This shouldn't happen!
        assert(any(size(category)==1))
        % Look up the category id in the categories table. 
        % This translates the seglabelall id to the cleaned label ids.
        if category > 0 
            [~, locb] = ismember(category, [categories.seglist_all_id]);
            annotations(ii).category_id = categories(locb).id;
        else
            % This is an unknown label
            annotations(ii).category_id = categories(1).id;
        end
    end

    % Save Results
    instances = struct('categories',  categories, 'images', images, 'annotations', annotations);
    fw = fopen(sprintf('%s/instances_%s.json', savedir, split_name), 'w', 'n','UTF-8');
    fwrite(fw, jsonencode(instances));
    fclose(fw);

    save(sprintf('%s/instances_%s.mat', savedir, split_name), 'instances');
    
    clear SUNRGBD2Dseg
    load([SUNRGBDtoolbox_root, '/Metadata/SUNRGBDMeta2DBB_v2.mat']);
end

end