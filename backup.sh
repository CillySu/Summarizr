#!/bin/bash

# Initialize defaults
file="$1"
prompt="Default prompt text."
model="llama2"
skip_summary="false"
ollama_models=$(ollama list | tr -d '\n' | tr -d ' ')

# FFMPEG supported formats
declare -A supported_formats=([mp4]=1 [avi]=1 [mkv]=1 [flv]=1 [mov]=1 [webm]=1 [mp3]=1 [mp4]=1)


# Usage
if [ "$#" -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--usage" ]]; then
	echo "Usage: ./yt-summary.sh [URL] --prompt [qbank, summary] --model [$ollama_models] --skip-summary"
	exit 0
fi


# Handle arguments
shift
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --prompt)
      shift
      prompt="$1"
      ;;
    --model)
      shift
      model="$1"
      ;;
    --skip-summary)
      skip_summary="true"
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# Validation for model
if [[ ! "$ollama_models" == *"$model"* ]]; then
	echo "Invalid model. Must be one of: $ollama_models"
	exit 1
fi

# Debugging prints
echo "URL: $url"
echo "Prompt template: $prompt"
echo "Model: $model"
echo "Skip Summary: $skip_summary"
echo "First Arg: $1"

# Parsing
#OPTIND=1
#				"usmle")			prompt="On the next paragraph I will supply a transcript of a YouTube video of a USMLE Step 1 QBank question explained. I want for you to extract salient information from the transcript and present it in a visually appealing way. I want you to use the headings of 'Clinical Vignette' (With a markdown table for age, gender, presenting complaint, medical history, other pertinent information), 'Question asked', 'Answer Choices', 'Correct Answer' and 'Explanations' (for the correct AND incorrect answers). I want you to also list ALL salient information contained within the transcript, such as important associations made typically in the USMLE. Format your answer in markdown and be as succinct as possible. Focus on delivering the important high-yield USMLE concepts as well as possible. The transcript is supplied below:";;
#				"qbank")			prompt="On the next paragraph I will supply a transcript of a YouTube video of a question-bank question explained by a narrator. I want for you to extract salient information from the transcript and present it in a visually appealing way. I want you to use appropriate headings and also to include 'Question asked', 'Answer Choices', 'Correct Answer' and 'Explanations' (for both the correct AND incorrect answers). I want you to also list ALL salient information contained within the transcript, such as important associations made typically in the exam. Format your answer in markdown and be as succinct as possible. Focus on delivering the important high-yield exam concepts as well as possible. The transcript is supplied below:";;
#				"summary")		prompt="You are provided below with a transcript of a youtube video. Do your best to summarise the transcript in the manner you feel would be most of use to a viewer of this video. Do your best to include all salient points without including unnecessary information.";;
#				*)						prompt="You are provided below with a transcript of a youtube video. Do your best to summarise the transcript in the manner you feel would be most of use to a viewer of this video. Do your best to include all salient points without including unnecessary information.";;


# Utility function to print in colors
print_colored() {
  echo "\033[1;34m$1\033[0m"
}

# Get current date/time for folder name
now=$(date +%Y-%m-%d_%H-%M-%S)

# */ Execution Block Start
arg1="$1"
echo "$arg1"

if [[ $arg1 =~ ^https?:// ]]; then
  # It's a URL, proceed as normal
  url="$arg1"
else
  # It's a file path
  filepath="$arg1" 
fi


# Create download folder with date/time name
if [[ ! -z "$filepath" ]]; then
  filename="$(basename "$filepath")"
  download_dir="${filepath%/*}/$filename"
else
  download_dir="$HOME/Documents/Whisper/$now"
  print_colored "Making new directory at $download_dir"
  print_colored " *** This will be renamed to the video title later *** "
  mkdir -p "$download_dir"
fi

# Initialize wav_files array
wav_files=()

if [[ ! -z "$url" ]]; then
  # Download with yt-dlp
  print_colored "==> Downloading Video"
  yt-dlp "$url" -f 'best' -o "$download_dir/%(title)s.%(ext)s"
  # Extract title from one of the downloaded files
  yt_title=$(ls "$download_dir" | head -1 | sed 's/\..*//')
fi


# Convert files to wav
if [[ ! -z "$filepath" ]]; then
  fileForConversion="$download_dir"
else
  # Assume all files in download_dir need to be converted
  fileForConversion="$download_dir/*"
fi

# Loop through all files for conversion
for file in $fileForConversion; do
  if [ -f "$file" ]; then  # Only process if it's a file
    extension="${file##*.}"
    # Check if the file extension is in supported_formats
    if [[ ${supported_formats[$extension]} ]]; then
      # Your conversion logic here, e.g., with ffmpeg
      echo "Converting $file to WAV format"
        ffmpeg -i "$file" -ar 16000 "$wav_file"
      # ffmpeg -i "$file" "${file%.*}.wav"
    else
      echo "Skipping $file (unsupported format)"
    fi
  fi
done

# Check for empty array
[[ ${#wav_files[@]} -eq 0 ]] && { echo "No WAV files"; exit 1; }
print_colored "ERROR: No .wav files found"

# Rename folder based on yt_title
if [[ ! -z "$yt_title" ]]; then
  print_colored "==> Renaming Folder"
  new_dir="$HOME/Documents/Whisper/$yt_title"
  mv "$download_dir" "$new_dir"
  fileForConversion="$new_dir"
  
  # Create a new array for storing updated paths
  new_wav_files=()
  
  for wav_file in "${wav_files[@]}"; do
    new_wav_file="${wav_file//$download_dir/$new_dir}"
    new_wav_files+=("$new_wav_file")
  done
  
  # Update the original wav_files array
  wav_files=("${new_wav_files[@]}")
  
  download_dir="$new_dir"
fi

# Run whisper
print_colored "==> Running Whisper"
~/whisper.cpp/main -l en -m ~/whisper.cpp/models/ggml-large.bin -otxt -f "${wav_files[@]}"

# Generate AI-based summary
print_colored "==> Generating Summary"
txt="${wav_files[*]}.txt"
folder=$(dirname "$txt")

if [ "$skip_summary" = false ]; then
  ollama run llama2 """
  "$prompt"
  """ "$(cat "$txt")" | tee "$folder"/AI-summary.md
fi

