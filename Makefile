PREFIX ?= ${HOME}/usr/local/stow/$(notdir ${CURDIR})
BIN_DIR ?= ${PREFIX}/bin

.PHONY: all install uninstall

all:

install:
	mkdir -p ${BIN_DIR}
	cp -a frame.bash ${BIN_DIR}
	sed "s/^VERSION=.*/VERSION=\"$(shell git describe --dirty)\"/" frame.bash >${BIN_DIR}/frame

uninstall:
	rm -f ${BIN_DIR}/frame.bash
	rmdir ${BIN_DIR} >/dev/null 2>&1 || true
