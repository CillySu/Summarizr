#!/bin/bash
# Initialize variables
# Format variables
BF="\033[1m" # Bold
BL="\033[34m" # Blue
GR="\033[32m" # Green
RD="\033[31m" # Red
RS="\033[0m" # Reset

# Initialize variables
prompt="Summarise the following file"
ollama_model="llama2"
whisper_model="ggml-large.bin"
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
skip_whisper=l
url=0
txt_file=0
local_file=0

echo -e "Running ${BF}Summarizr${RS} from: $script_dir"

. $script_dir/healthcheck.sh
whisper_command="$whisper_dir/main -l en -m $whisper_dir/models/$whisper_model -otxt -f"
folder="$HOME/Documents/summarizr/output_$(date +%Y%m%d_%H%M%S)"
parent_folder=$(dirname "$folder")
wav=""
txt_output=""

echo -e "\n${BF}${BL}*** OLLAMA MODELS ***${RS}"  
echo -e "$(ollama list)"
echo -e "==> Above are the models that you have installed. Use --ollama [model]\n"

echo -e "\n${BF}${BL}*** PROMPTS ***${RS}"
echo -e "$(ls -laG $script_dir/prompts)"
echo -e "==> Above are the prompts that you have installed. Use --prompt [prompt] (${BF}do ${RD}not${RS} include the .txt)\n"

echo -e "\n${BF}${BL}*** WHISPER MODELS***${RS}"
echo -e "$(ls -laG $whisper_dir/models | grep '.*.bin')"
echo -e "==> Above are the whisper models that you have installed. Use --whisper [model] (${BF}do ${RD}not${RS} include the .bin)\n"

clean_extension(){
  local file_name="$1"
  local new_extension="$2"
  # Use awk to remove all extensions except the last one and remove extra spaces
  local new_cleaned_name=$(echo "$file_name" | awk -F'.' '{if (NF>1) {$NF=""; print $0} else {print $0}}' | sed 's/ *$//')
  echo "${new_cleaned_name}.${new_extension}"
}

# Parse remaining command-line options
url_or_file="$1"
shift
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --prompt)
            prompt_file="$script_dir/prompts/$2.txt"
            if [[ -f "$prompt_file" ]]; then
                prompt=$(<"$prompt_file")
            else
                echo "Invalid prompt file. Exiting."
                exit 1
            fi
            shift 2  # Remove --prompt and its value
            ;;
        --ollama)
            installed_ollama_models=$(ollama list | awk '{print $1}')
            if [[ $installed_ollama_models == *"$2"* ]]; then
                ollama_model="$2"
            else
                echo "Invalid model. Exiting."
                exit 1
            fi
            shift 2  # Remove --ollama and its value
            ;;
        --whisper)
            installed_whisper_models=$(ls "$whisper_dir/models")
            found_model=false
            for model in $installed_whisper_models; do
              if [[ $model == "$2.bin" ]]; then
                found_model=true
              break
              fi
            done
        if $found_model; then
          whisper_model="$2.bin"
        else
          echo "Invalid model. Exiting."
          exit 1
        fi
        shift 2  # Remove --whisper and its value
        ;;
      *)
            # Unrecognized option
            echo "Unrecognized option: $1. Exiting."
            exit 1
            ;;
    esac
done

# DEBUGGING
echo -e "\n${BF}${BL}SELECTED PROMPT:${RS} $prompt"
echo -e "${BF}${BL}${BL}OLLAMA MODEL:${RS} $ollama_model"
echo -e "${BF}${BL}FILE/URL:${RS} $url_or_file"
echo -e "${BF}${BL}WHISPER.CPP INSTALL:${RS} $whisper_dir"
echo -e "${BF}${BL}WHISPER.CPP MODEL:${RS} $whisper_model"
echo -e "${BF}${BL}WHISPER COMMAND BEING RUN:${RS} $whisper_command"


# Step 1: Download video if URL is provided
# /* START - IF URL
# Create output folder
mkdir -p "$folder"
if [[ $url_or_file == http* ]]; then
  url=1
  echo -e "\n\n${BF}${GR}URL detected 🔗: Sending to yt-dlp${RS}\n"
  
  # Download to $folder
  yt-dlp "$url_or_file" -f 'best' -o "$folder/%(title)s.%(ext)s"
  title=$(yt-dlp --get-filename -o '%(title)s' "$url_or_file")
  clean_title=$(echo "$title" | tr -d '/?<>\\:*|"')
  
  # Make new folder using the title of the video
  mkdir -p "$parent_folder/$clean_title/"
  
  # Move contents of $folder to the new folder
  mv "$folder/"* "$parent_folder/$clean_title/"
  
  # Update $folder to point to the new location
  folder="$parent_folder/$clean_title"
  
  # Loop through files in the new folder
  for file in "$folder"/*; do
    if [[ "$file" == *"$title"* ]]; then
      wav="${file%.*}.wav"
      wav=$(clean_extension "$wav" "wav")
      ffmpeg -i "$file" -ar 16000 "$wav"
    fi
  done 
# END - IF URL */

# /* START - IF TEXT FILE
elif [[ "$url_or_file" =~ \.(txt)$ ]]; then
  # Create output folder
  folder=$(dirname $url_or_file)
  echo -e "\n\n${BF}${GR}Text file detected: 📝 - Skipping ${BF}FFmpeg, Whisper.cpp${RS}\n"
  txt_file=1
  skip_whisper=1
# END - IF TEXT FILE */

# */ START - IF LOCAL VIDEO FILE
elif [[ -f "$url_or_file" ]]; then
  echo -e "\n\nLocal file detected: 🗂️ - Running ${BF}FFmpeg${RS} to get 16kHz .wav\n"
  local_file=1
  folder=$(dirname "$url_or_file")
  local_wav=$(basename "$url_or_file")
  local_wav=$(clean_extension "$local_wav" wav)
  ffmpeg -i "$url_or_file" -ar 16000 "$folder/$local_wav"
  wav="$folder/$local_wav"
# END - IF LOCAL VIDEO */

else
  echo -e "Invalid file/url passed. Usage is:\n\n summarizr [FILE PATH or URL] [--options]"
fi

# Step 3: Run whisper command
echo -e "\n${BF}${GR}Running Whisper 🤫${RS}"
$whisper_command "$wav"
# We need to redefine txt_output, as the values for folder and wav have changed 

# /* START defining txt_output depending on whether txt file, local video or URL was passed
if [[ $txt_file -eq 1 ]]; then
  echo "Found txt_file to be True"
  txt_output=$url_or_file 
  txt_output=$(clean_extension "$url_or_file" txt)
elif [[ $local_file -eq 1 ]]; then
  echo "Found local_file to be True"
  txt_output=$wav
  txt_output=$(clean_extension "$wav" txt)
elif [[ $url -eq 1 ]]; then
  echo "Found url to be True"
  txt_output=$wav
  txt_output=$(clean_extension "$wav" txt)
else
  echo "No valid flags set."
fi
# END defining txt_output depending on whether txt file, local video or URL was passed */

echo "Final Variables:"
echo "url_or_file $url_or_file"
echo "txt_output: $txt_output"
echo "wav: $wav"
echo "folder: $folder"

# Step 4: Run ollama command

echo -e "\n${BF}${GR}Running Ollama 🦙${RS}"
ollama run "$ollama_model" """ "$prompt" """ "$(cat "$txt_output")" | tee "$folder/AI-summary.md"
echo -e "${BF}${GR}Your $ollama_model summary can be found at:\n$folder/AI-summary.md"

# Cleanup
# rm -rf "$script_dir"/temp*