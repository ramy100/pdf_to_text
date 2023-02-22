#!bin/bash
pdf_file=$1
languages=$2
output_file_name="${3:-output}"
new_dir_name=$(date '+%Y%m%d%H%M%S')_$RANDOM
tesseract_path="./bin/tesseract"
gs_path="./bin/ghostscript-10.0.0-linux-x86_64/"
IFS='+' read -ra languagesArr <<<"$languages"

#download language data if not existing
function download_language_data {
  # Check if the language trained data file exists
  if [ -e "./bin/tesseract/$1.traineddata" ]; then
    echo "The language trained data already exists so will be using it..."
  else
    echo "The language '$1' trained data file does not exist downloading it first...'."
    wget -q -P $tesseract_path "https://github.com/tesseract-ocr/tessdata/raw/main/$1.traineddata"
  fi
  return $?

}

#cleaning up unneeded files and folders
function cleanup_and_exit {
  echo "removing files and cleaning up"
  rm -rf ./"$new_dir_name"
  rm ./"$new_dir_name".txt
  exit 1
}

#checking if arguments is provided
if [ -z "$pdf_file" ]; then
  echo "please pass the pdf file you want to convert to this script. Exiting script."
  exit 1
fi

if ! file -b --mime-type "$pdf_file" | grep -q "pdf$"; then
  echo "The file passed is not a PDF file. Exiting script."
  exit 1
fi

if [ -z "$languages" ]; then
  echo "please pass the language. Exiting script."
  exit 1
fi

# Generate a unique name based on the current date and a random number
mkdir ./"$new_dir_name"

"$gs_path/gs-1000-linux-x86_64" -dSAFER -dNOPAUSE -dBATCH -sDEVICE=jpeg -r300 -dJPEGQ=100 -sOutputFile=./"$new_dir_name"/output_%03d.jpg "$pdf_file"

#getting list of images names
ls -1 ./"$new_dir_name"/* >./"$new_dir_name".txt

for item in "${languagesArr[@]}"; do
  if !(download_language_data $item); then
    echo "error downloading the language $item"
    cleanup_and_exit
  fi
done

"$tesseract_path/tesseract" --tessdata-dir $tesseract_path ./"$new_dir_name".txt "$output_file_name" -l $languages
#converting images to text file
cleanup_and_exit
