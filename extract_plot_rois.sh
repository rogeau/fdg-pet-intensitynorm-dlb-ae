#!/bin/bash

read -p "Do you want to extract ROI values? (y/n): " extract_answer
if [[ "$extract_answer" =~ ^[Yy]$ ]]; then
    while true; do
        echo "Enter the parent folder location: "
        read parent

        if [ ! -d "$parent" ]; then
            echo "Error: Parent folder '$parent' does not exist."
            continue  # allow retry instead of exiting
        fi

        echo "Enter the input subfolder name (inside parent folder): "
        read input_subfolder

        input_path="${parent}/${input_subfolder}"
        if [ ! -d "$input_path" ]; then
            echo "Error: Input path '$input_path' does not exist."
            continue  # allow retry
        fi

        echo "Enter the file name of volumes from which ROI values will be extracted (including the extension, e.g. s_gm_w_realigned.nii): "
        read filename

        if ! find "$input_path" -type f -name "$filename" -print -quit | grep -q .; then
            echo "No $filename file found. Please try again."
            continue  # allow retry
        fi

        # Run Python script
        python extract_rois.py --input_folder "$input_path" --filename "$filename"

        echo
        read -p "Do you want to extract other ROIs? (y/n): " answer
        case "$answer" in
            [Yy]* ) continue ;;
            * ) echo "Exiting ROI extraction."; break ;;
        esac
    done
fi


read -p "Do you want to plot ROI data? (y/n): " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Exiting."; exit 0; }

excel_paths=()

while true; do
    echo "Enter the parent folder location: "
    read parent

    if [ ! -d "$parent" ]; then
	echo "Error: Parent folder '$parent' does not exist. Please try again."
	continue
    fi

    echo "Enter the input subfolder name (inside parent folder): "
    read subfolder

    if [ ! -d "${parent}/${subfolder}" ]; then
	echo "Error: Subfolder '${parent}/${subfolder}' does not exist. Please try again."
	continue
    fi

    echo "Enter the file name of the Excel table (including the extension): "
    read filename

    excel_path="${parent}/${subfolder}/${filename}"
    if [ ! -f "$excel_path" ]; then
        echo "Error: Excel file '$excel_path' does not exist."
        continue
    fi

    excel_paths+=("$excel_path")  # add to array

    echo
    read -p "Do you want to provide another Excel table? (y/n): " answer
    case "$answer" in
        [Yy]* ) continue ;;
        * ) break ;;
    esac
done

target_dir="roi_plots/${filename%.*}"
mkdir -p "${target_dir}"

read -p "Unit to be displayed on x axis: " unit

while true; do
    echo "Enter region exact name (as shown in excel table) "
    read region

python plot_rois.py --excel "${excel_paths[@]}" --region "$region" --unit "$unit" --save "${target_dir}/$region.png"

    echo
    read -p "Do you want to display another plot? (y/n): " answer
    case "$answer" in
        [Yy]* ) continue ;;
        * ) break ;;
    esac
done
