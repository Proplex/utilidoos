#!/usr/bin/env bash
# pomf.se uploader
# https://gist.github.com/KittyKatt/5818701
# requires: curl

if ! type 'curl' &> /dev/null; then
	err 'requires curl to upload'
	exit 1
fi

err() {
	echo -e "\033[1;31m$1\033[0m" >&2
}

dest_url='https://files.seventhprotocol.com/upload.php'
return_url='https://f.ipv7.sh/'

if [[ -z "${1}" ]]; then
	err 'Error! You must supply a filename to upload!'
	exit 1
fi

file="${1}"
ext="${file##*.}"

if [[ ! -f "${file}" ]]; then
	err 'Error! File does not exist!'
	exit 1
fi

#echo -n "Uploading ${file}..."
curloutput=$(curl --silent -sf -F files[]="@${file}" "${dest_url}")
return_file=''

for (( n=0; n < 3; n+=1 )); do
 #       echo $curloutput
	if [[ "${curloutput}" =~ '"success": true,' ]]; then
		#TODO: this sucks
		return_file=$(echo "$curloutput" | grep -Eo "\"url\": \"https\:\\\/\\\/f.ipv7.sh\\\/[A-Za-z0-9]+\.${ext}\"," | sed 's/"url": "//;s/",//' | sed 's/\\//g')
		break
	else
		err 'failed'
	fi
done

if [[ -z ${return_file} ]]; then
	err 'Error! File not uploaded'
	exit 1
else
	echo "File can be found at: ${return_file}"
        echo ${return_file} | pbcopy
fi
