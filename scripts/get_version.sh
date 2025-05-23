#!/bin/bash

# Default configuration file path
DEFAULT_CONFIG_FILE="ez-version-config.json"
CONFIG_FILE="$DEFAULT_CONFIG_FILE"

# Function to show usage
usage() {
  echo "Usage: $0 [-c|--config <config_file>]"
  echo "  -c, --config  Path to the configuration file (default: $DEFAULT_CONFIG_FILE)"
  exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -c|--config) CONFIG_FILE="$2"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found."
  echo "Please create it or specify a valid path using -c or --config."
  echo "This script uses it to find the 'version_file_path'."
  echo "An example can be found at ez-version-config.json.example (for version.sh, but structure is similar for version_file_path)."
  exit 1
fi

# Read version_file_path from config
VERSION_JSON_PATH=$(jq -r '.version_file_path' "$CONFIG_FILE")

if [ -z "$VERSION_JSON_PATH" ] || [ "$VERSION_JSON_PATH" == "null" ]; then
  echo "Error: 'version_file_path' not found or is null in $CONFIG_FILE."
  exit 1
fi

# Check if version JSON file exists
if [ ! -f "$VERSION_JSON_PATH" ]; then
  echo "Error: Version JSON file '$VERSION_JSON_PATH' (specified in $CONFIG_FILE) not found."
  exit 1
fi

# Parse the JSON file to extract the constants
major=$(jq -r '.VERSION_MAJOR' "$VERSION_JSON_PATH")
minor=$(jq -r '.VERSION_MINOR' "$VERSION_JSON_PATH")
rev=$(jq -r '.VERSION_REV' "$VERSION_JSON_PATH")

# Echo the version string
echo "$major.$minor.$rev"