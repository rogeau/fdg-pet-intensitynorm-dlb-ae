import numpy as np
import pandas as pd
import nibabel as nib
from pathlib import Path

def extract(subject_path, mask_path):
    if not subject_path.exists():
        print(f"⚠️ Subject not found: {subject_path}")
        return np.nan
    if not mask_path.exists():
        print(f"⚠️ Mask not found: {mask_path}")
        return np.nan

    img_data = nib.load(str(subject_path)).get_fdata()
    mask_data = nib.load(str(mask_path)).get_fdata()

    region_voxels = img_data[mask_data.astype(bool)]
    mean_value = np.mean(region_voxels) if region_voxels.size > 0 else np.nan
    return mean_value

def extract_rois_GM(subject_files, individual_masks=None):
    """
    Extracts mean voxel values from subject images using individual masks.
    
    Parameters:
        subject_files (list): List of subject image Path objects.
        individual_masks (dict or None): Dict mapping Path -> list of mask Paths.
    
    Returns:
        pd.DataFrame: Columns = filename + one column per mask.
    """
    rows = []

    for subject_file in subject_files:
        subject_path = Path(subject_file)
        row = {'filename': str(subject_path)}

        if individual_masks is not None:
            masks = individual_masks.get(subject_path, [])
            for mask_path in masks:
                region_name = mask_path.stem  # e.g., "rindividual_mask_001"
                row[region_name] = extract(subject_path, mask_path)
        else:
            mask_path = subject_path.parent / 'rGM.nii'
            row['rGM'] = extract(subject_path, mask_path)

        rows.append(row)

    return pd.DataFrame(rows)








# def extract(subject_path, mask):
#     # Check both files exist
#     if not subject_path.exists():
#         print(f"Warning: {subject_path} does not exist. Skipping.")
#         continue
#     if not mask.exists():
#         print(f"Warning: {mask} does not exist for {subject_path.name}. Skipping.")
#         continue

#     # Load data
#     img_data = nib.load(str(subject_path)).get_fdata()
#     mask_data = nib.load(str(mask)).get_fdata()

#     region_voxels = img_data[mask_data.astype(bool) == 1]
#     mean_value = np.mean(region_voxels) if region_voxels.size > 0 else np.nan

#     results.append({
#         'filename': str(subject_path),
#         region_name: mean_value
#     })
#     return pd.DataFrame(results)

# def extract_rois_GM(subject_files, mask_path=None, individual_masks=None, region_name="Gray_Matter"):
#     """
#     Extracts mean voxel values from subject images within a mask.
    
#     Parameters:
#         subject_files (list): List of subject image file paths.
#         mask_path (str|Path|None): Path to shared mask (ignored if individual_masks=True).
#         individual_masks (bool): If True, expects a mask next to each subject named like 'individual_mask.nii.gz'.
#         region_name (str): Label for the extracted region in the output DataFrame.
    
#     Returns:
#         pd.DataFrame with columns ['filename', region_name]
#     """
#     results = []

#     for subject_file in subject_files:
#         subject_path = Path(subject_file)

#         # Determine mask path
#         if individual_masks is not None:
#             subject_indiv_masks = list(individual_masks[subject_file])

            
#             suffix = ''.join(subject_path.suffixes)  # preserves .nii.gz
#             mask = subject_path.with_name(f"individual_mask_03{suffix}")
#         else:
#             if mask_path is None:
#                 raise ValueError("mask_path must be provided when individual_masks=False.")
#             mask = Path(mask_path)

# # Check both files exist
# if not subject_path.exists():
#     print(f"Warning: {subject_path} does not exist. Skipping.")
#     continue
# if not mask.exists():
#     print(f"Warning: {mask} does not exist for {subject_path.name}. Skipping.")
#     continue

# # Load data
# img_data = nib.load(str(subject_path)).get_fdata()
# mask_data = nib.load(str(mask)).get_fdata()

# region_voxels = img_data[mask_data.astype(bool) == 1]
# mean_value = np.mean(region_voxels) if region_voxels.size > 0 else np.nan

# results.append({
#     'filename': str(subject_path),
#     region_name: mean_value
# })

# return pd.DataFrame(results)