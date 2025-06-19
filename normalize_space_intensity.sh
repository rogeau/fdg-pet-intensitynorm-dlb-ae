#!/bin/bash

echo "Enter the parent folder location: "
read parent

if [ ! -d "$parent" ]; then
    echo "Error: Parent folder '$parent' does not exist."
    exit 1
fi

echo "Enter the input subfolder name (inside parent folder): "
read input_subfolder

input_path="${parent}/${input_subfolder}"
if [ ! -d "$input_path" ]; then
    echo "Error: Input path '$input_path' does not exist."
    exit 1
fi

echo "Enter the output subfolder name (inside parent folder): "
read output_subfolder

output_path="${parent}/${output_subfolder}"
mkdir -p "$output_path"

infos="${parent}/infos.xlsx"
if [ ! -f "$infos" ]; then
    echo "Error: Required file '$infos' not found."
    exit 1
fi

matlab -nosplash -nodisplay -r "center_mass('$input_path', '$output_path', '$infos'); spatial_norm('$output_path'); std_intensity_norm('$output_path'); std_smooth('$output_path'); exit"
