BUILD_VERSION?="$(shell git for-each-ref --sort=-v:refname --count=1 --format '%(refname)'  | cut -d '/' -f3)"
OUTDIR="crowdsec-openresty-bouncer-${BUILD_VERSION}/"
OUT_ARCHIVE="crowdsec-openresty-bouncer.tgz"
default: release
release:
	mkdir "${OUTDIR}"
	cp -r ./lua/ "${OUTDIR}"
	cp -r ./config/ ${OUTDIR}
	cp -r ./openresty/ ${OUTDIR}
	cp install.sh ${OUTDIR}
	cp uninstall.sh ${OUTDIR}
	tar cvzf ${OUT_ARCHIVE} ${OUTDIR}
	rm -rf ${OUTDIR}
clean:
	rm -rf "${OUTDIR}"
	rm -rf "${OUT_ARCHIVE}"