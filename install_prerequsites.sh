#!/bin/bash

wx_widget_version="tags/v3.0.4"

# Commands
check_for_error(){
	RED='\033[0;31m'
	NC='\033[0m'
	if [ $1 -ne "0" ]; then
		echo -e "${RED}Error $2. ${NC}\n"
		exit 1;
	fi
}
install_tools(){
	sudo apt-get install gcc g++ build-essential cmake git doxygen swig
	check_for_error $? "Failed to install tools"
}

update_git_submodules(){
	git submodule init
	check_for_error $? "Submodule init"
	git submodule update
	check_for_error $? "Submodule update"
	sudo apt autoremove
	check_for_error $? "apt-get autoremove "
	echo "TESTTTTTTTTTTT"
}
# Libraries

# GUI library
install_wx_widget_library(){
	cd wxWidgets/
	git checkout $wx_widget_version 
	check_for_error $? "004"
	../configure --enable-unicode --enable-debug
	check_for_error $? "005"
	make -j12
	check_for_error $? "006"
	make install
	check_for_error $? "007"
	cd -
}

main(){
	install_tools
	update_git_submodules
	#install_wx_widget_library 
}

main
