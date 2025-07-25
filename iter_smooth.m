function iter_smooth(patient_dir, threshold)
    if nargin < 2
        threshold = 0.01;
    end
    threshold = str2double(threshold);
    threshold_str = strrep(num2str(threshold, '%.15g'), '.', '');
    nii_files = dir(fullfile(patient_dir, '**', sprintf('iter%s_w_realigned.nii', threshold_str)));

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
