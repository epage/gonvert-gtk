PROJECT_NAME=gonvert-gtk
SOURCE_PATH=src
SOURCE=$(shell find $(SOURCE_PATH) -iname "*.py")
PROGRAM=$(SOURCE_PATH)/$(PROJECT_NAME).py
DATA_PATH=data
DATA_TYPES=*.ini *.map *.glade *.png
DATA=$(foreach type, $(DATA_TYPES), $(shell find $(DATA_PATH) -iname "$(type)"))
OBJ=$(SOURCE:.py=.pyc)
BUILD_PATH=./build
TAG_FILE=~/.ctags/$(PROJECT_NAME).tags
TODO_FILE=./TODO

DEBUGGER=winpdb
UNIT_TEST=nosetests --with-doctest -w .
SYNTAX_TEST=support/test_syntax.py
STYLE_TEST=../../Python/tools/pep8.py --ignore=W191,E501
LINT_RC=./support/pylint.rc
LINT=pylint --rcfile=$(LINT_RC)
PROFILE_GEN=python -m cProfile -o .profile
PROFILE_VIEW=python -m pstats .profile
TODO_FINDER=support/todo.py
CTAGS=ctags-exuberant

.PHONY: all run profile debug test build lint tags todo clean distclean

all: test

run: $(OBJ)
	$(SOURCE_PATH)/gonvert_glade.py

profile: $(OBJ)
	$(PROFILE_GEN) $(PROGRAM)
	$(PROFILE_VIEW)

debug: $(OBJ)
	$(DEBUGGER) $(PROGRAM)

test: $(OBJ)
	$(UNIT_TEST)

package: $(OBJ)
	rm -Rf $(BUILD_PATH)

	mkdir -p $(BUILD_PATH)/generic
	cp $(SOURCE_PATH)/constants.py  $(BUILD_PATH)/generic
	cp $(SOURCE_PATH)/$(PROJECT_NAME).py  $(BUILD_PATH)/generic
	$(foreach file, $(DATA), cp $(file) $(BUILD_PATH)/generic/$(subst /,-,$(file)) ; )
	$(foreach file, $(SOURCE), cp $(file) $(BUILD_PATH)/generic/$(subst /,-,$(file)) ; )
	#$(foreach file, $(OBJ), cp $(file) $(BUILD_PATH)/generic/$(subst /,-,$(file)) ; )
	cp support/gonvert.desktop $(BUILD_PATH)/generic
	cp support/builddeb.py $(BUILD_PATH)/generic
	cp support/py2deb.py $(BUILD_PATH)/generic

	mkdir -p $(BUILD_PATH)/diablo
	cp -R $(BUILD_PATH)/generic/* $(BUILD_PATH)/diablo
	cd $(BUILD_PATH)/diablo ; python builddeb.py diablo
	mkdir -p $(BUILD_PATH)/fremantle
	cp -R $(BUILD_PATH)/generic/* $(BUILD_PATH)/fremantle
	cd $(BUILD_PATH)/fremantle ; python builddeb.py fremantle
	mkdir -p $(BUILD_PATH)/debian
	cp -R $(BUILD_PATH)/generic/* $(BUILD_PATH)/debian
	cd $(BUILD_PATH)/debian ; python builddeb.py debian

upload:
	dput fremantle-extras-builder $(BUILD_PATH)/fremantle/$(PROJECT_NAME)*.changes
	dput diablo-extras-builder $(BUILD_PATH)/diablo/$(PROJECT_NAME)*.changes
	cp $(BUILD_PATH)/debian/*.deb www/$(PROJECT_NAME).deb

lint: $(OBJ)
	$(foreach file, $(SOURCE), $(LINT) $(file) ; )

tags: $(TAG_FILE) 

todo: $(TODO_FILE)

clean:
	rm -Rf $(OBJ)
	rm -Rf $(BUILD_PATH)
	rm -Rf $(TODO_FILE)

distclean:
	rm -Rf $(OBJ)
	rm -Rf $(BUILD_PATH)
	rm -Rf $(TAG_FILE)
	find $(SOURCE_PATH) -name "*.*~" | xargs rm -f
	find $(SOURCE_PATH) -name "*.swp" | xargs rm -f
	find $(SOURCE_PATH) -name "*.bak" | xargs rm -f
	find $(SOURCE_PATH) -name ".*.swp" | xargs rm -f

$(TAG_FILE): $(OBJ)
	mkdir -p $(dir $(TAG_FILE))
	$(CTAGS) -o $(TAG_FILE) $(SOURCE)

$(TODO_FILE): $(SOURCE)
	@- $(TODO_FINDER) $(SOURCE) > $(TODO_FILE)

%.pyc: %.py
	#$(SYNTAX_TEST) $<

#Makefile Debugging
#Target to print any variable, can be added to the dependencies of any other target
#Userfule flags for make, -d, -p, -n
print-%: ; @$(error $* is $($*) ($(value $*)) (from $(origin $*)))
