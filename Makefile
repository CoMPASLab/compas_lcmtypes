##############################################################################
# Copyright 2023  Monterey Bay Aquarium Research Institute                   #
# Monterey Bay Aquarium Research Institute Proprietary Information.          #
# All rights reserved.                                                       #
##############################################################################

# files and directories
LCM_SRC_DIR = .
BUILD_DIR = build
BUILD_JAVA = $(BUILD_DIR)/java
BUILD_CPP = $(BUILD_DIR)/cpp
BUILD_PYTHON = $(BUILD_DIR)/python
COMPAS_HEADER_DIR = /usr/local/share/compas/include
COMPAS_JAR_DIR = /usr/local/share/java
COMPAS_JAR = lcmtypes_compas.jar
LCM_JAR = /usr/local/share/java/lcm.jar

# use make install OVERWRITE=1
# for non-interactive install
ifeq ($(OVERWRITE),1)
OPT_OVWR =
else
OPT_OVWR = -i
endif

# Compas LCM packages
NAVLCM_PACKAGE = navlcm
SENLCM_PACKAGE = senlcm
GEOMETRY_PACKAGE = geometry
STANDARD_PACKAGE = standard

# Compas LCM sources
LCM_SRC = \
$(LCM_SRC_DIR)/$(NAVLCM_PACKAGE)*lcm \
$(LCM_SRC_DIR)/$(SENLCM_PACKAGE)*lcm \
$(LCM_SRC_DIR)/$(GEOMETRY_PACKAGE)*lcm \
$(LCM_SRC_DIR)/$(STANDARD_PACKAGE)*lcm

# Compas Java sources
JAVA_SRC = \
 $(BUILD_JAVA)/$(NAVLCM_PACKAGE)/*.java \
 $(BUILD_JAVA)/$(SENLCM_PACKAGE)/*.java \
 $(BUILD_JAVA)/$(GEOMETRY_PACKAGE)/*.java \
 $(BUILD_JAVA)/$(STANDARD_PACKAGE)/*.java

# tools

# rules
all: build_dirs jar_file lcm_headers lcm_python

.PHONY: install_dirs jar_file lcm_headers

# create missing build directories
build_dirs:
	@ echo checking build directories
	@[ -d $(BUILD_DIR) ] || mkdir -p $(BUILD_DIR)
	@[ -d $(BUILD_CPP) ] || mkdir -p $(BUILD_CPP)
	@[ -d $(BUILD_JAVA) ] || mkdir -p $(BUILD_JAVA)
	@[ -d $(BUILD_PYTHON) ] || mkdir -p $(BUILD_PYTHON)

# creating missing install directories
install_dirs:
	@ echo checking install directories
	@[ -d $(COMPAS_HEADER_DIR) ] || mkdir -p $(COMPAS_HEADER_DIR)

# generate Compas LCM jar
jar_file:
	@ echo generating lcm java...
	lcm-gen -j --jpath=$(BUILD_JAVA) $(LCM_SRC)
	@ echo compiling java source...
	javac -cp $(LCM_JAR) $(JAVA_SRC)
	@ echo generating jar file
	jar cvf $(BUILD_DIR)/$(COMPAS_JAR) $(LCM_SRC) -C $(BUILD_JAVA) .

# generate Compas LCM python
lcm_python:
	@ echo generating lcm python
	lcm-gen -p --ppath=$(BUILD_PYTHON) $(LCM_SRC)

# generate Compas

# install jar and headers
.PHONY: install uninstall
install: install_dirs
	sudo cp $(OPT_OVWR) $(BUILD_DIR)/$(COMPAS_JAR) $(COMPAS_JAR_DIR)
	sudo cp $(OPT_OVWR) -r $(BUILD_CPP)/* $(COMPAS_HEADER_DIR)/.

# uninstall jar and headers
uninstall:
	sudo rm $(COMPAS_JAR_DIR)/$(COMPAS_JAR)
	sudo rm -rf $(COMPAS_HEADER_DIR)/$(NAVLCM_PACKAGE)
	sudo rm -rf $(COMPAS_HEADER_DIR)/$(SENLCM_PACKAGE)
	sudo rm -rf $(COMPAS_HEADER_DIR)/$(GEOMETRY_PACKAGE)
	sudo rm -rf $(COMPAS_HEADER_DIR)/$(STANDARD_PACKAGE)

# clean build products
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/$(COMPAS_JAR)
	rm -rf $(BUILD_JAVA)
	rm -rf $(BUILD_CPP)
	rm -rf $(BUILD_PYTHON)

