import argparse
import nibabel as nib
import numpy as np
import pandas as pd
from pathlib import Path
from scipy.ndimage import binary_erosion
from extract_rois_GM import extract_rois_GM

def get_data_labels(atlas_path, labels_path):
    atlas_img = nib.load(atlas_path)
    atlas_data = atlas_img.get_fdata()
    affine = atlas_img.affine

    labels = {}
    with open(labels_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('['):
                continue

            parts = line.split()
            label_id = int(parts[0])
            label_name = ' '.join(parts[1:-3])

            labels[label_id] = label_name

    region_ids = sorted([k for k in labels.keys() if k != 0])

    return atlas_data, labels, region_ids, affine

def erode_atlas_regions(atlas_data, region_ids):
    eroded_atlas = np.zeros_like(atlas_data, dtype=atlas_data.dtype)

    for region_id in region_ids:
        region_mask = (atlas_data == region_id)
        voxel_count_before = np.sum(region_mask)

        eroded_mask = np.zeros_like(region_mask)

        for z in range(region_mask.shape[2]):
            slice_mask = region_mask[:, :, z]
            if np.any(slice_mask):  # Skip empty slices
                eroded_slice = binary_erosion(slice_mask)
                eroded_mask[:, :, z] = eroded_slice

        voxel_count_after = np.sum(eroded_mask)
        voxels_removed = voxel_count_before - voxel_count_after
        print(f"Region {region_id} had {voxel_count_before} voxels; after 2D erosion {voxel_count_after} remain; {voxels_removed} removed.")
        eroded_atlas[eroded_mask] = region_id

    return eroded_atlas

def extract_rois(subject_files, atlas_path, labels_path):
    results = []
    atlas_data, labels, region_ids, affine = get_data_labels(atlas_path, labels_path)
    eroded_atlas_data = erode_atlas_regions(atlas_data, region_ids)
    eroded_filename = Path(atlas_path).parent / f"eroded_{Path(atlas_path).name}"
    nib.save(nib.Nifti1Image(eroded_atlas_data, affine), str(eroded_filename))

    for subject_file in subject_files:
        img = nib.load(str(subject_file))
        img_data = img.get_fdata()

        subject_row = {'filename': str(subject_file)}

        for region_id in region_ids:
            region_voxels = img_data[eroded_atlas_data == region_id]
            if region_voxels.size > 0:
                mean_value = np.mean(region_voxels)
            else:
                mean_value = np.nan
            region_name = labels[region_id].replace(" ", "_")
            subject_row[region_name] = mean_value

        results.append(subject_row)

    return pd.DataFrame(results)

def main():
    parser = argparse.ArgumentParser(description="Extract ROI values from NIfTI images.")
    parser.add_argument('--input_folder', type=str, required=True, help='Path to input folder containing subject NIfTI files')
    parser.add_argument('--filename', type=str, required=True, help='Filename')
    args = parser.parse_args()

    input_folder = Path(args.input_folder)
    subject_files = list(input_folder.glob(f'**/{args.filename}'))

    if not subject_files:
        print(f"No subject files found in {input_folder}")
        return

    results_label = extract_rois(subject_files=subject_files, atlas_path="reference_regions/TD_label.nii", labels_path="reference_regions/TD_label.txt")
    results_lobe = extract_rois(subject_files=subject_files, atlas_path="reference_regions/TD_lobe.nii", labels_path="reference_regions/TD_lobe.txt")
    results_GM = extract_rois_GM(subject_files=subject_files, mask_path="reference_regions/GM.nii")
    results_GM_iter = extract_rois_GM(subject_files=subject_files, individual_masks=True, region_name="Gray_Matter_Iter")

    filename_stem = Path(args.filename).stem
    output_path = input_folder / f'roi_results_{filename_stem}.xlsx'

    with pd.ExcelWriter(output_path) as writer:
        results_label.to_excel(writer, sheet_name='TD_label', index=False)
        results_lobe.to_excel(writer, sheet_name='TD_lobe', index=False)
        results_GM.to_excel(writer, sheet_name='GM', index=False)
        results_GM_iter.to_excel(writer, sheet_name='GM_iter', index=False)

    print(f'Results saved successfully to {output_path}')

if __name__ == "__main__":
    main()
