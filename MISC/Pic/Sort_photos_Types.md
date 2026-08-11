# File Type Organization

This Bash script organizes files into specific folders by type (`ORG`, `MOV`, `MP4`, `CR2`, `HEIC`). HEIC-to-JPG conversion code exists in the script but is currently commented out, so HEIC files are moved as-is rather than converted.

## Prerequisites

Before running this script, make sure you have the following prerequisites installed on your system:

- `sudo`: Superuser privileges for installing packages.

Note: the script still checks for and installs `libheif-examples` (via `dpkg`/`apt-get`) as if HEIC conversion were about to run, but the actual `heif-convert` call is currently commented out in the script (see "HEIC Handling" below), so this install step is effectively vestigial — it installs a package the script no longer uses.

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
If the package is not found, the script installs it using `apt-get`. Note: this check is currently vestigial — it was originally there to support HEIC-to-JPG conversion, but that conversion step is commented out in the script (see below), so nothing in the script actually uses `libheif-examples` right now.

2. Folder Creation:

The script creates the following folders in the current directory: `ORG`, `MOV`, `MP4`, `CR2`, and `HEIC`. These folders will be used to organize different types of files.

3. HEIC Handling (no conversion):

HEIC files are **not** converted to JPG. The HEIC-to-JPG conversion code (using `heif-convert`) is present in the script only as a commented-out block and does not run. Instead, `.HEIC` files are simply moved as-is into the `HEIC` folder, the same way `.MOV`, `.MP4`, and `.CR2` files are moved into their respective folders.

4. File Organization:

Files are organized into their respective folders based on their file extensions. Files with extensions `.mov` are moved to the `MOV` folder, `.mp4` to the `MP4` folder, `.CR2` to the `CR2` folder, and `.HEIC` to the `HEIC` folder.

5. Copying JPG Files:

`JPG` and `JPEG` files are copied to the `ORG` folder. This folder serves as a central location for storing these image files.

6. Empty Directory Cleanup:

The script utilizes the `find` command to locate and delete any empty directories within the current working directory. This step helps maintain a tidy directory structure.

7. Completion Message:

The script concludes by displaying an "All tasks completed" message to indicate the successful execution of all operations.
Note: Ensure that you run the script with appropriate permissions, especially when using `sudo` for package installation, to avoid any permission-related issues.