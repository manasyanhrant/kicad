#!/bin/bash

PWD=`pwd`
export_file="/etc/environment"
#export_file="~/.bashrc"

append_variables(){
	if [ $# -eq 2 ]; then
		if ! grep $1 $export_file ; then
		    echo "$1=$2" | sudo tee -a $export_file
        else
            echo "Warning: Variable $1 already exported"
        fi
    else
        echo "Error: Function should receive two arguments [var_name] [path]"
        exit 1
	fi	
}

main(){
    append_variables KICAD_PTEMPLATES "$PWD/kicad-templates"
    append_variables KICAD_SYMBOL_DIR "$PWD/kicad-symbols"
    append_variables KISYS3DMOD "$PWD/kicad-packages3D"
    append_variables KISYSMOD "$PWD/kicad-kicad-footprints"
}

main
