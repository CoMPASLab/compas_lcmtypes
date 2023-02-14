##############################################################################
# Copyright 2023  Monterey Bay Aquarium Research Institute                   #
# Monterey Bay Aquarium Research Institute Proprietary Information.          #
# All rights reserved.                                                       #
##############################################################################

# files and directories
JAR_FILE = 			lcmtypes_compas.jar
NAVLCM_PACKAGE =	navlcm
SENLCM_PACKAGE =	senlcm
GEOMETRY_PACKAGE =	geometry
STANDARD_PACKAGE =	standard

LCM_JAR = 		/usr/local/share/java/lcm.jar
INSTALL_DIR =	/usr/local/share/java/

# tools

#rules
all: jar_file

.PHONY: jar_file
jar_file:
	lcm-gen -j *.lcm
	javac -cp $(LCM_JAR) \
			  $(NAVLCM_PACKAGE)/*.java \
			  $(SENLCM_PACKAGE)/*.java \
			  $(GEOMETRY_PACKAGE)/*.java \
			  $(STANDARD_PACKAGE)/*.java

	jar cf $(JAR_FILE) \
		   $(NAVLCM_PACKAGE)/*.class \
		   $(SENLCM_PACKAGE)/*.class \
		   $(GEOMETRY_PACKAGE)/*.class \
		   $(STANDARD_PACKAGE)/*.class

.PHONY: install
install:
	sudo cp -i $(JAR_FILE) $(INSTALL_DIR)

.PHONY: clean
clean:
	rm -rf $(JAR_FILE) \
		   $(NAVLCM_PACKAGE) \
		   $(SENLCM_PACKAGE) \
		   $(GEOMETRY_PACKAGE) \
		   $(STANDARD_PACKAGE)


