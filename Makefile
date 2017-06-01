prefix := ${HOME}/usr/local
bin_dir := ${prefix}/bin

.PHONY: all install uninstall

all:

install:
	mkdir -p ${bin_dir}
	cp -a frame.bash ${bin_dir}
	sed "s/^VERSION=.*/VERSION=\"$(shell git describe --dirty)\"/" frame.bash >${bin_dir}/frame
	chmod 755 ${bin_dir}/frame

uninstall:
	rm -f ${bin_dir}/frame.bash
	rmdir ${bin_dir} >/dev/null 2>&1 || true
