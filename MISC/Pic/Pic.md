# HEIC to JPG Conversion and File Organization

This Bash script converts HEIC files to JPG format and organizes files into specific folders.

## Prerequisites

Before running this script, make sure you have the following prerequisites installed on your system:

- `heif-convert`: A tool for converting HEIC images to other formats.
- `sudo`: Superuser privileges for installing packages.

## Usage

Follow these steps to use the script:

1. Ensure you have the necessary prerequisites installed on your system.

2. Modify the script as needed.

3. Run the script using the following command:

   ```bash
   bash script_name.sh

## Script Explanation
1. Package Check and Installation:

The script starts by checking if the `libheif-examples` package is installed on the system using the `dpkg` command.
If the package is not found, the script installs it using `apt-get`, ensuring that the necessary software is available for HEIC conversion.

2. Folder Creation:

The script creates the following folders in the current directory: `ORG`, `MOV`, `MP4`, `CR2`, and `HEIC`. These folders will be used to organize different types of files.

3. HEIC to JPG Conversion:

HEIC files present in the current directory are converted to JPG format using the `heif-convert` tool. This conversion process ensures compatibility with common image viewers and applications.
Additionally, the script renames the resulting JPG files to remove the .HEIC extension for better file identification and consistency.

4. File Organization:

Files are organized into their respective folders based on their file extensions. Files with extensions `.mov` are moved to the `MOV` folder, `.mp4` to the `MP4` folder, `.CR2` to the `CR2` folder, and `.HEIC` to the `HEIC` folder.

5. Copying JPG Files:

`JPG` and `JPEG` files are copied to the `ORG` folder. This folder serves as a central location for storing these image files.

6. Empty Directory Cleanup:

The script utilizes the `find` command to locate and delete any empty directories within the current working directory. This step helps maintain a tidy directory structure.

7. Completion Message:

The script concludes by displaying an "All tasks completed" message to indicate the successful execution of all operations.
Note: Ensure that you run the script with appropriate permissions, especially when using `sudo` for package installation, to avoid any permission-related issues.