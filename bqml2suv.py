import os
import nibabel as nib
import json
import pydicom
import pandas as pd
import argparse
import math

def time_to_seconds(tstr):
    # DICOM time format HHMMSS.frac
    if '.' in tstr:
        tstr, frac = tstr.split('.')
    else:
        frac = '0'
    h = int(tstr[0:2])
    m = int(tstr[2:4])
    s = int(tstr[4:6])
    return h*3600 + m*60 + s + float("0."+frac)

def find_first_dcmslice(dicom_dir, nifti_path):
    if nifti_path.endswith(".nii.gz"):
        series_uid = os.path.basename(nifti_path[:-7])
    elif nifti_path.endswith(".nii"):
        series_uid = os.path.basename(nifti_path[:-4])
    else:
        raise ValueError("Unsupported file extension. Only .nii and .nii.gz are supported.")

    for dirpath, dirnames, filenames in os.walk(dicom_dir):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            try:
                ds = pydicom.dcmread(filepath, stop_before_pixels=True)
                if ds.get("SeriesInstanceUID") == series_uid:
                    return ds
            except Exception:
                continue
    return None

def suv_conversion_parameters(ds):
    patient_weight_kg = ds.get("PatientWeight", None)
    if patient_weight_kg is None:
        raise ValueError("PatientWeight missing")
    patient_weight_g = patient_weight_kg * 1000

    # Radiopharmaceutical info sequence (usually only one)
    radsq = ds.RadiopharmaceuticalInformationSequence[0]
    injected_dose_Bq = radsq.get("RadionuclideTotalDose", None)
    if injected_dose_Bq is None:
        raise ValueError("Injected dose missing")

    half_life_s = radsq.get("RadionuclideHalfLife", None)
    if half_life_s is None:
        raise ValueError("Half-life missing")

    injection_time_str = radsq.get("RadiopharmaceuticalStartTime", None)
    acq_time_str = ds.get("AcquisitionTime", None)
    
    inj_sec = time_to_seconds(injection_time_str)
    acq_sec = time_to_seconds(acq_time_str)
    delta_t = acq_sec - inj_sec
    if delta_t < 0:  # If acquisition is after midnight, adjust accordingly
        delta_t += 24*3600

    decay_factor = math.exp(-math.log(2) / half_life_s * delta_t)
        
    return patient_weight_g, injected_dose_Bq, decay_factor


def identification(ds, info_dict):
    series_uid = ds.get("SeriesInstanceUID", None)
    name = ds.get("PatientName", None)
    patient_id = ds.get("PatientID", None)
    modality = ds.get("Modality", None)
    dob = ds.get("PatientBirthDate", None)
    sex = ds.get("PatientSex", None)
    dos = ds.get("StudyDate", None)
    weight = ds.get("PatientWeight", None)
    size = ds.get("PatientSize", None)

    injected_dose_Bq = None
    if "RadiopharmaceuticalInformationSequence" in ds:
        radsq = ds.RadiopharmaceuticalInformationSequence[0]
        injected_dose_Bq = radsq.get("RadionuclideTotalDose", None)

    recon_element = ds.get((0x0054, 0x1103), None)
    recon_method = recon_element.value if recon_element else None
    series_description = ds.get("SeriesDescription", None)

    # Update the passed dict with these key-value pairs
    info_dict.update({
        "SeriesUID": str(series_uid),
        "PatientName": str(name) if name else None,
        "PatientID": patient_id,
        "Modality": modality,
        "DateOfBirth": dob,
        "Sex": sex,
        "StudyDate": dos,
        "PatientWeight": weight,
        "PatientSize": size,
        "InjectedDose_Bq": injected_dose_Bq,
        "ReconstructionMethod": str(recon_method) if recon_method else None,
        "SeriesDescription": series_description
    })

def compute_age(row):
    try:
        dob = pd.to_datetime(row['DateOfBirth'], format='%Y%m%d')
        study_date = pd.to_datetime(row['StudyDate'], format='%Y%m%d')
        age = (study_date - dob).days / 365.25
        return round(age, 1)
    except Exception:
        return None

def convert_bqml_to_suv(bqml_dir, suv_dir, dicom_dir):
    parent_folder = os.path.abspath(bqml_dir).split(os.sep)[-2]
    info_list = []

    for filename in os.listdir(bqml_dir):
        if filename.endswith(".nii.gz"):
            source_path = os.path.join(bqml_dir, filename)
            json_path = source_path[:-7] + ".json"
            target_filename = filename[:-7] + ".nii"
            target_path = os.path.join(suv_dir, target_filename)

        elif filename.endswith(".nii"):
            source_path = os.path.join(bqml_dir, filename)
            json_path = source_path[:-4] + ".json"
            target_path = os.path.join(suv_dir, filename)

        else:
            continue

        try:
            with open(json_path, 'r') as f:
                meta = json.load(f)
        except FileNotFoundError:
            print(f"    ⚠️ JSON metadata not found for {source_path}. Skipping.")
            continue

        units = meta.get("Units", "")
        if units != "BQML":
            print(f"⚠️ Skipping {source_path}: Data is not in BQML units — cannot apply SUV formula.")
            continue

        print(f"⚙️ Processing {source_path}...")

        img = nib.load(source_path)
        bqml_data = img.get_fdata()

        dcm_file = find_first_dcmslice(dicom_dir, source_path)
        if dcm_file is None:
            print(f"    ⚠️ No matching DICOM slice found for {source_path}. Skipping.")
            continue

        try:
            weight, dose, decay = suv_conversion_parameters(dcm_file)
            suv_data = (bqml_data * weight) / (dose * decay)

            suv_img = nib.Nifti1Image(suv_data, img.affine, img.header)
            nib.save(suv_img, target_path)
            print(f"    ✅ SUV conversion")

            info_dict = {}
            identification(dcm_file, info_dict=info_dict)
            info_list.append(info_dict)

        except ValueError as e:
            print(f"    ❌ Skipping {source_path}: {e}")

    # Save the info as Excel
    if info_list:
        df = pd.DataFrame(info_list)
        df['Sex_binary'] = df['Sex'].map({'M': 0, 'F': 1})
        df['Age'] = df.apply(compute_age, axis=1)
        dfpath = os.path.join(parent_folder, "infos.xlsx")
        df.to_excel(dfpath, index=False)
        print(f"📄 Info saved to {dfpath}")


def main():
    parser = argparse.ArgumentParser(description="Convert BQML NIfTI files to SUV using DICOM metadata.")
    parser.add_argument("bqml_dir", help="Directory containing BQML .nii.gz files")
    parser.add_argument("suv_dir", help="Output directory for SUV .nii files")
    parser.add_argument("dicom_dir", help="Directory containing DICOM files")
    args = parser.parse_args()

    convert_bqml_to_suv(args.bqml_dir, args.suv_dir, args.dicom_dir)

if __name__ == "__main__":
    main()
