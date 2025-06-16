function center_mass(input_dir, output_dir, info_excel)
    info_table = readtable(info_excel, 'TextType', 'string');
    nii_files = dir(fullfile(input_dir, '*.nii'));

    for n = 1:length(nii_files)
        file_path = fullfile(input_dir, nii_files(n).name);
        [~, name_only, ~] = fileparts(nii_files(n).name);

        fprintf('🎯 Realignment... %s\n', file_path);

        match_idx = find(info_table.SeriesUID == name_only, 1);
        if isempty(match_idx)
            warning("❌ No SeriesUID match for file: %s. Skipping.", nii_files(n).name);
            continue;
        end

        patient_id = info_table.PatientID(match_idx);
        study_date = info_table.StudyDate(match_idx);

        V = spm_vol(file_path);
        Y = spm_read_vols(V);

        [i, j, k] = ind2sub(size(Y), find(Y > 0));
        if isempty(i)
            warning("⚠️ File %s has no non-zero voxels. Skipping.", nii_files(n).name);
            continue;
        end
        x = mean(i); y = mean(j); z = mean(k);
        mm = V.mat * ([x; y; z; 1] + [1; 1; 1; 0]);

        for vi = 1:numel(V)
            V(vi).mat(1:3, 4) = V(vi).mat(1:3, 4) - mm(1:3);
        end

        out_subdir = fullfile(output_dir, patient_id, study_date);
        if ~exist(out_subdir, 'dir')
            mkdir(out_subdir);
        end

        out_path = char(fullfile(out_subdir, 'realigned.nii'));
        for vi = 1:numel(V)
            V(vi).fname = out_path;
        end
        spm_write_vol(V, Y);
        fprintf(' Saved to %s\n', out_path);
    end
end
