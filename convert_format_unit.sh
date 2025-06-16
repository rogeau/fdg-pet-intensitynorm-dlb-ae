#!/bin/bash

copy_with_suffix() {
    src="$1"
    dest_dir="$2"
    base=$(basename "$src")
    name="${base%.*}"
    ext="${base##*.}"

    [[ "$name" == "$ext" ]] && ext="" || ext=".$ext"

    target="$dest_dir/$name$ext"
    i=1

    while [ -e "$target" ]; do
        target="$dest_dir/${name}_$i$ext"
        ((i++))
    done

    cp "$src" "$target"
}

echo "Enter source folder name: "
read source

# Check that source exists
if [ ! -d "$source" ]; then
    echo "Error: Source folder '$source' does not exist."
    exit 1
fi

echo "Enter population name: "
read population

# Define output directories
population_bqml="$population/bqml_nifti/"
population_suv="$population/suv_nifti/"

tmpdir=$(mktemp -d)
echo "Copying files to temporary directory: $tmpdir"
find "$source" -type f | while read -r file; do
    copy_with_suffix "$file" "$tmpdir"
done

mkdir -p "$population_bqml"
mkdir -p "$population_suv"

echo "Running Nifti transformation..."
dcm2niix -z y -b y -f "%j" -o "$population_bqml" "$tmpdir"

echo "Running SUV conversion..."
python bqml_to_suv.py "$population_bqml" "$population_suv" "$source"

echo "Processing complete."