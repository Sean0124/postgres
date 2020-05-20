#!/bin/bash
#--------------------------------------------------------
#Filename: build_image.sh
#Revision: v0.0.1
#Data: 2019/6/10
#Author: Sean
#Email: sean.x.dbm@gmail.com
#Description:
#Note:
#-------------------------------------------------------
#Version v0.0.1
#The first one, can input hub/subdir/name/tag build docker image
ARGS=`getopt -o sh --long show,help -n 'example.sh' -- "$@"`
if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi
eval set -- "${ARGS}"

if [ ! -f README.md ]; then
cat >> README.md << EOF
DOCKER_HUB=registry.cloudclusters.net
HUB_SUBDIR=cloudclusters
IMAGE_NAME=xxxx
IMAGE_TAG=xxx-v0.0.0
EOF
fi

DOCKER_HUB=`sed '/^DOCKER_HUB=/!d;s/.*=//' README.md`
HUB_SUBDIR=`sed '/^HUB_SUBDIR=/!d;s/.*=//' README.md`
IMAGE_NAME=`sed '/^IMAGE_NAME=/!d;s/.*=//' README.md`
IMAGE_TAG=`sed '/^IMAGE_TAG=/!d;s/.*=//' README.md`

TAG_PRO=${IMAGE_TAG/[0-9].[0-9].[0-9]/}
TAG_NUM=${IMAGE_TAG/*[a-z]-v/}
TAG_NUM01=`echo ${TAG_NUM} | awk -F . '{print $1}'`
TAG_NUM02=`echo ${TAG_NUM} | awk -F . '{print $2}'`
TAG_NUM03=`echo ${TAG_NUM} | awk -F . '{print $3}'`

function change_version {
	let TAG_NUM03++
	if [ ${TAG_NUM03} -ge 10 ];then
		let TAG_NUM02++
		TAG_NUM03=0
		if [ ${TAG_NUM02} -ge 10 ];then
			let TAG_NUM01++
			TAG_NUM02=0
		 fi
	fi

	NEW_TAG_NUM=${TAG_NUM01}.${TAG_NUM02}.${TAG_NUM03}
	NEW_IMAGE_TAG=${TAG_PRO}${NEW_TAG_NUM}
}

function read_input {
	INPUT=''
	local default="$1"
	local prompt="$2"
	local answer
	read -t 30 -p "$prompt" answer
	[ -z "$answer" ] && answer="$default"
	INPUT=$answer
}

function choice {
    read_input $1 "$2"
    answer=$INPUT
    case "$answer" in
    [yY1] )
        INPUT='y'
        ;;
    [nN0] )
        INPUT='n'
        ;;
    * )
        echo "%b" "Unexpected answer '$answer'!" >&2
        ;;
    esac
}

function build_image {
    read_input ${DOCKER_HUB} "Please input docker hub address [${DOCKER_HUB}]:"
    NEW_DOCKER_HUB=$INPUT
    NEW_HUB_SUBDIR=${HUB_SUBDIR}
    read_input ${IMAGE_NAME} "Please input image name [${IMAGE_NAME}]:"
    NEW_IMAGE_NAME=$INPUT
    choice y "Please select whether to input old tag [${IMAGE_TAG}] (Y/N):"
    if [ ${INPUT} = n ];then
    	read_input ${IMAGE_TAG} "Please input image tag [${IMAGE_TAG}]:"
    	NEW_IMAGE_TAG=$INPUT
    else 
    	change_version
    fi

    NEW_IMAGE=${DOCKER_HUB}/${NEW_HUB_SUBDIR}/${NEW_IMAGE_NAME}:${NEW_IMAGE_TAG}
    AGENT_DIR="root/agent"
    if [ -d root ]; then
        choice y "Please select whether to git pull code: ${AGENT_DIR}  (Y/N):"
        if [ ${INPUT} == y ];then
    	    read_input ${AGENT_DIR} "Please input git pull dir ${AGENT_DIR}:"
        	NEW_AGENT_DIR=${INPUT}
        	echo -e "\e[1;33mgit pull ... \e[0m"
        	git -C ${NEW_AGENT_DIR} pull
        fi

    fi

    echo -e "\e[1;33mdocker build ... \e[0m"
    docker build -t $NEW_IMAGE .
    if [ $? == 0 ]; then
        sed -i s/DOCKER_HUB=${DOCKER_HUB}/DOCKER_HUB=${NEW_DOCKER_HUB}/ README.md
        sed -i s/HUB_SUBDI=${HUB_SUBDIR}/HUB_SUBDI=${NEW_HUB_SUBDIR}/ README.md
        sed -i s/IMAGE_NAME=${IMAGE_NAME}/IMAGE_NAME=${NEW_IMAGE_NAME}/ README.md
        sed -i s/IMAGE_TAG=${IMAGE_TAG}/IMAGE_TAG=${NEW_IMAGE_TAG}/ README.md
    fi

    choice y "Please select whether to upload new image $NEW_IMAGE (Y/N):"
    if [ ${INPUT} == y ];then
    	echo -e "\e[1;33mdocker push ... \e[0m"
            docker push $NEW_IMAGE
    	echo -e "\e[1;32mpsuh $NEW_IMAGE successfully \e[0m"
    else
    	echo -e "\e[1;31mPlsease manual push: \e[0m \e[1;32m$NEW_IMAGE \e[0m"
    fi

    echo -e New image: "\e[1;32m${NEW_IMAGE} \e[0m"
}

if [ "$1" == "--" ]; then
    build_image
else
    while [ -n "$1" ]
    do
        case "$1" in
        -s|--show)
            IMAGE=${DOCKER_HUB}/${HUB_SUBDIR}/${IMAGE_NAME}:${IMAGE_TAG}
            echo "${IMAGE}"
            ;;
        -h|--help)
            echo "usage: 就不告诉你,就不告诉你"
            ;;
        --)
            break
            ;;
        *)
            echo "please input true arg"
            ;;
        esac
            shift
    done
fi

#source /home/sean/work/myself_tool/update_template.sh
