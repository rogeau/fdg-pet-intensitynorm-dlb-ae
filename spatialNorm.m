function spatialNorm(input_dir)
    nii_files = dir(fullfile(input_dir, '**', '*.nii'));

    for i = 1:length(nii_files)
        file_path = fullfile(nii_files(i).folder, nii_files(i).name);
        
        if ~exist(file_path, 'file')
            warning('File not found: %s. Skipping.', file_path);
            continue;
        end
        
        fprintf('🧭 Spatial Normalization... %s\n', file_path);

        clear matlabbatch
        matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.source = {file_path};
        matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
        matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.resample = {file_path};
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.template = {'/home/arogeau/Desktop/spm12/toolbox/OldNorm/PET.nii,1'};
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 8;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smoref = 0;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.bb = [-90 -126 -72; 90 90 108];
        matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.vox = [2 2 2];
        matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
        matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w_';

        spm_jobman('run', matlabbatch);
    end
end

