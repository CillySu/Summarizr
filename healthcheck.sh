#!/bin/bash
# Check for Xcode Command Line Tools
echo "Checking if user has installed xcode CLI tools"
if xcode-select -p &> /dev/null; then
  echo "Xcode Command Line Tools are installed."
else
  read -p "Xcode Command Line Tools are not installed. Install now? (y/n): " choice
  if [ "$choice" == "y" ]; then
    xcode-select --install
  else
    echo "Installation aborted."
    exit 1
  fi
fi

echo -e "Checking if user has whisper.cpp, ollama, ffmpeg, yt-dlp, python3 installed.\n\n"
# Initialize array
declare -a ADDR

# Populate array with whisper_dir
while IFS= read -r line; do
  ADDR+=("$line")
done < <(mdfind "kMDItemFSName == 'whisper.cpp' && kMDItemContentType == 'public.folder'" -onlyin $HOME)

# Check if the folder was found
if [ ${#ADDR[@]} -eq 0 ]; then
  echo "Folder 'whisper.cpp' not found."
  exit 1
fi

# If multiple folders are found, let the user select one
if [ ${#ADDR[@]} -gt 1 ]; then
  echo "Multiple folders found. Please select one:"
  select opt in "${ADDR[@]}"; do
    if [ "$opt" ]; then
      echo "You selected folder at: $opt"
      whisper_dir="$opt"
      break
    else
      echo "Invalid selection."
    fi
  done
else
  echo "Folder 'whisper.cpp' found at: ${ADDR[0]}"
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
  echo "Found ffmpeg in $(whereis ffmpeg)"
fi

# Check for ytdlp
if ! command -v yt-dlp &> /dev/null; then
  missing_packages+=("yt-dlp")
else
  echo "Found yt-dlp in $(whereis yt-dlp)"
fi

# Check for gcc
if ! command -v gcc &> /dev/null; then
  missing_packages+=("gcc")
else
  echo "Found gcc in $(whereis gcc)"
fi

# Check for clang
if ! command -v clang &> /dev/null; then
  missing_packages+=("clang")
else
  echo "Found clang in $(whereis clang)"
fi

# Check for python3
if ! command -v python3 &> /dev/null; then
  missing_packages+=("python3")
else
  echo "Found python3 in $(whereis python3)"
fi

# If missing packages, prompt for install
if [ ${#missing_packages[@]} -ne 0 ]; then
  echo "Missing packages: ${missing_packages[@]}"
  read -p "Do you want to install missing packages? (y/n): " choice

  if [ "$choice" == "y" ]; then
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi  # <-- Missing fi

    # Install ffmpeg, ytdlp, python3 via Homebrew
    for package in "${missing_packages[@]}"; do
      if [ "$package" != "ollama (manual install required)" ]; then
        brew install "$package"
      fi
    done

    # Notify about manual ollama install
    if [[ " ${missing_packages[@]} " =~ " ollama (manual install required) " ]]; then
      echo "Please manually install ollama as it's not available via Homebrew."
    fi
  else
    echo "Installation aborted."
  fi  # <-- Missing fi
else
  echo "All packages are installed."
fi


# Check for pip or pip3
echo -e "Checking if user has pip installed.\n\n"

if command -v pip &> /dev/null; then
  echo "Found pip installed at $(whereis pip)"
  pip_cmd="pip"
elif command -v pip3 &> /dev/null; then
  echo "Found pip installed at $(whereis pip3)"
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
    echo "Installation aborted."
    exit 1
  fi
fi