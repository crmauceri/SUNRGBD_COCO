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

% SUNRGBDtoolbox_root = '/Users/Mauceri_1/Workspace/SUNRGBDtoolbox';
% SUNRGBDdata_root = '/Users/Mauceri_1/Workspace/SUNRGBD/images/';
% COCOAPI_MatlabAPI = '/Users/Mauceri_1/Workspace/cocoapi/';
% savedir = '.';

% Add paths to helper functions
addpath(genpath(SUNRGBDtoolbox_root));
addpath([COCOAPI_MatlabAPI '/MatlabAPI']);

% Template for annotation dictionary
annotate = struct('category_id', [], 'area', [], 'bbox', [], 'id', [], 'image_id', [], ...
    'mask_name', [], 'segmentation', [], 'iscrowd', false, 'classname', []);
% Template for categories dictionary
category = struct('supercategory', [], 'id', [], 'name', [], 'seglist_all_name', [], 'seglist_all_id', []);

% Load SUNRGBD data
load([SUNRGBDtoolbox_root, '/Metadata/SUNRGBDMeta2DBB_v2.mat']);
load([SUNRGBDtoolbox_root, '/traintestSUNRGBD/allsplit.mat']);

%% Cleaned category labels
% Load cleaned labels
seg_ids = readtable('seglistall.csv');
categories(size(seg_ids, 1)) = category;
category_index = cell(size(seg_ids, 1), 3); % Index for seglistall -> categories

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
    [~,Locb] = ismember(lower(id.clean_label), {categories(1:ii-1).name});
    if Locb > 0
        % This category is has the same clean_name as a category that has
        % already been processed
        categories(Locb).seglist_all_name = [categories(Locb).seglist_all_name, id.original_labels{1}]; % Uncleaned label
        categories(Locb).seglist_all_id = [categories(Locb).seglist_all_id, id.seglistallIndex]; % Uncleaned label id
        c = Locb;
    else
        % First time we add this category to the list
        categories(ii).id = ii-1;
        categories(ii).name = id.clean_label{1};
        categories(ii).seglist_all_name = {id.original_labels{1}}; % Uncleaned label
        categories(ii).seglist_all_id = id.seglistallIndex; % Uncleaned label id
        if Locb <= 37
            % If it is a member of the orginal 37, assign it a supercategory name
            % TODO map supercategories for the fine-grained labels
            categories(ii).supercategory = id.clean_label{1};
        end
        c = ii;
        ii = ii + 1;
    end
    
    % Make an index for seglistall -> categories
    category_index{jj, 3} = lower(id.original_labels);
    category_index{jj, 1} = id.seglistallIndex;
    category_index{jj, 2} = c;
end

categories = categories(1:ii-1);

%% Split data into train/val/test based on contents of '/traintestSUNRGBD/allsplit.mat'
train = find(startsWith(replace({SUNRGBDMeta2DBB.sequenceName}, '/', ''), ...
    replace(replace(trainvalsplit.train, '/n/fs/sun3d/data/', ''), '/', '')));
test = find(startsWith(replace({SUNRGBDMeta2DBB.sequenceName}, '/', ''), ...
    replace(replace(alltest, '/n/fs/sun3d/data/', ''), '/', '')));
val = find(startsWith(replace({SUNRGBDMeta2DBB.sequenceName}, '/', ''), ...
    replace(replace(trainvalsplit.val, '/n/fs/sun3d/data/', ''), '/', '')));
datasets = {test, train, val};
splits = {'test', 'train', 'val'};

% Process each split
for set_idx= 1:3
    annotations_idx = 0;
    
    split_name = splits{set_idx};
    split_data = datasets{set_idx};
    
    % Initialize empty images table with size of split
    n_images = length(split_data);
    images = table(cell(n_images, 1), cell(n_images, 1), zeros(n_images, 1), zeros(n_images, 1), zeros(n_images, 1), cell(n_images, 1),...
        'VariableNames', {'file_name', 'depth_file_name', 'height', 'width', 'id', 'split'});
    
    % Estimate number of annotations in dataset by loading each seg.mat
    % file and counting number of labeled segments
    n_objects = 0;
    for ii = split_data
        segpath = sprintf('%s/%s/seg.mat', SUNRGBDdata_root, SUNRGBDMeta2DBB(ii).sequenceName);
        seg = load(segpath);
        n_objects = n_objects + length(seg.names) + length(SUNRGBDMeta2DBB(ii).groundtruth2DBB);
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
        if(~isfield(seg, 'seginstances'))
            seg.seginstances = zeros(size(seg.seglabel));
        end
        
        % Load the image file
        imfile = {sprintf('%s/image/%s', SUNRGBDMeta2DBB(img_idx).sequenceName, SUNRGBDMeta2DBB(img_idx).rgbname)};
        depthfile = {sprintf('%s/depth/%s', SUNRGBDMeta2DBB(img_idx).sequenceName, SUNRGBDMeta2DBB(img_idx).depthname)};
        I = imread([SUNRGBDdata_root imfile{1}]);
        assert(size(seg.seglabel,1) == size(I,1) && size(seg.seglabel,2) == size(I,2), ...
            sprintf('Dimention missmatch with image %d', img_idx));
        
        % Complete the image table entries
        images(ii, :) = table(imfile, depthfile, ...
            size(seg.seglabel, 1), size(seg.seglabel, 2), img_idx, {split_name},...
            'VariableNames', {'file_name', 'depth_file_name', 'height', 'width', 'id', 'split'});
        
        % For each segment in the image
        jj_list = unique(seg.seglabel(seg.seglabel>0))';
        for jj=jj_list
            label_mask = seg.seglabel==jj;
            for kk=unique(seg.seginstances(label_mask))'
                instance_mask = seg.seglabel==jj & seg.seginstances==kk;
                classname = seg.names{jj};
                % Convert to a COCO mask annotation
                annotate = encode_coco_mask(instance_mask, img_idx, sprintf('%d_%d_%d_seg', img_idx, jj, kk), classname, SUNRGBDMeta2DBB);
                if ~isempty(annotate.id)
                    annotations(annotations_idx+1) = annotate;
                    annotations_idx = annotations_idx + 1;
                end
            end
        end
        
        for jj=1:length(SUNRGBDMeta2DBB(img_idx).groundtruth2DBB)
            
            bbox_struct = SUNRGBDMeta2DBB(img_idx).groundtruth2DBB(jj);
            bbox = round([bbox_struct.gtBb2D(1), bbox_struct.gtBb2D(2), ...
                bbox_struct.gtBb2D(1) + bbox_struct.gtBb2D(3), bbox_struct.gtBb2D(2) + bbox_struct.gtBb2D(4)]);
            bbox(bbox<=0) = 1;
            if(bbox(3) > size(seg.seglabel, 2)) bbox(3) = size(seg.seglabel, 2); end
            if(bbox(4) > size(seg.seglabel, 1)) bbox(4) = size(seg.seglabel, 1); end
            
            bbox_mask = zeros(size(seg.seglabel), 'logical');
            bbox_mask(bbox(2):bbox(4), bbox(1):bbox(3)) = 1;
            
            classname = bbox_struct.classname;
            annotate = encode_coco_mask(bbox_mask, img_idx, sprintf('%d_%d', img_idx, jj), classname, SUNRGBDMeta2DBB);
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
    unknown_classes = {};
    
    % For each annotation
    for ii = 1:length(annotations)
        if(mod(ii, 100)==0)
            fprintf('Processed %d annotations\n', ii);
        end
        
        if(endsWith(annotations(ii).id, 'seg'))
            %If annotation from segment
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
                [~, locb] = ismember(category, [category_index{:, 1}]);
                annotations(ii).category_id = categories(category_index{locb, 2}).id;
            else
                % This is an unknown label
                annotations(ii).category_id = categories(1).id;
            end
        else
            %If annotation from bbox
            classname = lower(annotations(ii).classname);
            [~, category] = ismember(annotations(ii).classname, [category_index{:,3}]);
            if category > 0
                %It's in the un-corrected list of names
                annotations(ii).category_id = category;
            else
                [~, category] = ismember(replace(classname, '_', ' '), {categories.name});
                if category > 0
                    % It's in the corrected list of names
                    annotations(ii).category_id = category;
                else
                   % This is an unknown label
                    annotations(ii).category_id = categories(1).id;
                    unknown_classes = [unknown_classes, annotations(ii).classname];
                end
            end
        end
    end
    
    disp(unknown_classes);
    
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