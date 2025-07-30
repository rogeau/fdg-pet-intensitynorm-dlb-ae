import argparse
import matplotlib.pyplot as plt
import pandas as pd

def extract_region_values(excel_path, region):
    file = pd.ExcelFile(excel_path)
    fallback_region = "rGM" if region.startswith("rindividual_mask") else None

    # First try to find the exact region in any sheet
    for sheet_name in file.sheet_names:
        df = file.parse(sheet_name)
        if region in df.columns:
            return df[region].dropna()

    # If not found, try fallback if applicable
    if fallback_region:
        for sheet_name in file.sheet_names:
            df = file.parse(sheet_name)
            if fallback_region in df.columns:
                print(f"⚠️ '{region}' not found in '{excel_path}'. Falling back to '{fallback_region}' in sheet '{sheet_name}'.")
                return df[fallback_region].dropna()

    print(f"❌ Neither '{region}' nor fallback found in any sheet of '{excel_path}'.")
    return pd.Series(dtype=float)

def plot_region_histogram(excel_files, region, unit, save_path):
    plt.figure(figsize=(10, 6))

    for excel_path in excel_files:
        values = extract_region_values(excel_path, region)
        if values.empty:
            continue

        label = excel_path.split("/")[0]  # Filename as group label
        mean_value = values.mean()

        _, _, patches = plt.hist(values, bins=25, alpha=0.5, label=f"{label} (mean={mean_value:.2f})")
        color = patches[0].get_facecolor()
        plt.axvline(mean_value, linestyle='dashed', linewidth=1.5, color=color)

    plt.title(f"{region}", fontweight='bold')
    plt.xlabel(f"{unit}")
    plt.ylabel("Frequency")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    ax = plt.gca()
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    plt.savefig(save_path, dpi=300)
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Plot histogram of ROI values from multiple Excel sheets.")
    parser.add_argument('--excel', type=str, nargs='+', required=True,
                        help='One or more Excel files with ROI data (e.g., group1.xlsx group2.xlsx)')
    parser.add_argument('--region', type=str, required=True,
                        help='Name of the ROI region (column name)')
    parser.add_argument('--unit', type=str, required=True,
                        help='Unit to be displayed on x axis (SUV or SUVR)')
    parser.add_argument('--save', type=str, required=True,
                        help='Path to save file')
    args = parser.parse_args()

    plot_region_histogram(args.excel, args.region, args.unit, args.save)

if __name__ == "__main__":
    main()
