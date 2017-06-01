#!/usr/bin/make -f
# vim: foldmethod=marker

# script metadata and includes  {{{1
makefile := $(abspath $(lastword ${MAKEFILE_LIST}))
srcdir := $(patsubst %/,%,$(dir ${makefile}))
builddir := ${CURDIR}

# customize to your liking  {{{1
DESTDIR :=
prefix := ${HOME}/usr/local
binprefix :=
exec_prefix := ${prefix}
bindir := ${exec_prefix}/bin
# end customize

# advanced customize to your liking  {{{1
RM := rm
RMFLAGS := -f
RMRFLAGS := -rf
RMDIR := rmdir
RMDIRFLAGS := -p
SED := sed
SEDFLAGS :=
INSTALL := install
INSTALLFLAGS := -c
INSTALL_PROGRAM := ${INSTALL}
INSTALL_PROGRAM_FLAGS := -c
INSTALL_DIRECTORIES := ${INSTALL}
INSTALL_DIRECTORIES_FLAGS :=

version = $(patsubst v%,%,$(call release_name))
distribution_head_tree = $(filter-out .git%,$(call head_tree))
release_name = $(shell git -C ${srcdir} --no-pager describe --always --dirty)
head_tree = $(shell git -C ${srcdir} ls-tree -r --name-only HEAD)
# end advanced customize

# helper functions and data  {{{1
ALL_SEDFLAGS := ${SEDFLAGS} -E -e
ALL_INSTALL_PROGRAM_FLAGS := ${INSTALL_PROGRAM_FLAGS} -m 755
ALL_INSTALL_DIRECTORIES_FLAGS := ${INSTALL_DIRECTORIES_FLAGS} -d -m 755

# source listing  {{{1
SRC_BIN_DIRECTORY := ${srcdir}/bin
SRC_FRAME_BINARY := ${SRC_BIN_DIRECTORY}/frame.bash
SRC := ${SRC_FRAME_BINARY}
SRC_BINARIES := $(filter ${SRC_BIN_DIRECTORY}/%,${SRC})
OUT_FRAME_BINARY := $(patsubst ${srcdir}/%,${builddir}/%,$(basename ${srcdir}/$(notdir ${SRC_FRAME_BINARY})))

# interface targets  {{{1
.PHONY: all install clean distclean dist distclean-files install-files installdirs

all: ${OUT_FRAME_BINARY}

clean:
	${RM} ${RMRFLAGS} ${OUT_FRAME_BINARY}

distclean: distclean-files

install: install-files

dist:
	git -C ${srcdir} archive --prefix=frame-$(call release_name)/ HEAD $(call distribution_head_tree) |xz >${srcdir}/frame-$(call release_name).tar.xz

# helper targets  {{{1
${OUT_FRAME_BINARY}: ${SRC_FRAME_BINARY}
	${SED} ${ALL_SEDFLAGS} "s/^VERSION=.*/VERSION=\"$(call version)\"/" $< >$@

distclean-files: clean

installdirs:
	${INSTALL_DIRECTORIES} ${ALL_INSTALL_DIRECTORIES_FLAGS} ${DESTDIR}${bindir}

install-files: all installdirs
	${INSTALL_PROGRAM} ${ALL_INSTALL_PROGRAM_FLAGS} ${OUT_FRAME_BINARY} ${DESTDIR}${bindir}/${binprefix}$(notdir ${OUT_FRAME_BINARY})
