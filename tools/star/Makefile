# Usually these exist as tarballs existing on the FTP site(s)
# eg. 2017.07 etc.
# Occasionally (mis-)used to pull in fixes (see 'lastmin-fixes.txt')
# eg. 2017.07-9-gc0abee7 etc.
RAKUDO_VER  = 2019.07.1
NQP_VER     = 2019.07.1
MOAR_VER    = 2019.07.1

STAR_REL    = rakudo-star-$(VERSION)
STAR_TGZ    = $(STAR_REL).tar.gz

SRC_DIR = work/src
WORKDIR ?= $(shell pwd)/work/rakudo-star-$(VERSION)
RELEASE_DIR = $(shell pwd)/work/release

RAKUDO_TGZ = rakudo-$(RAKUDO_VER).tar.gz
RAKUDO_URL = https://rakudo.perl6.org/downloads/rakudo/$(RAKUDO_TGZ)
RAKUDO_SRC = $(SRC_DIR)/$(RAKUDO_TGZ)
NQP_TGZ    = nqp-$(NQP_VER).tar.gz
NQP_URL    = https://dist.tyil.nl/raku/nqp/$(NQP_TGZ)
NQP_SRC    = $(SRC_DIR)/$(NQP_TGZ)
MOAR_TGZ   = MoarVM-$(MOAR_VER).tar.gz
MOAR_URL   = https://www.moarvm.org/releases/$(MOAR_TGZ)
MOAR_SRC   = $(SRC_DIR)/$(MOAR_TGZ)

PERL   = perl
PREFIX = $(PERL) $(CURDIR)/tools/star/prefix.pl
WGET   = wget
TAR    = tar

all: rakudo nqp moarvm manifest

rakudo: nqp $(RAKUDO_SRC)
	mkdir -p $(WORKDIR)/rakudo
	$(TAR) -C $(WORKDIR)/rakudo --strip-components 1 -xzf $(RAKUDO_SRC)

$(RAKUDO_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(RAKUDO_URL) -O $(RAKUDO_SRC)

nqp: moarvm $(NQP_SRC)
	mkdir -p $(WORKDIR)/nqp
	$(TAR) -C $(WORKDIR)/nqp --strip-components 1 -xzf $(NQP_SRC)

$(NQP_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(NQP_URL) -O $(NQP_SRC)

moarvm: $(MOAR_SRC)
	mkdir -p $(WORKDIR)/MoarVM
	$(TAR) -C $(WORKDIR)/MoarVM --strip-components 1 -xzf $(MOAR_SRC)

$(MOAR_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(MOAR_URL) -O $(MOAR_SRC)

modules/DBIish/lib:
	@echo "Updating submodules"
	git submodule init
	git submodule update

manifest:
	printf "%s\n" MANIFEST >> "$(WORKDIR)/MANIFEST"

	# Add an assortment of files from this repository
	git ls-files | grep -E '^docs' >> "$(WORKDIR)/MANIFEST"
	git ls-files | grep -E '^modules' >> "$(WORKDIR)/MANIFEST"
	git ls-files | grep -E '^ports' >> "$(WORKDIR)/MANIFEST"
	git ls-files | grep -E '^tools' >> "$(WORKDIR)/MANIFEST"

	printf "%s\n" build_msi.bat >> "$(WORKDIR)/MANIFEST"
	printf "%s\n" Configure.pl >> "$(WORKDIR)/MANIFEST"
	printf "%s\n" LICENSE >> "$(WORKDIR)/MANIFEST"
	printf "%s\n" README.md >> "$(WORKDIR)/MANIFEST"

	# Add the 3 core parts for Raku
	cd -- "$(WORKDIR)" && $(PREFIX) rakudo/ rakudo/MANIFEST >> "$(WORKDIR)/MANIFEST"
	cd -- "$(WORKDIR)" && $(PREFIX) nqp/ nqp/MANIFEST >> "$(WORKDIR)/MANIFEST"
	cd -- "$(WORKDIR)" && $(PREFIX) MoarVM/ MoarVM/MANIFEST >> "$(WORKDIR)/MANIFEST"

	# Add ecosystem modules
	git submodule foreach --quiet 'git ls-files | $(PREFIX) $$path/' >> $(WORKDIR)/MANIFEST

	# Remove explicitly removed files
	grep -v -f tools/star/MANIFEST.exclude $(WORKDIR)/MANIFEST > $(WORKDIR)/MANIFEST.1
	mv -- "$(WORKDIR)/MANIFEST.1" "$(WORKDIR)/MANIFEST"

	# Clean up whitespace
	$(PERL) -n -e 'chomp; print "$$_\n"' $(WORKDIR)/MANIFEST > $(WORKDIR)/MANIFEST.1
	mv -- "$(WORKDIR)/MANIFEST.1" "$(WORKDIR)/MANIFEST"

	# Sort the MANIFEST
	sort -o $(WORKDIR)/MANIFEST $(WORKDIR)/MANIFEST

patch:
	patch -p1 < patches/star-ver.patch

tarball: manifest
	[ -n "$(VERSION)" ] || ( echo "\nTry '$(MAKE) release VERSION=yyyy.mm'\n\n"; exit 1 )

	mkdir -p "$(RELEASE_DIR)"
	cp -r modules "$(WORKDIR)/."
	cp -r docs "$(WORKDIR)/."
	cp -r ports "$(WORKDIR)/."
	cp -r tools "$(WORKDIR)/."
	cp LICENSE "$(WORKDIR)/."
	cp bundle/README.md "$(WORKDIR)/."
	cp bundle/build_msi.bat "$(WORKDIR)/."
	cp bundle/Configure.pl "$(WORKDIR)/."

	cd -- work && $(PREFIX) $(STAR_REL)/ "$(WORKDIR)/MANIFEST" \
		| $(TAR) -zc -T - -f "$(RELEASE_DIR)/$(STAR_TGZ)"

release: tarball

clean:
	rm -fr work
