# ez-version

A flexible, configuration-driven auto-versioning script for multiple languages. Designed to be easily integrated into your projects, especially as a Git submodule, for straightforward version management.

## Features

*   **Configuration-Driven:** Define version file paths and target source files in a simple JSON configuration.
*   **Flexible Bumping:** Increment MAJOR, MINOR, or REVISION parts of your version (MAJOR.MINOR.REVISION).
*   **Extensible:** Easily add support for new languages or file types by defining new target types in the script.
*   **Submodule Friendly:** Designed to be included as a submodule in your projects.
*   **Git Integration:** Automate version bumps using Git hooks (e.g., pre-commit).

## How it Works

`ez-version` uses a central JSON file, specified by `version_file_path` in your `ez-version-config.json`, to store the `MAJOR`, `MINOR`, and `REVISION` numbers. If this file does not exist, `scripts/version.sh` will create it with an initial version of `0.1.0`.

The main script, `scripts/version.sh`, performs the following:

1.  **Reads Configuration:** It looks for a configuration file (default: `ez-version-config.json` in the directory where it's run, typically your project's root when used as a submodule). This file specifies:
    *   `version_file_path`: The path (relative to your project root) to the JSON file that will store your version numbers (e.g., `my_project_config/version.json`).
    *   `targets`: An array of files in your project to update with the new version, along with their type (e.g., `c_header`, `python_vars`).
2.  **Initializes Version File (if needed):** If the file specified by `version_file_path` does not exist, the script creates it and its parent directories, initializing the version to `0.1.0`.
3.  **Parses Arguments:** It accepts arguments to specify which part of the version to bump (`--bump <MAJOR|MINOR|REVISION>`) and the path to the configuration file (`--config <path>`).
4.  **Bumps Version:** It increments the specified version component in the `version_file_path` JSON file.
    *   Bumping `MAJOR` resets `MINOR` and `REVISION` to 0.
    *   Bumping `MINOR` resets `REVISION` to 0.
5.  **Updates Targets:** It iterates through the `targets` defined in the configuration file and updates each one according to its specified `type`.
6.  **Stages Changes:** It automatically stages the updated version JSON file and all processed target files in Git.

## Project Structure (within `ez-version`)

*   `scripts/version.sh`: The main versioning script.
*   `scripts/get_version.sh`: A utility script to retrieve and print the current full version string (reads from the `version_file_path` defined in your config).
*   `ez-version-config.json.example`: An example configuration file showing how to set up `ez-version` for your project. This file is intended to be copied into your project's root and customized.
*   `project_config/version.json.example`: An example/template for the version JSON file that your project will use. You can copy this to the location specified in your `ez-version-config.json` (e.g., `project_config/version.json`) as a starting point.

## How to Use

### 1. As a Git Submodule (Recommended)

This is the ideal way to use `ez-version` across multiple projects.

   a. **Add `ez-version` as a submodule to your project:**
      ```bash
      git submodule add <repository_url_of_ez-version> path/to/ez-version
      # e.g., git submodule add https://github.com/your-username/ez-version.git external/ez-version
      git commit -m "Add ez-version submodule"
      ```

   b. **Create your configuration file:**
      In the root of your main project, create an `ez-version-config.json` file. Copy and adapt [`ez-version-config.json.example`](ez-version-config.json.example:0) from the submodule.

      **Example `ez-version-config.json` in your project's root:**
      ```json
      {
        "version_file_path": "project_config/version.json", // Path in your project for the version data
        "targets": [
          {
            "path": "my_app_src/version.h", // Path in your project to a C header
            "type": "c_header"
          },
          {
            "path": "my_app_src/app_version.py", // Path in your project to a Python file
            "type": "python_vars"
          }
          // Add other files in your project that need versioning
        ]
      }
      ```
      *   `version_file_path`: This is where your project's version numbers will be stored. `scripts/version.sh` will create this file (and its directory if needed) with version `0.1.0` if it doesn't exist on the first run. Alternatively, you can copy `path/to/ez-version/project_config/version.json.example` to this location and customize it.
      *   `targets.path`: Paths are relative to where `version.sh` is run (typically your project root).

   c. **Set up your project's version file:**
      Ensure the file specified by `version_file_path` in your `ez-version-config.json` exists.
      You can either:
      *   Let `scripts/version.sh` create it automatically on its first run (it will be initialized to `0.1.0`).
      *   Or, copy the example: `cp path/to/ez-version/project_config/version.json.example project_config/version.json` (adjusting `project_config/version.json` to match your `version_file_path`) and modify if needed.

   d. **Run the script:**
      From your project's root:
      ```bash
      # Bump REVISION (default) using default ez-version-config.json
      path/to/ez-version/scripts/version.sh

      # Bump MINOR
      path/to/ez-version/scripts/version.sh --bump MINOR

      # Use a different config file
      path/to/ez-version/scripts/version.sh --config my-custom-config.json --bump MAJOR
      ```

   e. **Integrate with Git Hooks (Optional but Recommended):**
      To automatically bump the version on each commit, call the script from a Git hook, like `pre-commit`.

      Example `.git/hooks/pre-commit` in your main project:
      ```bash
      #!/bin/bash
      echo "Bumping version before commit..."
      # Ensure the path to version.sh is correct relative to your project root
      ./external/ez-version/scripts/version.sh --bump REVISION
      # The script will 'git add' the changed files.
      # If the script fails (e.g., config error), it will exit non-zero, stopping the commit.
      echo "Version bumped."
      exit 0
      ```
      Make the hook executable: `chmod +x .git/hooks/pre-commit`

### 2. Standalone (Less Flexible for Multiple Projects)

You can clone or download `ez-version` into a directory. You'll still need to create an `ez-version-config.json` and adjust paths accordingly.

## `scripts/version.sh` Arguments

*   `-c, --config <config_file_path>`: Specifies the path to the JSON configuration file.
    *   Default: `ez-version-config.json` (searched in the current working directory).
*   `-b, --bump <MAJOR|MINOR|REVISION>`: Specifies which part of the version to increment.
    *   Default: `REVISION`. Case-insensitive.
*   `-h, --help`: Displays usage information.

## `scripts/get_version.sh`

This simple script reads the version from the `version_file_path` (as defined in your `ez-version-config.json`) and prints it to standard output (e.g., `0.1.5`).

**Usage:**
```bash
# Assuming ez-version-config.json is in the current directory
path/to/ez-version/scripts/get_version.sh

# With a custom config (get_version.sh will look for it)
# Ensure get_version.sh is modified or configured to find your custom config if not default.
# (Note: get_version.sh currently assumes default config name in CWD,
#  this could be enhanced to also take a -c argument like version.sh)
```

## Extending to New Languages/File Types

To support a new language or file format:
1.  Define a new `type` name (e.g., `java_props`).
2.  Add a corresponding `case` block in `scripts/version.sh` to handle this new type. This block will contain the logic to read the `VERSION_MAJOR`, `VERSION_MINOR`, `VERSION_REV` variables and write them into the target file in the correct format.
3.  Update your `ez-version-config.json` to use this new `type` for relevant target files.

Contributions for new language handlers are welcome!