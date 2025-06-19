function std_intensity_norm(input_dir)
    nii_files = dir(fullfile(input_dir, '**', 'w_realigned.nii'));

    % Load ref regions
    wfu_path = 'reference_regions/wfu.nii';
    wfu_header = spm_vol(wfu_path);
    wfu = spm_read_vols(wfu_header);

    gm_path = 'reference_regions/GM.nii';
    gm_header = spm_vol(gm_path);
    gm = spm_read_vols(gm_header);

    output_pdf = fullfile(input_dir, 'intensity_QC.pdf');
    if exist(output_pdf, 'file')
        delete(output_pdf);
    end

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

        % Save images for QC
        mid_x = round(size(pet_vol, 1) / 2);  % Sagittal (X)
        mid_z = round(size(pet_vol, 3) / 2);  % Axial (Z)

	orig_sag = flipud(squeeze(pet_vol(mid_x, :, :))');
	pons_sag = flipud(squeeze(pons_mask(mid_x, :, :))');
        intersect_sag = orig_sag .* double(pons_sag);

	orig_ax = flipud(squeeze(pet_vol(:, :, mid_z))');
	gm_ax = flipud(squeeze(gm_mask(:, :, mid_z))');
        intersect_ax = orig_ax .* double(gm_ax);

        fig = figure('Name', 'Sagittal & Axial Visualization', 'NumberTitle', 'off');
        colormap gray;

        subplot(2, 3, 1);
        imagesc(orig_sag); axis image off;
        title('Original');
        subplot(2, 3, 2);
        imagesc(pons_sag); axis image off;
        title('WFU Pons');
        subplot(2, 3, 3);
        imagesc(intersect_sag); axis image off;
        title('Intersection');

        % Bottom row: axial
        subplot(2, 3, 4);
        imagesc(orig_ax); axis image off;
        title('Original');

        subplot(2, 3, 5);
        imagesc(gm_ax); axis image off;
        title('GM');

        subplot(2, 3, 6);
        imagesc(intersect_ax); axis image off;
        title('Intersection');

	[filepath_parent, file_name, ext] = fileparts(file_path);
	[filepath_gdparent, parent_folder] = fileparts(filepath_parent);
	[~, gdparent_folder] = fileparts(filepath_gdparent);

	full_title = sprintf('Intensity Norm QC for: %s/%s/%s%s', gdparent_folder, parent_folder, nii_files(i).name);
	sgtitle(full_title, 'Interpreter', 'none', 'FontWeight', 'bold', 'FontSize', 10);

        exportgraphics(fig, output_pdf, 'Append', true, 'ContentType', 'image');
        close(fig);
    end
end
