# 🧠 Bq/mL -> SUV and Normalization pipeline

This pipeline transforms step-by-step [18F]FDG PET dicom data expressed in Bq/mL to nifti files expressed in SUV. This is followed by spatial and intensity normalization using MATLAB and SPM.

---

# 📋 Requirements

To run this pipeline, you’ll need the following:

- **MATLAB**
- **SPM12**, added to your MATLAB path
- **dcm2niix** – for DICOM to NIfTI conversion
- **Python** (via Anaconda/Miniconda recommended)

It is recommended to create a dedicated environment using the provided `environment.yml` file:

```bash
conda env create -f environment.yml
conda activate pet-pipeline
```

---

# Procedure
Place your [¹⁸F]FDG DICOM folders inside the current directory. The script supports nested subfolders and processes only DICOM files. A summary of the conversion will be output to an Excel file.

```bash
./convert_format_unit.sh
```

The second step is to automatically reorient the origin of nifti files using the center of mass, spatially normalize data using SPM Old Normalize function and the PET.nii provided in SPM8, and normalize in intensity based on average gray matter and pons (from Wake Forest University PickAtlas).

```bash
./normalize_space_intensity.sh
```
