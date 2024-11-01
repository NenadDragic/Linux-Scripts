# Photo Organization Script
This Bash script organizes photos into folders based on their creation date and camera model using EXIF metadata.

## Prerequisites
Before running this script, make sure you have the following prerequisites installed on your system:
- `exiftool`: A tool for reading and writing EXIF metadata.
- Basic Unix/Linux command line tools.

## Installation
1. Install ExifTool if not already installed:
```bash
sudo apt-get install exiftool
```

2. Download the script and make it executable:
```bash
chmod +x Play.sh
```

## Usage
1. Place the script in the directory containing your photos
2. Run the script using:
```bash
./photo-organizer.sh
```

## Script Explanation

### 1. File Detection
- The script searches for files with `.JPG` and `.JPEG` extensions (case-insensitive)
- Uses bash's `nocaseglob` option to ensure case-insensitive matching

### 2. Metadata Extraction
The script extracts the following metadata from each image:
- Creation date (YYYY-MM-DD format)
- Camera model name
- Original filename

### 3. Directory Structure Creation
- Creates a hierarchical folder structure: `YYYY-MM-DD/CAMERA_MODEL/`
- Example: `2024-01-15/Canon_EOS_R6/`
- Special characters in camera model names are replaced with underscores

### 4. File Organization
- Copies each photo to its corresponding date/camera model directory
- Maintains the original filename
- Preserves the original files in their source location

### 5. Error Handling
The script includes several safety features:
- Checks for existence of files before processing
- Validates extracted metadata
- Provides feedback for successful copies and errors
- Skips files with missing or invalid metadata

## Example Output
```
Successfully copied IMG_1234.JPG to 2024-01-15/Canon_EOS_R6/IMG_1234.JPG
Successfully copied IMG_1235.JPG to 2024-01-15/Canon_EOS_R6/IMG_1235.JPG
Warning: Could not extract metadata from IMG_1236.JPG
```

## Directory Structure Example
```
.
├── 2024-01-15
│   └── Canon_EOS_R6
│       ├── IMG_1234.JPG
│       └── IMG_1235.JPG
└── 2024-01-16
    └── Nikon_D850
        └── DSC_0001.JPG
```

## Notes
- The script copies rather than moves files to prevent accidental data loss
- Empty folders will be created only when needed
- Files without valid EXIF data will be skipped with a warning
- The script maintains the original files in their source location

## Troubleshooting
1. **Missing ExifTool**: If you see "command not found" errors, ensure ExifTool is installed
2. **Permission Issues**: Make sure you have write permissions in the target directories
3. **No Files Processed**: Check that your JPG/JPEG files are in the same directory as the script

## Contributing
Feel free to submit issues and enhancement requests!

## License
This project is licensed under the MIT License - see the LICENSE file for details.
