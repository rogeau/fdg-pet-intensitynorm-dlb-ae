function create_individual_masks(patient_dir, control_dir)
    spm('defaults', 'PET');
    original_dir = pwd; 
    % Recursively find patient and control NIfTI files
    patient_paths = dir(fullfile(patient_dir, '**', 's_gm_w_realigned.nii'));
    control_paths = dir(fullfile(control_dir, '**', 's_gm_w_realigned.nii'));

    % Convert control paths to proper format for SPM
    control_files = fullfile({control_paths.folder}, {control_paths.name});
    control_files = strcat(control_files, ',1');

    % Loop through each patient
    for d = 1:length(patient_paths)
        % Get current patient file
        PET_file = fullfile(patient_paths(d).folder, patient_paths(d).name);
        PET_file = [PET_file ',1'];  % SPM volume index

        % Set target folder to the same as the patient's file location
        parent_folder = patient_paths(d).folder;
        target_folder = fullfile(parent_folder, 'individual_mask_analysis');       
        if ~exist(target_folder, 'dir')
            mkdir(target_folder);
        end

        clear matlabbatch

        % 1. Factorial design
        matlabbatch{1}.spm.stats.factorial_design.dir = {target_folder};
        matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = control_files';
        matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = {PET_file};
        matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 1;
        matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;
        matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;
        matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
        matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
        matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {'masks/GM.nii,1'};
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_mean = 1;
        matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
        matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 2;

        % 2. Model estimation
        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', ...
            substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
            substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

        % 3. Contrast definition
        matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', ...
            substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
            substruct('.','spmmat'));
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = 'Hypo/hyper';
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = [1 -1];
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
        matlabbatch{3}.spm.stats.con.delete = 1;

        % 4. Results export
        matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', ...
            substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
            substruct('.','spmmat'));
        matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
        matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'none';
        matlabbatch{4}.spm.stats.results.conspec.thresh = 0.01;
        matlabbatch{4}.spm.stats.results.conspec.extent = 0;
        matlabbatch{4}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{4}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{4}.spm.stats.results.units = 1;
        matlabbatch{4}.spm.stats.results.export{1}.binary.basename = 'hypo_hyper_mask';
        matlabbatch{4}.spm.stats.results.export{2}.ps = true;

        original_mask = fullfile(target_folder, 'mask.nii');
        hypo_hyper_mask = fullfile(target_folder, 'spmF_0001_hypo_hyper_mask.nii');

        matlabbatch{5}.spm.util.imcalc.input = {original_mask; hypo_hyper_mask};
        matlabbatch{5}.spm.util.imcalc.output = 'individual_mask';
        matlabbatch{5}.spm.util.imcalc.outdir = {parent_folder};
        matlabbatch{5}.spm.util.imcalc.expression = 'i1 - i2';
        matlabbatch{5}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{5}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{5}.spm.util.imcalc.options.mask = -1;
        matlabbatch{5}.spm.util.imcalc.options.interp = 1;
        matlabbatch{5}.spm.util.imcalc.options.dtype = 2;

        spm_jobman('run', matlabbatch);
        cd(original_dir);
    end
end