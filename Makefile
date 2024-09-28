MOD_NAME = fq-core
MOD_VERSION != jq -r .version $(MOD_NAME)/info.json
FACTORIO_FOLDER = ~/GOG\ Games/Factorio

MOD_PACKAGE_NAME = $(MOD_NAME)_$(MOD_VERSION).zip
MOD_PACKAGE_PATH = $(FACTORIO_FOLDER)/game/mods/$(MOD_PACKAGE_NAME)
MOD_SYMLINK_PATH = $(FACTORIO_FOLDER)/game/mods/$(MOD_NAME)

package: clean
	zip -r $(MOD_PACKAGE_NAME) $(MOD_NAME) LICENSE

clean:
	rm -f $(MOD_PACKAGE_NAME)

link: uninstall
	ln -s $(realpath $(MOD_NAME)) $(MOD_SYMLINK_PATH)

unlink:
	[ -L $(MOD_SYMLINK_PATH) ] && rm $(MOD_SYMLINK_PATH) || true

install: package unlink
	cp $(MOD_PACKAGE_NAME) $(MOD_PACKAGE_PATH)

uninstall:
	rm -f $(MOD_PACKAGE_PATH)

run:
	$(FACTORIO_FOLDER)/start.sh