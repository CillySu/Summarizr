# Format variables
BF="\033[1m" # Bold
BL="\033[34m" # Blue
GR="\033[32m" # Green
RD="\033[31m" # Red
RS="\033[0m" # Reset

source ~/.zshrc > /dev/null 2>&1

# Check if alias already exists
if [[ $(alias | grep 'summarizr=') ]]; then
  echo "${BF}${GR}Summarizr${RS} is already installed!"
  echo "Usage: Summarizr [Video/.txt/URL] --prompt [prompt_template] --ollama [ollama_model] --whisper [whisper_model]"
  echo "Supported websites include...\n\n"
  echo $(man ./supported-sites.1)
  exit 1
fi

echo "response?Would you like to install ${BF}${GR}Summarizr${RS} as an alias to your .zshrc?\n\n\nThis allows you to run ${BF}${GR}Summarizr${RS} by simply typing ${BF}${GR}Summarizr${RS} in the terminal, instead of having to type the full path to ${BF}${GR}Summarizr${RS}. \n\n(${GR}[Y]${RS}/${RD}[N]${RS})"
read response

if [[ $response == "y" ]]; then
  echo "\# /* Summarizr installation block" >> ~/.zshrc
  echo "alias summarizr=\"\$script_dir/Summarizr.sh\"" >> ~/.zshrc
  echo "alias Summarizr=\"\$script_dir/Summarizr.sh\"" >> ~/.zshrc
  echo "\# Summarizr installation block */" >> ~/.zshrc
  echo "Aliases added."
else
  echo "Operation cancelled."
fi