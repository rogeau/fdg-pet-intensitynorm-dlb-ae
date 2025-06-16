#!/bin/bash

echo "Enter the parent folder location: "
read parent

echo "Enter the input subfolder location: "
read input_subfolder

echo "Enter the output subfolder: "
read output_subfolder

input_path="${parent}/${input_subfolder}"
output_path="${parent}/${output_subfolder}"
infos="${parent}/infos.xlsx"

mkdir -p "$output_path"

matlab -nosplash -nodisplay -r "center_mass('$input_path', '$output_path', '$infos'); spatialNorm('$output_path'); intensityNorm('$output_path'); smooth('$output_path'); exit"
