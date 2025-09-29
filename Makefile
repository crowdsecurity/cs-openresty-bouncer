BUILD_VERSION?="$(shell git for-each-ref --sort=-v:refname --count=1 --format '%(refname)'  | cut -d '/' -f3)"
OUTDIR="crowdsec-openresty-bouncer-${BUILD_VERSION}/"
LUA_DIR="${OUTDIR}lua"
CONFIG_DIR="${OUTDIR}config"
TEMPLATE_DIR="${OUTDIR}templates"
OUT_ARCHIVE="crowdsec-openresty-bouncer.tgz"
LUA_BOUNCER_BRANCH?=v1.0.11
default: release
release:
	git clone -b "${LUA_BOUNCER_BRANCH}" https://github.com/crowdsecurity/lua-cs-bouncer.git
	mkdir -p "${OUTDIR}"
	mkdir -p "${LUA_DIR}"
	mkdir -p "${CONFIG_DIR}"
	mkdir -p "${TEMPLATE_DIR}"
	cp -r lua-cs-bouncer/lib "${LUA_DIR}"
	cp lua-cs-bouncer/templates/* "${TEMPLATE_DIR}"
	cp -r lua-cs-bouncer/config_example.conf ${CONFIG_DIR}
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
