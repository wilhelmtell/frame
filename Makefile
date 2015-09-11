PREFIX ?= ${HOME}/usr/local/stow/$(notdir ${CURDIR})
BIN_DIR ?= ${PREFIX}/bin

SRC := frame frame.bash

.PHONY: all install uninstall

all:

install:
	mkdir -p ${BIN_DIR}
	cp -a ${SRC} ${BIN_DIR}
	sed "s/^VERSION=.*/VERSION=\"$(shell git describe --dirty)\"/" frame.bash >${BIN_DIR}/frame.bash

uninstall:
	rm -f $(foreach s,${SRC},${BIN_DIR}/$s)
	rmdir ${BIN_DIR} >/dev/null 2>&1 || true
