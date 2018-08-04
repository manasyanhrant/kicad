#!/bin/bash

wx_widget_version="v3.0.4"
cores=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l `

# Commands
check_for_error(){
	RED='\033[0;31m'
	NC='\033[0m'
	if [ $1 -ne "0" ]; then
		echo -e "${RED}Error $2. ${NC}\n"
		exit 1;
	fi
}

install_ngspice(){
	if ! dpkg -s ngspice >> /dev/null; then	
		url="http://de.archive.ubuntu.com/ubuntu/pool/multiverse/n/ngspice/ngspice_27-1_amd64.deb"
		wget $url -P /tmp
		check_for_error $? "Getting ngspice failed"
		sudo dpkg -i /tmp/ngspice_27-1_amd64.deb
		check_for_error $? "Installing ngspice failed"
		cd ./kicad/scripts
		chmod +x get_libngspice_so.sh
		check_for_error $? "Chanding +x ngspice failed"
		./get_libngspice_so.sh
		check_for_error $? "Failed to get ngspice shared lib"
		sudo ./get_libngspice_so.sh install
		check_for_error $? "Failed to install ngspice shared lib"
		cd -
	fi
}

# SWIG is used to generate the Python scripting language extensions for KiCad
install_swig(){
	if ! dpkg -s swig >> /dev/null; then	
		git clone https://github.com/swig/swig.git /tmp
		check_for_error $? "Getting swig failed"
		cd /tmp/swig
		./autogen.sh && ./configure && make "-j$cores"
		check_for_error $? "Installing swig failed"
		cd -
	fi
}

install_python_wxgtk2(){
	sudo add-apt-repository ppa:nilarimogard/webupd8
	check_for_error $? "Failed to add wxgtk2 repo"
	sudo apt-get update 
	check_for_error $? "Failed to update wxgtk2 repo "
	sudo apt-get install python-wxgtk2.8
	check_for_error $? "Failed to install wxgtk2 "
}

install_tools(){
	packages=" gcc g++ build-essential cmake git doxygen flex "
	packages+=" libgtk2.0-dev libgtk-3-dev " # Needed for wxWidget
	packages+=" libpcre3-dev libtool bison " # Needed for swig
	packages+=" libglm-dev " # The OpenGL Mathematics Library is an
							# OpenGL helper library used by the KiCad 
							# graphics abstraction library
							# [GAL] and is always required to build KiCad.
	packages+=" libglew-dev " # The OpenGL Extension Wrangler is an
							 # OpenGL helper library used by the KiCad 
							 # graphics abstraction library
							 # [GAL] and is always required to build KiCad.
	packages+=" freeglut3-dev " # Helper of glew
	packages+=" libcairo2-dev " # 2D graphic library for rendering
							   # canvas when OpenGL is not available
	packages+=" python python3 python-dev " 
	# gtk3 (wxgtk3.0) has some issues for the moment 01/08/2018
	packages+=" python python3 python-dev python-wxgtk3.0* " 
	packages+=" libcurl3 libcurlpp-dev " # For secure git file transfer
	packages+=" liboce-foundation-dev liboce-modeling-dev liboce-ocaf-dev liboce-visualization-dev " 
	packages+=" libboost-all-dev libbz2-dev libssl-dev " # Other
	packages+="libgit2-dev transfig imagemagick " # For eeshow (Tool)
	# Not needed for my case. I built this libraries myself
	packages+=" libwxgtk3.0-0v5 libwxgtk3.0 " 
	sudo apt-get -y install $packages
	check_for_error $? "Failed to install tools"
	#sudo pip install wxPython #--upgrade
	check_for_error $? "Failed to install wxPython"
	#install_python_wxgtk2
	install_ngspice
	install_swig
	sudo apt autoremove
	check_for_error $? "apt-get autoremove "
}

update_git_submodules(){
	git submodule init
	check_for_error $? "Submodule init"
	git submodule update -f
	check_for_error $? "Submodule Update"
}
# Libraries

# GUI library
install_wx_widget_library(){
	cd wxWidgets/
	git checkout  "tags/$wx_widget_version"
	# TODO: Gives error when running second time after first
	# succesfull run
	#check_for_error $? "git checkout wxWidgets"
	if [ ! -f './Makefile' ]; then
			./configure --enable-unicode --with-opengl --with-gtk=2
			check_for_error $? "Configuring wxWidgets"
	fi
	make "-j$cores"
	check_for_error $? "make wxWidgets"
	sudo make install
	check_for_error $? "make install wxWidgets"
	cd -
}

# Build KiCad
build_kicad(){
		cd kicad
		mkdir -p build/
		cd build
		# -DKICAD_SCRIPTING_WXPYTHON=ON
		cmake -DCMAKE_BUILD_TYPE=Release -DKICAD_SCRIPTING_WXPYTHON=OFF \
		-DKICAD_SCRIPTING=ON  -DKICAD_SCRIPTING_MODULES=ON \
		-DKICAD_SCRIPTING_ACTION_MENU=ON  -DKICAD_INSTALL_DEMOS=ON \
		-DKICAD_USE_OCE=ON -DKICAD_SPICE=ON ../
		check_for_error $? "Configuring kicad"
		make "-j$cores"
		check_for_error $? "Building kicad"
		sudo make install
		check_for_error $? "Installing kicad"
		cd ../../
}

main(){
	install_tools
	update_git_submodules
	#install_wx_widget_library
	build_kicad
}

main
