function std_smooth(input_dir)
    nii_files = dir(fullfile(input_dir, '**', '*w_realigned.nii'));

    for i = 1:length(nii_files)
        file_path = fullfile(nii_files(i).folder, nii_files(i).name);
        
        if ~exist(file_path, 'file')
            warning('File not found: %s. Skipping.', file_path);
            continue;
        end
        
        fprintf('🧠 Smoothing... %s\n', file_path);

        clear matlabbatch
	matlabbatch{1}.spm.spatial.smooth.data = {file_path};
	matlabbatch{1}.spm.spatial.smooth.fwhm = [8 8 8];
	matlabbatch{1}.spm.spatial.smooth.dtype = 0;
	matlabbatch{1}.spm.spatial.smooth.im = 0;
	matlabbatch{1}.spm.spatial.smooth.prefix = 's_';
	spm_jobman('run', matlabbatch);
    end
end
