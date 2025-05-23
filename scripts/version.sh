#!/bin/bash

# Default configuration
DEFAULT_CONFIG_FILE="ez-version-config.json"
DEFAULT_BUMP_TYPE="REVISION" # Or MAJOR, MINOR

CONFIG_FILE="$DEFAULT_CONFIG_FILE"
BUMP_TYPE="$DEFAULT_BUMP_TYPE"

# Function to show usage
usage() {
  echo "Usage: $0 [-c|--config <config_file>] [-b|--bump <MAJOR|MINOR|REVISION>]"
  echo "  -c, --config  Path to the configuration file (default: $DEFAULT_CONFIG_FILE)"
  echo "  -b, --bump    Version part to bump (default: $DEFAULT_BUMP_TYPE)"
  exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -c|--config) CONFIG_FILE="$2"; shift ;;
    -b|--bump) BUMP_TYPE=$(echo "$2" | tr '[:lower:]' '[:upper:]'); shift ;; # Convert to uppercase
    -h|--help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Validate BUMP_TYPE
if [[ "$BUMP_TYPE" != "MAJOR" && "$BUMP_TYPE" != "MINOR" && "$BUMP_TYPE" != "REVISION" ]]; then
  echo "Error: Invalid bump type '$BUMP_TYPE'. Must be MAJOR, MINOR, or REVISION."
  usage
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found."
  echo "Please create it or specify a valid path using -c or --config."
  echo "An example can be found at ez-version-config.json.example"
  exit 1
fi

# Read version_file_path from config
VERSION_JSON_PATH=$(jq -r '.version_file_path' "$CONFIG_FILE")
if [ -z "$VERSION_JSON_PATH" ] || [ "$VERSION_JSON_PATH" == "null" ]; then
  echo "Error: 'version_file_path' not found or is null in $CONFIG_FILE."
  exit 1
fi

# Check if version JSON file exists, create if not
if [ ! -f "$VERSION_JSON_PATH" ]; then
  echo "Info: Version JSON file '$VERSION_JSON_PATH' not found. Creating with default version 0.1.0."
  # Ensure parent directory exists
  mkdir -p "$(dirname "$VERSION_JSON_PATH")"
  # Create the file with default content
  echo '{
  "VERSION_MAJOR": 0,
  "VERSION_MINOR": 1,
  "VERSION_REV": 0
}' > "$VERSION_JSON_PATH"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create version JSON file '$VERSION_JSON_PATH'."
    exit 1
  fi
fi

TMP_VERSION_JSON_FILE="${VERSION_JSON_PATH}.tmp"

# Read current versions
VERSION_MAJOR=$(jq -r '.VERSION_MAJOR' "$VERSION_JSON_PATH")
VERSION_MINOR=$(jq -r '.VERSION_MINOR' "$VERSION_JSON_PATH")
VERSION_REV=$(jq -r '.VERSION_REV' "$VERSION_JSON_PATH")

# Bump the version
case $BUMP_TYPE in
  MAJOR)
    VERSION_MAJOR=$((VERSION_MAJOR + 1))
    VERSION_MINOR=0
    VERSION_REV=0
    ;;
  MINOR)
    VERSION_MINOR=$((VERSION_MINOR + 1))
    VERSION_REV=0
    ;;
  REVISION)
    VERSION_REV=$((VERSION_REV + 1))
    ;;
esac

# Update the version.json file
jq \
  --argjson major "$VERSION_MAJOR" \
  --argjson minor "$VERSION_MINOR" \
  --argjson rev "$VERSION_REV" \
  '.VERSION_MAJOR = $major | .VERSION_MINOR = $minor | .VERSION_REV = $rev' \
  "$VERSION_JSON_PATH" > "$TMP_VERSION_JSON_FILE" && mv "$TMP_VERSION_JSON_FILE" "$VERSION_JSON_PATH"

echo "Bumped $BUMP_TYPE: New version is $VERSION_MAJOR.$VERSION_MINOR.$VERSION_REV"
echo "Updated $VERSION_JSON_PATH"

# Files to be added to git
GIT_ADD_FILES=("$VERSION_JSON_PATH")

# Process targets
jq -c '.targets[]' "$CONFIG_FILE" | while IFS= read -r target_json; do
  target_path=$(echo "$target_json" | jq -r '.path')
  target_type=$(echo "$target_json" | jq -r '.type')

  if [ -z "$target_path" ] || [ "$target_path" == "null" ]; then
    echo "Warning: Skipping target with no path defined in $CONFIG_FILE."
    continue
  fi
  if [ -z "$target_type" ] || [ "$target_type" == "null" ]; then
    echo "Warning: Skipping target '$target_path' with no type defined in $CONFIG_FILE."
    continue
  fi

  echo "Processing target: $target_path (type: $target_type)"

  # Ensure parent directory exists for the target file
  mkdir -p "$(dirname "$target_path")"

  case $target_type in
    c_header)
      echo "#ifndef VERSION_H_" > "$target_path"
      echo "#define VERSION_H_" >> "$target_path"
      echo "" >> "$target_path"
      echo "#define VERSION_MAJOR $VERSION_MAJOR" >> "$target_path"
      echo "#define VERSION_MINOR $VERSION_MINOR" >> "$target_path"
      echo "#define VERSION_REV $VERSION_REV" >> "$target_path"
      echo "" >> "$target_path"
      echo "#endif /* VERSION_H_ */" >> "$target_path"
      GIT_ADD_FILES+=("$target_path")
      echo "Updated C header: $target_path"
      ;;
    python_vars)
      echo "VERSION_MAJOR = $VERSION_MAJOR" > "$target_path"
      echo "VERSION_MINOR = $VERSION_MINOR" >> "$target_path"
      echo "VERSION_REV = $VERSION_REV" >> "$target_path"
      GIT_ADD_FILES+=("$target_path")
      echo "Updated Python variables file: $target_path"
      ;;
    kotlin_object_vars)
      echo "object Version {" > "$target_path"
      echo "    const val VERSION_MAJOR = $VERSION_MAJOR" >> "$target_path"
      echo "    const val VERSION_MINOR = $VERSION_MINOR" >> "$target_path"
      echo "    const val VERSION_REV = $VERSION_REV" >> "$target_path"
      echo "}" >> "$target_path"
      GIT_ADD_FILES+=("$target_path")
      echo "Updated Kotlin object variables file: $target_path"
      ;;
    # Add more types here as needed, e.g.:
    # json_property)
    #   property_name=$(echo "$target_json" | jq -r '.property_name') # e.g., "version"
    #   jq --arg ver "$VERSION_MAJOR.$VERSION_MINOR.$VERSION_REV" \
    #      --arg prop "$property_name" \
    #      '(.[$prop]) = $ver' \
    #      "$target_path" > "${target_path}.tmp" && mv "${target_path}.tmp" "$target_path"
    #   GIT_ADD_FILES+=("$target_path")
    #   echo "Updated JSON property '$property_name' in: $target_path"
    #   ;;
    # pyproject_toml)
    #   # Using sed for simplicity, consider a toml parser for robustness
    #   sed -i.bak "s/^version = \".*\"/version = \"$VERSION_MAJOR.$VERSION_MINOR.$VERSION_REV\"/" "$target_path"
    #   rm -f "${target_path}.bak" # Remove backup file created by sed -i
    #   GIT_ADD_FILES+=("$target_path")
    #   echo "Updated pyproject.toml: $target_path"
    #   ;;
    # build_gradle_kts)
    #   sed -i.bak "s/^version = \".*\"/version = \"$VERSION_MAJOR.$VERSION_MINOR.$VERSION_REV\"/" "$target_path"
    #   rm -f "${target_path}.bak"
    #   GIT_ADD_FILES+=("$target_path")
    #   echo "Updated build.gradle.kts: $target_path"
    #   ;;
    *)
      echo "Warning: Unknown target type '$target_type' for $target_path. Skipping."
      ;;
  esac
done

# Add and commit the changed files
if [ ${#GIT_ADD_FILES[@]} -gt 0 ]; then
  echo "Adding files to git: ${GIT_ADD_FILES[*]}"
  git add "${GIT_ADD_FILES[@]}"
else
  echo "No files configured to be added to git."
fi

echo "ez-version script finished."
