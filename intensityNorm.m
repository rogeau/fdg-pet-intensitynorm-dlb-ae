function intensityNorm(input_dir)
    nii_files = dir(fullfile(input_dir, '**', 'w_realigned.nii'));

    % Load wfu mask (pons = 7)
    wfu_path = 'masks/wfu.nii';
    wfu_header = spm_vol(wfu_path);
    wfu = spm_read_vols(wfu_header);

    % Load GM mask (GM = 1)
    gm_path = 'masks/GM.nii';
    gm_header = spm_vol(gm_path);
    gm = spm_read_vols(gm_header);

    for i = 1:length(nii_files)
        file_path = fullfile(nii_files(i).folder, nii_files(i).name);

        if ~exist(file_path, 'file')
            warning('File not found: %s. Skipping.', file_path);
            continue;
        end

        fprintf('📈 Intensity Normalization... %s\n', file_path);

        pet_hdr = spm_vol(file_path);
        pet_vol = spm_read_vols(pet_hdr);

        pons_mask = (wfu == 7);
        pons_mean = mean(pet_vol(pons_mask), 'omitnan');

        if pons_mean == 0 || isnan(pons_mean)
            warning('⚠️ Pons mean is zero or NaN in %s. Skipping pons normalization.', file_path);
        else
            norm_pons = pet_vol / pons_mean;
            pons_hdr = pet_hdr;
            [~, name, ext] = fileparts(nii_files(i).name);
            pons_hdr.fname = fullfile(nii_files(i).folder, ['pons_' name ext]);
            spm_write_vol(pons_hdr, norm_pons);
        end

        gm_mask = (gm == 1);
        gm_mean = mean(pet_vol(gm_mask), 'omitnan');

        if gm_mean == 0 || isnan(gm_mean)
            warning('⚠️ GM mean is zero or NaN in %s. Skipping GM normalization.', file_path);
        else
            norm_gm = pet_vol / gm_mean;
            gm_hdr = pet_hdr;
            [~, name, ext] = fileparts(nii_files(i).name);
            gm_hdr.fname = fullfile(nii_files(i).folder, ['gm_' name ext]);
            spm_write_vol(gm_hdr, norm_gm);
        end
    end
end

