# ez-version

A flexible, configuration-driven auto-versioning script for multiple languages. Designed to be easily integrated into your projects, especially as a Git submodule, for straightforward version management.

## Features

*   **Configuration-Driven:** Define version file paths and target source files in a simple JSON configuration.
*   **Flexible Bumping:** Increment MAJOR, MINOR, or REVISION parts of your version (MAJOR.MINOR.REVISION).
*   **Extensible:** Easily add support for new languages or file types by defining new target types in the script.
*   **Submodule Friendly:** Designed to be included as a submodule in your projects.
*   **Git Integration:** Automate version bumps using Git hooks (e.g., pre-commit).

## How it Works

`ez-version` uses a central JSON file (e.g., `scripts/version.json` within the `ez-version` submodule, or a path you define) to store the `MAJOR`, `MINOR`, and `REVISION` numbers.

The main script, `scripts/version.sh`, performs the following:

1.  **Reads Configuration:** It looks for a configuration file (default: `ez-version-config.json` in the directory where it's run, typically your project's root when used as a submodule). This file specifies:
    *   `version_file_path`: The path to the JSON file holding the version numbers.
    *   `targets`: An array of files to update with the new version, along with their type (e.g., `c_header`, `python_vars`).
2.  **Parses Arguments:** It accepts arguments to specify which part of the version to bump (`--bump <MAJOR|MINOR|REVISION>`) and the path to the configuration file (`--config <path>`).
3.  **Bumps Version:** It increments the specified version component in the `version_file_path` JSON file.
    *   Bumping `MAJOR` resets `MINOR` and `REVISION` to 0.
    *   Bumping `MINOR` resets `REVISION` to 0.
4.  **Updates Targets:** It iterates through the `targets` defined in the configuration file and updates each one according to its specified `type`.
5.  **Stages Changes:** It automatically stages the updated version JSON file and all processed target files in Git.

## Project Structure (within `ez-version`)

*   `scripts/version.sh`: The main versioning script.
*   `scripts/get_version.sh`: A utility script to retrieve and print the current full version string (reads from the `version_file_path` defined in your config).
*   `scripts/version.json`: The default version store if you use `ez-version` to version itself (see `ez-version-config.json.example`).
*   `ez-version-config.json.example`: An example configuration file showing how to set up `ez-version`.
*   `src/`: Contains example language implementations updated by the example configuration.

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
        "version_file_path": "external/ez-version/scripts/version.json", // Or a path in your own project
        "targets": [
          {
            "path": "my_project_src/version.h", // Path relative to your project root
            "type": "c_header"
          },
          {
            "path": "my_project_src/app_version.py",
            "type": "python_vars"
          }
          // Add other files in your project that need versioning
        ]
      }
      ```
      *   `version_file_path`: Can point to the `version.json` inside the submodule (as shown) or a `version.json` you manage in your parent project.
      *   `targets.path`: Paths are relative to where `version.sh` is run (typically your project root).

   c. **Initialize the version file (if new):**
      If `version_file_path` points to a new file, create it with initial values:
      ```json
      {
        "VERSION_MAJOR": 0,
        "VERSION_MINOR": 1,
        "VERSION_REV": 0
      }
      ```

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