#!/bin/bash
mac=$(printf '52:54:00:AB:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)))
name=${1}
nomad job dispatch -meta mac=${mac} -meta name=${name} -meta image_size="60G" ubuntu-amd64-lanecloud-cloud
