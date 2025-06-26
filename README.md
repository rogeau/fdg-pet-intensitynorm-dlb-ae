# 🧠 Bq/mL -> SUV and Normalization pipeline

This pipeline converts [¹⁸F]FDG PET DICOM data (in Bq/mL) to NIfTI format expressed in Standardized Uptake Values (SUV), followed by spatial normalization and 3 different intensity normalization methods using MATLAB and SPM.

---

# 📋 Requirements

To run this pipeline, you’ll need the following:

- **MATLAB**
- **SPM12** (added to your MATLAB path)
- **dcm2niix**, for DICOM to NIfTI conversion
- **Python** (via Anaconda/Miniconda recommended)

Python is required for the first step (DICOM to NIfTI and unit conversions) and a dedicated conda environment can be created with the provided `environment.yml` file:

```bash
conda env create -f environment.yml
conda activate pet-pipeline
```

---

# 🛠️ Processing Pipeline
**1. Format and Unit Conversion**

Place your [¹⁸F]FDG DICOM folders inside the current directory. The script supports nested subfolders and processes only DICOM files. A summary will be saved to `infos.xlsx`.

```bash
./convert_format_unit.sh
```

**2. Spatial and Gray Matter/Pons Intensity Normalization**

This step:
- Reorients the origin of NIfTI files to the center of mass,
- Applies SPM’s Old Normalize using the PET template (PET.nii from SPM8),
- Performs intensity normalization using the average uptake in pons (from Wake Forest University PickAtlas) and gray matter.

```bash
./normalize_space_intensity.sh
```

**3. Iterative Intensity Normalization**

This final step requires a control group. It identifies regions of abnormal metabolism by creating a custom individual reference region (gray matter minus F-map clusters), computing an average uptake within this region and dividing the spatially normalized image `w_realigned.nii` by this average.

```bash
./normalize_iterative_intensity.sh
```

---

# 🔍 Average ROI values

This script allows you to extract average ROI values from the Wake Forest University (WFU) PickAtlas and plot them as histograms.

```bash
./extract_plot_rois.sh
```
