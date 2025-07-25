#!/bin/bash

echo "Enter the patient folder location: "
read patient
if [ ! -d "$patient" ]; then
    echo "Error: Patient folder '$patient' does not exist."
    exit 1
fi

echo "Enter the patient group's preprocessed scan subfolder: "
read patient_subfolder

patient_dir="${patient}/${patient_subfolder}"
if [ ! -d "$patient_dir" ]; then
    echo "Error: Patient dir path '$patient_dir' does not exist."
    exit 1
fi

read -p "Enter threshold for SPM F-contrast (individual mask): " threshold

matlab -nosplash -nodisplay -r "iter_smooth('$patient_dir', '$threshold'); exit"