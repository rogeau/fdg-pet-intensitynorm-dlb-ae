function spatialNorm(input_dir)
    nii_files = dir(fullfile(input_dir, '**', '*.nii'));

    template = fullfile(pwd, 'template', 'PET.nii');

    output_pdf = fullfile(input_dir, 'norm_QC.pdf');
    if exist(output_pdf, 'file')
        delete(output_pdf);
    end

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
        matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.template = {template};
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

        norm_image = fullfile(nii_files(i).folder, ['w_' nii_files(i).name]);
	
	spm_check_registration(template, norm_image);
        fig = spm_figure('FindWin', 'Graphics');
	
	[filepath_parent, file_name, ext] = fileparts(file_path);
	[filepath_gdparent, parent_folder] = fileparts(filepath_parent);
	[~, gdparent_folder] = fileparts(filepath_gdparent);

	full_title = sprintf('Spatial Norm QC for: %s/%s/%s%s', gdparent_folder, parent_folder, ['w_' nii_files(i).name]);
	sgtitle(full_title, 'Interpreter', 'none', 'FontWeight', 'bold', 'FontSize', 10);
        exportgraphics(fig, output_pdf, 'Append', true, 'ContentType', 'image');
    end
    close all;

    % spm check reg saves a .ps file automatically, this is to remove it
    delete(fullfile(pwd, 'spm*.ps'));
end

