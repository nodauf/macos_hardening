#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
LIGHTGRAY='\033[0;37m'
NC='\033[0m' # No Color

################################################################################
#                                                                              #
#                                 FUNCTIONS                                    #
#                                                                              #
################################################################################

function Usage() {
  echo "Usage: ./tethys.sh [options]"
  echo "  -s (--status)   : read method to read configuration"
  echo "  -a (-audit)     : audit method to audit configuration"
  echo "  -r (-reinforce) : apply a configuration)"
  echo "  -h : help method"
}

function FirstPrint() {
  echo "User name : $USER"
  echo "Mode to apply : $MODE"
  echo "CSV File configuration : $INPUT"
}

function PrintResult() {
  ID=$1
  Name=$2
  ReturnedExit=$3
  ReturnedValue=$4

  case $ReturnedExit in
    0 )#No Error
    echo "[-] $ID : $Name ; ActualValue = $ReturnedValue"
      ;;
    1 )#Error Exec
    echo -e "${YELLOW}[x] $ID : $Name ; Error : The execution caused an error${NC}"
      ;;
    26 )#Error exist policy
    echo -e "${LIGHTGRAY}[!] $ID, $Name${NC}"
    echo -e "${YELLOW}Warning : This policy does not exist yet${NC}"
      ;;
  esac
}

################################################################################
#                                                                              #
#                                  OPTIONS                                     #
#                                                                              #
################################################################################

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      Usage
      exit 1
      ;;
    -a|--audit)
      INPUT="$2"
      MODE="AUDIT"
      shift # past argument
      shift # past value
      ;;
    -s|--status)
      INPUT="$2"
      MODE="STATUS"
      shift # past argument
      shift # past value
      ;;
    -r|--reinforce)
      INPUT="$2"
      MODE="REINFORCE"
      shift # past argument
      shift # past value
      ;;
    -b|--backup)
      INPUT="$2"
      MODE="BACKUP"
      shift # past argument
      shift # past value
      ;;
    --default)
      DEFAULT=YES
      shift # past argument
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done


## Define default CSV File configuration ##
if [[ -z $INPUT ]]; then #if INPUT is empty
  INPUT='list.csv'
fi

set -- "${POSITIONAL[@]}" # restore positional parameters

################################################################################
#                                                                              #
#                                 MAIN CODE                                    #
#                                                                              #
################################################################################

FirstPrint

### Global varibles
PRECEDENT_CATEGORY=''

## Save old separator
OLDIFS=$IFS
## Define new separator
IFS=','

## If CSV file does not exist
if [ ! -f $INPUT ]; then
  echo "$INPUT file not found";
  exit 99;
fi
while read ID Category Name Method MethodArgument RegistryPath RegistryItem ClassName Namespace Property DefaultValue RecommendedValue Operator Severity
do
  ## We will not take the first row
  if [[ $ID != "ID" ]]; then

    PARAMETER=$1

    ## Print category
    if [[ $PRECEDENT_CATEGORY != $Category ]]; then
      echo #new line
      echo "-----------------------------"
      DateValue=$(date +"%D %X")
      echo "[*] $DateValue Starting Category $Category"
      PRECEDENT_CATEGORY=$Category
    fi

    #
    #
    # STATUS MODE
    #
    #
    if [[ $MODE == "STATUS" ]]; then
      ## Test if file exist
      if [[ ! -f "$RegistryPath.plist" ]]; then
        ReturnedExit=26
      else
        # throw away stderr
        ReturnedValue=$(defaults read $RegistryPath $RegistryItem 2>/dev/null)
        ReturnedExit=$?
        # if an error occurs, it's caused by non-existance of the couple (file,item)
        # we will not consider this as an error, but as an warning
        if [[ $ReturnedExit == 1 ]]; then
          ReturnedExit=26
        fi
      fi

    fi

    ## Result printing
    PrintResult "$ID" "$Name" "$ReturnedExit" "$ReturnedValue"

  fi
done < $INPUT

## Redefine separator with its precedent value
IFS=$OLDIFS