#!/bin/bash
# Initialize variables
prompt="Summarise the following file"
model="llama2"
script_dir="$(dirname "$0")"
cd "$script_dir"

echo -e "\n\n*** OLLAMA MODELS ***\n$(ollama list)\n ==> Above are the models that you have installed. Use --model [model]"

echo -e "\n\n*** PROMPTS ***\n$(ls $script_dir/prompts)\n ==> Above are the prompts that you have installed. Use --prompt [prompt] (do not include the .txt)"

# Parse remaining command-line options
url_or_file="$1"
shift
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --prompt)
            prompt_file="./prompts/$2.txt"
            if [[ -f "$prompt_file" ]]; then
                prompt=$(<"$prompt_file")
            else
                echo "Invalid prompt file. Exiting."
                exit 1
            fi
            shift 2  # Remove --prompt and its value
            ;;
        --model)
            available_models=$(ollama list | awk '{print $1}')
            if [[ $available_models == *"$2"* ]]; then
                model="$2"
            else
                echo "Invalid model. Exiting."
                exit 1
            fi
            shift 2  # Remove --model and its value
            ;;
        *)
            # Unrecognized option
            echo "Unrecognized option: $1. Exiting."
            exit 1
            ;;
    esac
done

# Initialize variables
. $script_dir/healthcheck.sh
whisper_model="ggml-large.bin"
whisper_command="$whisper_dir/main -l en -m /Users/cillian/whisper.cpp/models/$whisper_model -otxt -f"
folder="$HOME/Documents/summarizr/output_$(date +%Y%m%d_%H%M%S)"
parent_folder=$(dirname "$folder")
wav="$folder/temp.wav"
txt_output="$folder/$wav.txt"
echo "SELECTED PROMPT: $prompt"
echo "OLLAMA MODEL: $model"
echo "FILE/URL: $url_or_file"
echo "WHISPER.CPP INSTALL: $whisper_dir"

# Create output folder
mkdir -p "$folder"

# Step 1: Download video if URL is provided
if [[ $url_or_file == http* ]]; then
  echo "URL detected. Sending to yt-dlp"
  
  # Download to $folder
  yt-dlp "$url_or_file" -f 'best' -o "$folder/%(title)s.%(ext)s"
  title=$(yt-dlp --get-filename -o '%(title)s' "$url_or_file")
  clean_title=$(echo "$title" | tr -d '/?<>\\:*|"')

  # Make new folder
  mkdir -p "$parent_folder/$clean_title/"

  # Move contents of $folder to the new folder
  mv "$folder/"* "$parent_folder/$clean_title/"

  # Update $folder to point to the new location
  folder="$parent_folder/$clean_title"
  
  # Loop through files in the new folder
  for file in "$folder"/*; do
    if [[ "$file" == *"$title"* ]]; then
      wav="${file%.*}.wav"
      ffmpeg -i "$file" -ar 16000 "$wav"
    fi
  done
else
  # Copy the file to $folder
  escaped_var=$(printf '%q' "$url_or_file")
  cp "$escaped_var" "$folder/"
  
  # Derive wav filename
  wav="$folder/$(basename "$url_or_file")"
  
  for file in "$folder"/*; do
    if [[ "$file" =~ \.(mp4|mov|webm)$ ]]; then
      ffmpeg -i "$file" -ar 16000 "$wav"
    fi
  done
fi

# Step 3: Run whisper command
$whisper_command "$wav"

# Step 4: Run ollama command
# We need to redefine txt_output, as the values for folder and wav have changed 
txt_output="$wav.txt"
ollama run "$model" """ "$prompt" """ "$(cat "$txt_output")" | tee "$folder/AI-summary.md"

# Cleanup
rm -rf "$script_dir"/temp*