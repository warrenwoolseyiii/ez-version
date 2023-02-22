# ez-version
Auto versioning script for multiple languages. Drop this script in your project and integrate into git hooks for simple auto versioning of your code!

# How it works
ez-version is a simple script that can be run manually, or utilizing git hooks to automatically bump the `revision` field of a classical versioning method automatically. The versioning method is the following:`MAJOR.MINOR.REVISION`.
Each time the ez-version script is utilized, the `revision` field is incremented by one.
All of the versioning information is stored in `scripts/version.json` which contains the `MAJOR, MINOR, and REVISION` fields. When `scripts/version.sh` is run, it will automatically increment the `REVISION` field in the `version.json` file, and the apply those changes to all of the `src` implementations.

# Where to find it all
`scripts` stores the global version record in `version.json`, which is utilized by both `version.sh` and `get_version.sh`. You will also find both `version.sh` and `get_version.sh` in the scripts directory.
`src` contains the various language implementations that have been done so far. Each subdirectory has a file named `version.*` where the extension is based on the language. Running `scripts/version.sh` will automatically increment the `REVISION` field in each source file.

# How to use
You can clone the latest `main` branch, or download the latest release. All that is required is modification of the paths in `version.sh`. You can base your implementation entirely off of the `src` examples in this project. You can automatically implement auto versioning by calling `scripts/version.sh` from `.git/hooks/...` in one of the git hook scripts. This project uses the `pre-commit` hook to automatically bump the revision for each commit.