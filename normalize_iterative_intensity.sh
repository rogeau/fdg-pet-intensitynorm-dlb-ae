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


echo "Enter the control folder location: "
read control
if [ ! -d "$control" ]; then
    echo "Error: Control folder '$control' does not exist."
    exit 1
fi

echo "Enter the control group's preprocessed scan subfolder: "
read control_subfolder

control_dir="${control}/${control_subfolder}"
if [ ! -d "$control_dir" ]; then
    echo "Error: Control dir path '$control_dir' does not exist."
    exit 1
fi

matlab -nosplash -nodisplay -r "create_individual_masks('$patient_dir', '$control_dir'); iter_intensity_norm('$patient_dir'); iter_smooth('$patient_dir'); exit"