function iter_intensity_norm(patient_dir, threshold)
    if nargin < 2
        threshold = 0.01;
    end
    threshold = str2double(threshold);
    threshold_str = strrep(num2str(threshold, '%.15g'), '.', '');
    nii_files = dir(fullfile(patient_dir, '**', 'w_realigned.nii'));

    output_pdf = fullfile(patient_dir, sprintf('iter%s_intensity_QC.pdf', threshold_str));
    if exist(output_pdf, 'file')
        delete(output_pdf);
    end

    for i = 1:length(nii_files)
        file_path = fullfile(nii_files(i).folder, nii_files(i).name);
	    mask_path = fullfile(nii_files(i).folder, sprintf('individual_mask%s.nii', threshold_str));

        if ~exist(file_path, 'file')
            warning('File not found: %s. Skipping.', file_path);
            continue;
        end

        fprintf('📈 Iterative Intensity Normalization... %s\n', file_path);

        pet_hdr = spm_vol(file_path);
        pet_vol = spm_read_vols(pet_hdr);

    	mask_hdr = spm_vol(mask_path);
        P = char(pet_hdr.fname, mask_hdr.fname);  % PET first = reference
        flags = struct('interp', 0, 'wrap', [0 0 0], 'mask', 0, 'which', 1, 'mean', 0);
        spm_reslice(P, flags);
        resliced_mask_path = fullfile(nii_files(i).folder, sprintf('rindividual_mask%s.nii', threshold_str));
        mask_hdr = spm_vol(resliced_mask_path);
        mask_vol = spm_read_vols(mask_hdr);
        mask = logical(mask_vol);
        mask_mean = mean(pet_vol(mask), 'omitnan');

        if mask_mean == 0 || isnan(mask_mean)
            warning('⚠️ Mask mean is zero or NaN in %s. Skipping GM normalization.', file_path);
        else
            norm_gm = pet_vol / mask_mean;
            gm_hdr = pet_hdr;
            [~, name, ext] = fileparts(nii_files(i).name);
            gm_hdr.fname = fullfile(nii_files(i).folder, [sprintf('iter%s_', threshold_str) name ext]);
            spm_write_vol(gm_hdr, norm_gm);
        end

        % Save images for QC
        mid_z = round(size(pet_vol, 3) / 2);  % Axial (Z)

	    orig_ax = flipud(squeeze(pet_vol(:, :, mid_z))');
	    gm_ax = flipud(squeeze(mask(:, :, mid_z))');
        intersect_ax = orig_ax .* double(gm_ax);

        fig = figure('Name', 'Axial Visualization', 'NumberTitle', 'off');
        colormap gray;


        % Bottom row: axial
        subplot(1, 3, 1);
        imagesc(orig_ax); axis image off;
        title('Original');

        subplot(1, 3, 2);
        imagesc(gm_ax); axis image off;
        title('Individual mask');

        subplot(1, 3, 3);
        imagesc(intersect_ax); axis image off;
        title('Intersection');

	    [filepath_parent, ~, ~] = fileparts(file_path);
	    [filepath_gdparent, parent_folder] = fileparts(filepath_parent);
	    [~, gdparent_folder] = fileparts(filepath_gdparent);
    
	    full_title = sprintf('Iterative intensity Norm QC for: %s/%s/%s%s', gdparent_folder, parent_folder, nii_files(i).name);
	    sgtitle(full_title, 'Interpreter', 'none', 'FontWeight', 'bold', 'FontSize', 10);

        exportgraphics(fig, output_pdf, 'Append', true, 'ContentType', 'image');
        close(fig);
    end
end