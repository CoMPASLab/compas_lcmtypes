##############################################################################
# Copyright 2023  Monterey Bay Aquarium Research Institute                   #
# Monterey Bay Aquarium Research Institute Proprietary Information.          #
# All rights reserved.                                                       #
##############################################################################

GIT_SHA = $(shell git rev-parse HEAD)

# files and directories
NAVLCM_PACKAGE =	navlcm
SENLCM_PACKAGE =	senlcm
GEOMETRY_PACKAGE =	geolcm
STANDARD_PACKAGE =	stdlcm

BUILD_DIR = 	build/$(GIT_SHA)
JAVA_DIR = 		$(BUILD_DIR)/java
JAR_FILE = 		$(JAVA_DIR)/lcmtypes_compas.jar
PYTHON_DIR = 	$(BUILD_DIR)/python

LCM_JAR = 		/usr/local/share/java/lcm.jar
INSTALL_DIR =	/usr/local/share/java/

# tools

#rules
all: java python

.PHONY: java
java:
	lcm-gen -j *.lcm --jpath $(JAVA_DIR)
	javac -cp $(LCM_JAR) \
			  $(JAVA_DIR)/$(NAVLCM_PACKAGE)/*.java \
			  $(JAVA_DIR)/$(SENLCM_PACKAGE)/*.java \
			  $(JAVA_DIR)/$(GEOMETRY_PACKAGE)/*.java \
			  $(JAVA_DIR)/$(STANDARD_PACKAGE)/*.java

	jar cf $(JAR_FILE) *.lcm \
		   $(JAVA_DIR)/$(NAVLCM_PACKAGE)/*.class \
		   $(JAVA_DIR)/$(SENLCM_PACKAGE)/*.class \
		   $(JAVA_DIR)/$(GEOMETRY_PACKAGE)/*.class \
		   $(JAVA_DIR)/$(STANDARD_PACKAGE)/*.class

.PHONY: python
python:
	lcm-gen -p *.lcm --ppath $(PYTHON_DIR) --package-prefix compas_lcmtypes
	cat pyproject.toml.in | sed "s/VERSION/$(GIT_SHA)/" > $(PYTHON_DIR)/pyproject.toml
	cd $(PYTHON_DIR) && poetry build -n --no-cache

.PHONY: install
install:
	sudo cp -i $(JAR_FILE) $(INSTALL_DIR)
	pip install $(PYTHON_DIR)/dist/compas_lcmtypes-0.1.0+$(GIT_SHA)-py3-none-any.whl

.PHONY: clean
clean:
	rm -rf build


