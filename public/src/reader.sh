#!/bin/bash

SCRIPT_SOURCE="$PWD"

LOGGER_SOURCE=''
LOGGER_COMMAND='tail'

SETTING_FILE='/Users/pwiejak/Desktop/logs/virtual-host.log'
SETTING_HOST=''
SETTING_PORT=''
SETTING_STATUS=''
SETTING_METHOD=''
SETTING_LENGTH=''
SETTING_FOLLOW=''

trap ctrl_c INT

function ctrl_c {
	msg "[ ! ]"
	msg "[ ! ]"
	msg "[ ! ] CTRL + C"
	msg "[ ! ]"
	msg "[ ! ] Good Bye!"
	msg "[ ! ]"
}

function init {
	msg "[ ! ]"
	msg "[ ! ] init"
	msg "[ ! ]"
	msg "[ ! ] USAGE:"
	msg "[ ! ] -h|--host example.com"
	msg "[ ! ] -p|--port 80"
	msg "[ ! ] -s|--status 200"
	msg "[ ! ] -m|--method GET"
	msg "[ ! ] -l|--length 25"
	msg "[ ! ] -i|--input \"/var/log/apache2/log/error.log\""
	msg "[ ! ] -f|--follow"
	msg "[ ! ] -d|--default"
	msg "[ ! ]"
	
	while [[ $# -gt 0 ]]
	do
		KEY="$1"
		
		case $KEY in
			-h|--host)
				SETTING_HOST="$2"
				shift
				shift
			;;
			-p|--port)
				SETTING_PORT="$2"
				shift
				shift
			;;
			-s|--status)
				SETTING_STATUS="$2"
				shift
				shift
			;;
			-m|--method)
				SETTING_METHOD="$2"
				shift
				shift
			;;
			-l|--length)
				SETTING_LENGTH="$2"
				shift
				shift
			;;
			-f|--file)
				SETTING_FILE="$2"
				shift
				shift
			;;
			-d|--default)
				#SETTING_FILE='/var/log/apache2/virtual-host.log'
				SETTING_FILE='/Users/pwiejak/Desktop/logs/virtual-host.log'
				SETTING_LENGTH=25
				SETTING_FOLLOW=true
				shift
			;;
		esac
	done

	listen
}

function listen {
	msg "[ ! ]"
	msg "[ ! ] listen"
	msg "[ ! ]"
		
	SEARCH=''
	
	msg "[ ! ] SETTINGS:"
	msg "[ ! ] Log File: $SETTING_FILE"
	
	if [ ! -z "${SETTING_STATUS}" ]; then
		SEARCH=$SEARCH" select(.response_status_code | contains(\"$SETTING_STATUS\")) |"
		msg "[ ! ] Status Code: $SETTING_STATUS"
	fi
	
	if [ ! -z "${SETTING_HOST}" ]; then
		SEARCH=$SEARCH" select(.server_name | contains(\"$SETTING_HOST\")) |"
		msg "[ ! ] Server Name: $SETTING_HOST"
	fi
	
	if [ ! -z "${SETTING_PORT}" ]; then
		SEARCH=$SEARCH" select(.server_port | contains(\"$SETTING_PORT\")) |"
		msg "[ ! ] Server Port: $SETTING_PORT"
	fi
	
	if [ ! -z "${SETTING_METHOD}" ]; then
		SEARCH=$SEARCH" select(.request_method | contains(\"$SETTING_METHOD\")) |"
		msg "[ ! ] HTTP Method: $SETTING_METHOD"
	fi
	
	if [ ! -z "${SETTING_LENGTH}" ]; then
		LOGGER_COMMAND="$LOGGER_COMMAND -n $SETTING_LENGTH"
		
		msg "[ ! ] Log Length: $SETTING_LENGTH"
	fi
	
	COMMAND_FIELDS='[
		.request_datetime,
		.request_date,
		.request_time,
		.response_status_code,
		.remote_addr,
		.server_name,
		.server_port,
		.request_file,
		.request_uri,
		.http_user_agent
	]'

	# get log files
	SETTING_FILE=`files ${SETTING_FILE}`
	
	# create command string
	COMMAND_QUERY="${SEARCH} ${COMMAND_FIELDS} | @tsv"
	COMMAND_FINAL="$LOGGER_COMMAND -f -q -- ${SETTING_FILE} | jq --raw-output --unbuffered '${COMMAND_QUERY}';"

	# seems like following command can't be used as tail doesn't use long parameter names
	# --retry doesn't exist on macos
	#COMMAND_FINAL="$LOGGER_COMMAND --follow=name --quiet --retry -- ${SETTING_FILE} | jq --raw-output --unbuffered '${COMMAND_QUERY}';"

	msg "[ ! ]"
	msg "[ ! ] RUNNING COMMAND: $COMMAND_FINAL"
	msg "[ ! ]"
		
	bash -c "$COMMAND_FINAL" | \
		while IFS=$'\t' read -r L_DATETIME L_DATE L_TIME L_CODE L_CLIENT L_HOST L_PORT L_FILE L_URI L_AGENT; do
			T_HOST=''
			T_SUBS=''
			
			if `valid_ip $L_HOST`; then # IP ADDRESS
				T_HOST="${L_HOST}"
			else # WEB ADDRESS
				IFS='.' read -ra HOST_PARTS <<< "${L_HOST}"

				if [ ${#HOST_PARTS[@]} -eq 2 ]; then
					T_HOST="${HOST_PARTS[0]}.${HOST_PARTS[1]}"
				fi

				if [ ${#HOST_PARTS[@]} -eq 3 ]; then
					T_SUBS="${HOST_PARTS[0]}"
					T_HOST="${HOST_PARTS[1]}.${HOST_PARTS[2]}"
				fi
			fi
			
			printf "| [%-10s - %-8s] %-15s %-8.8s %-25s %s\n" "${L_DATE}" "${L_TIME}" "${L_CLIENT}" "${T_SUBS}" "[${L_CODE}] ${T_HOST}:${L_PORT}" "${L_URI}"
		done
}

function valid_ip
{
	ARG_ADDRESS="$1"
    FUN_REGEX="(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])"
    FUN_TEST="^$FUN_REGEX\\.$FUN_REGEX\\.$FUN_REGEX\\.$FUN_REGEX$"
	
	if [[ $ARG_ADDRESS =~ $FUN_TEST ]]; then
		return 0
	else
		return 1
	fi
}

function files {
	SRC_PATH="$1"
	SRC_LIST=()

	# get files from root log directory
	if [ -f ${SRC_PATH} ]; then
		DIR_ROOT=`dirname ${SRC_PATH}`
		DIR_FILE=`basename ${SRC_PATH}`
		DIR_LIST=`find ${DIR_ROOT}/* 2> /dev/null`
		
		for ITEM_PATH in ${DIR_LIST}; do
			ITEM_FILE=`basename $ITEM_PATH`
			
			#echo $DIR_FILE | tr -d -c '.' | wc -c
			if [[ "${ITEM_FILE}" == "${DIR_FILE}"* ]]; then
				if [[ ! "${ITEM_FILE}" =~ \.t?gz$ ]]; then
					SRC_LIST+=("${ITEM_PATH}")
				fi
			fi
		done
	fi

	# sort array by value
	IFS=$'\n' sorted=($(sort <<<"${SRC_LIST[*]}"))
	
	# reverse the array
	TEMP_STRING=''
	
	reverse "${SRC_LIST[@]}" && for FILE_PATH in "${REVERSED[@]}"; do 
		TEMP_STRING="${TEMP_STRING} '${FILE_PATH}'"; 
	done
	
	# trim string
	TEMP_STRING="${TEMP_STRING#${TEMP_STRING%%[![:space:]]*}}"

	# return string
	echo "${TEMP_STRING}"
}

function reverse(){ 
	REVERSED=();
	local INDEX;
	
	for ((INDEX=$#; INDEX>0; INDEX--)); do
		REVERSED+=("${!INDEX}");
	done;
}

function msg {
    if [ $# -lt 1 ]; then
        echo "[ ! ] msg: parameter is missing"
    fi
	
	if [ $# -gt 1 ]; then
        echo "[ ! ] msg: passed too many parameters"
    fi
	
	echo "$1"
}

msg "[ ! ]"
msg "[ ! ] START"
init "$@"

msg "[ ! ] EXIT"
msg "[ ! ]"

exit 0