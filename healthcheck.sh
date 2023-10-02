#!/bin/bash
# Check for Xcode Command Line Tools
# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Checking if user has installed xcode CLI tools${NC}"
if xcode-select -p &> /dev/null; then
  echo -e "Xcode Command Line Tools are installed."
else
  read -p "Xcode Command Line Tools are not installed. Install now? (y/n): " choice
  if [ "$choice" == "y" ]; then
    xcode-select --install
  else
    echo -e "Installation aborted."
    exit 1
  fi
fi

echo -e "\n${GREEN}Checking if user has whisper.cpp, ollama, ffmpeg, yt-dlp, python3 installed.${NC}\n"
# Initialize array
declare -a ADDR

# Populate array with whisper_dir
while IFS= read -r line; do
  ADDR+=("$line")
done < <(mdfind "kMDItemFSName == 'whisper.cpp' && kMDItemContentType == 'public.folder'" -onlyin $HOME)

# Check if the folder was found
if [ ${#ADDR[@]} -eq 0 ]; then
  echo -e "${RED}Folder 'whisper.cpp' not found.${NC}"
  exit 1
fi

# If multiple folders are found, let the user select one
if [ ${#ADDR[@]} -gt 1 ]; then
  echo -e "Multiple folders found. Please select one:"
  select opt in "${ADDR[@]}"; do
    if [ "$opt" ]; then
      echo -e "You selected folder at: $opt"
      whisper_dir="$opt"
      break
    else
      echo -e "${RED}Invalid selection.${NC}"
    fi
  done
else
  echo -e "Folder 'whisper.cpp' found at: ${ADDR[0]}"
  whisper_dir="${ADDR[0]}"
fi

# Initialize array for missing packages
declare -a missing_packages

# Check for ollama
if ! command -v ollama &> /dev/null; then
  missing_packages+=("ollama (manual install required)")
fi

# Check for ffmpeg
if ! command -v ffmpeg &> /dev/null; then
  missing_packages+=("ffmpeg")
else
  echo -e "Found ffmpeg in $(whereis ffmpeg)"
fi

# Check for ytdlp  
if ! command -v yt-dlp &> /dev/null; then
  missing_packages+=("yt-dlp")
else
  echo -e "Found yt-dlp in $(whereis yt-dlp)"
fi

# Check for gcc
if ! command -v gcc &> /dev/null; then
  missing_packages+=("gcc") 
else
  echo -e "Found gcc in $(whereis gcc)"
fi

# Check for clang
if ! command -v clang &> /dev/null; then
  missing_packages+=("clang")
else
  echo -e "Found clang in $(whereis clang)" 
fi

# Check for python3
if ! command -v python3 &> /dev/null; then
  missing_packages+=("python3")
else
  echo -e "Found python3 in $(whereis python3)"
fi

# If missing packages, prompt for install
if [ ${#missing_packages[@]} -ne 0 ]; then
  echo -e "\n${RED}Missing packages: ${missing_packages[@]}${NC}"
  read -p "Do you want to install missing packages? (y/n): " choice

  if [ "$choice" == "y" ]; then
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install ffmpeg, ytdlp, python3 via Homebrew
    for package in "${missing_packages[@]}"; do
      if [ "$package" != "ollama (manual install required)" ]; then
        brew install "$package"
      fi
    done

    # Notify about manual ollama install 
    if [[ " ${missing_packages[@]} " =~ " ollama (manual install required) " ]]; then
      echo -e "${RED}Please manually install ollama as it's not available via Homebrew.${NC}"
    fi
  else
    echo -e "Installation aborted."
  fi
else
  echo -e "All packages are installed."
fi


# Check for pip or pip3
echo -e "\n${GREEN}Checking if user has pip installed.${NC}\n" 

if command -v pip &> /dev/null; then
  echo -e "Found pip installed at $(whereis pip)"
  pip_cmd="pip"
elif command -v pip3 &> /dev/null; then
  echo -e "Found pip installed at $(whereis pip3)"
  pip_cmd="pip3"
else
  read -p "Neither pip nor pip3 is installed. Install pip? (y/n): " choice
  if [ "$choice" == "y" ]; then
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install python3
    pip_cmd="pip3"
  else
    echo -e "Installation aborted."
    exit 1
  fi
fi

# Initialize array for missing libraries  
echo -e "\n${GREEN}Checking if user has python libraries ane_transformers, openai-whisper, coremltools installed.${NC}\n"
declare -a pip_missing_libraries

# Check for ane_transformers
if ! $pip_cmd show ane_transformers > /dev/null 2>&1; then
  pip_missing_libraries+=("ane_transformers")  
fi

# Check for openai-whisper
if ! $pip_cmd show openai-whisper > /dev/null 2>&1; then
  pip_missing_libraries+=("openai-whisper")
fi

# Check for coremltools
if ! $pip_cmd show coremltools > /dev/null 2>&1; then
  pip_missing_libraries+=("coremltools")
fi

# If missing libraries, prompt for install
if [ ${#pip_missing_libraries[@]} -ne 0 ]; then
  echo -e "\n${RED}Missing libraries: ${pip_missing_libraries[@]}${NC}"
  read -p "Do you want to install missing libraries? (y/n): " choice

  if [ "$choice" == "y" ]; then    
    for library in "${pip_missing_libraries[@]}"; do
      $pip_cmd install "$library"
    done
  else
    echo -e "Installation aborted."
  fi
else
  echo -e "All libraries are installed."  
fi