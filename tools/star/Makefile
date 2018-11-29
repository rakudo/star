# Usually these exist as tarballs existing on the FTP site(s)
# eg. 2017.07 etc.
# Occasionally (mis-)used to pull in fixes (see 'lastmin-fixes.txt')
# eg. 2017.07-9-gc0abee7 etc.
RAKUDO_VER  = 2018.10
NQP_VER     = 2018.10
MOAR_VER    = 2018.10

STAR_REL    = rakudo-star-$(VERSION)
STAR_TGZ    = $(STAR_REL).tar.gz

SRC_DIR = src

RAKUDO_TGZ = rakudo-$(RAKUDO_VER).tar.gz
RAKUDO_URL = https://rakudo.perl6.org/downloads/rakudo/$(RAKUDO_TGZ)
RAKUDO_SRC = $(SRC_DIR)/$(RAKUDO_TGZ)
NQP_TGZ    = nqp-$(NQP_VER).tar.gz
NQP_URL    = https://rakudo.perl6.org/downloads/nqp/$(NQP_TGZ)
NQP_SRC    = $(SRC_DIR)/$(NQP_TGZ)
MOAR_TGZ   = MoarVM-$(MOAR_VER).tar.gz
MOAR_URL   = https://www.moarvm.org/releases/$(MOAR_TGZ)
MOAR_SRC   = $(SRC_DIR)/$(MOAR_TGZ)

PERL   = perl
PREFIX = $(PERL) $(CURDIR)/tools/star/prefix.pl
WGET   = wget
TAR    = tar

all: rakudo nqp moar manifest

always:

rakudo: nqp $(RAKUDO_SRC)
	mkdir rakudo
	$(TAR) -C rakudo --strip-components 1 -xvzf $(RAKUDO_SRC)

$(RAKUDO_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(RAKUDO_URL) -O $(RAKUDO_SRC)

nqp: moar $(NQP_SRC)
	mkdir nqp
	$(TAR) -C nqp --strip-components 1 -xvzf $(NQP_SRC)

$(NQP_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(NQP_URL) -O $(NQP_SRC)

moar: $(MOAR_SRC)
	mkdir MoarVM
	$(TAR) -C MoarVM --strip-components 1 -xvzf $(MOAR_SRC)

$(MOAR_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(MOAR_URL) -O $(MOAR_SRC)

modules/DBIish/lib:
	@echo "Updating submodules"
	git submodule init
	git submodule update

manifest: modules/DBIish/lib
	echo MANIFEST >MANIFEST
	git ls-files >>MANIFEST
	$(PREFIX) rakudo/ rakudo/MANIFEST >>MANIFEST
	$(PREFIX) nqp/ nqp/MANIFEST >>MANIFEST
	$(PREFIX) MoarVM/ MoarVM/MANIFEST >>MANIFEST
	git submodule foreach --quiet 'git ls-files | $(PREFIX) $$path/' >>MANIFEST
	grep -v -f tools/star/MANIFEST.exclude MANIFEST >MANIFEST.1
	$(PERL) -n -e 'chomp; -f && print "$$_\n"' MANIFEST.1 >MANIFEST
	sort -o MANIFEST MANIFEST
	rm MANIFEST.1

patch:
	patch -p1 < patches/star-ver.patch

tarball: manifest patch
	[ -n "$(VERSION)" ] || ( echo "\nTry '$(MAKE) release VERSION=yyyy.mm'\n\n"; exit 1 )
	[ -d $(STAR_REL) ] || ln -s . $(STAR_REL)
	$(PREFIX) $(STAR_REL)/ MANIFEST | \
	    $(TAR) -zcv -T - -f $(STAR_TGZ)
	rm $(STAR_REL)

release: tarball
