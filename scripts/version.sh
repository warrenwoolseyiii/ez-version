#!/bin/bash

# The input JSON file
input_file="scripts/version.json"
tmp_file="scripts/version.json.tmp"

### Bump the version ###
# Increment the rev field in the version.json file
jq ".VERSION_REV += 1" $input_file > $tmp_file
mv $tmp_file $input_file

### C ###

# The output header file
c_out_file="src/C/version.h"

# Parse the JSON file to extract the constants
major=$(cat $input_file | jq -r '.VERSION_MAJOR')
minor=$(cat $input_file | jq -r '.VERSION_MINOR')
rev=$(cat $input_file | jq -r '.VERSION_REV')

# Write the constants to the header file
echo "#ifndef VERSION_H_" > $c_out_file
echo "#define VERSION_H_" >> $c_out_file
echo "" >> $c_out_file
echo "#define VERSION_MAJOR $major" >> $c_out_file
echo "#define VERSION_MINOR $minor" >> $c_out_file
echo "#define VERSION_REV $rev" >> $c_out_file
echo "" >> $c_out_file
echo "#endif /* VERSION_H_ */" >> $c_out_file

### Python ###

# The output Python file
python_outfile="src/Python/version.py"

# Parse the JSON file to extract the constants
major=$(cat $input_file | jq -r '.VERSION_MAJOR')
minor=$(cat $input_file | jq -r '.VERSION_MINOR')
rev=$(cat $input_file | jq -r '.VERSION_REV')

# Write the constants to the Python file
echo "VERSION_MAJOR = $major" > $python_outfile
echo "VERSION_MINOR = $minor" >> $python_outfile
echo "VERSION_REV = $rev" >> $python_outfile

# Uncomment this if you have a version you want to add to a pyproject.toml file
# Read the version fields from the JSON file
#version_major=$(jq -r '.VERSION_MAJOR' $input_file)
#version_minor=$(jq -r '.VERSION_MINOR' $input_file)
#version_rev=$(jq -r '.VERSION_REV' $input_file)

# Create the version string
#version="$major.$minor.$rev"

# Insert the version string into the pyproject.toml file
#sed -i "s/version = \".*\"/version = \"$version\"/" path/to/pyproject.toml

### Kotlin ###

# The output Kotlin file
kotlin_outfile="src/Kotlin/Version.kt"

# Parse the JSON file to extract the constants
major=$(cat $input_file | jq -r '.VERSION_MAJOR')
minor=$(cat $input_file | jq -r '.VERSION_MINOR')
rev=$(cat $input_file | jq -r '.VERSION_REV')

# Write the constants to the Kotlin file
echo "object Version {" > $kotlin_outfile
echo "    const val VERSION_MAJOR = $major" >> $kotlin_outfile
echo "    const val VERSION_MINOR = $minor" >> $kotlin_outfile
echo "    const val VERSION_REV = $rev" >> $kotlin_outfile
echo "}" >> $kotlin_outfile

# Uncomment this if you have a version you want to add to a build.gradle.kts file
# Read the version fields from the JSON file
#version_major=$(jq -r '.VERSION_MAJOR' $input_file)
#version_minor=$(jq -r '.VERSION_MINOR' $input_file)
#version_rev=$(jq -r '.VERSION_REV' $input_file)

# Create the version string
#version="$major.$minor.$rev"

# Insert the version string into the build.gradle.kts file
#sed -i "s/version = \".*\"/version = \"$version\"/" protocol-implementation/Kotlin/serial-protocol/build.gradle.kts

# Add and commit the version.json file
#./../../protocol-implementation/Kotlin/gradlew build
#git add protocol-implementation/Kotlin/serial-protocol/build.gradle.kts
#git add protocol-implementation/Python/pyproject.toml
git add $input_file
git add $python_outfile
git add $c_out_file
git add $kotlin_outfile
