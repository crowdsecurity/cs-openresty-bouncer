BUILD_VERSION?="$(shell git for-each-ref --sort=-v:refname --count=1 --format '%(refname)'  | cut -d '/' -f3)"
OUTDIR="crowdsec-openresty-bouncer-${BUILD_VERSION}/"
LUA_DIR="${OUTDIR}lua"
CONFIG_DIR="${OUTDIR}config"
OUT_ARCHIVE="crowdsec-openresty-bouncer.tgz"
LUA_BOUNCER_BRANCH?=main
default: release
release:
	git clone -b ${LUA_BOUNCER_BRANCH} https://github.com/crowdsecurity/lua-cs-bouncer.git
	mkdir -p "${OUTDIR}"
	mkdir -p "${LUA_DIR}"
	mkdir -p "${CONFIG_DIR}"
	cp -r lua-cs-bouncer/nginx/*.lua "${LUA_DIR}"
	cp -r lua-cs-bouncer/nginx/template.conf ${CONFIG_DIR}
	cp -r ./openresty/ ${OUTDIR}
	cp install.sh ${OUTDIR}
	cp uninstall.sh ${OUTDIR}
	chmod +x ${OUTDIR}install.sh
	chmod +x ${OUTDIR}uninstall.sh
	tar cvzf ${OUT_ARCHIVE} ${OUTDIR}
	rm -rf ${OUTDIR}
	rm -rf "lua-cs-bouncer/"
clean:
	rm -rf "${OUTDIR}"
	rm -rf "${OUT_ARCHIVE}"