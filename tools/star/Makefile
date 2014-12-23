RAKUDO_VER  = 2014.12
NQP_VER     = 2014.12
PARROT_VER  = 6.10.0
MOAR_VER    = 2014.12

STAR_REL    = rakudo-star-$(VERSION)
STAR_TGZ    = $(STAR_REL).tar.gz

SRC_DIR = src

RAKUDO_TGZ = rakudo-$(RAKUDO_VER).tar.gz
RAKUDO_URL = http://rakudo.org/downloads/rakudo/$(RAKUDO_TGZ)
RAKUDO_SRC = $(SRC_DIR)/$(RAKUDO_TGZ)
NQP_TGZ    = nqp-$(NQP_VER).tar.gz
NQP_URL    = http://rakudo.org/downloads/nqp/$(NQP_TGZ)
NQP_SRC    = $(SRC_DIR)/$(NQP_TGZ)
PARROT_TGZ = parrot-$(PARROT_VER).tar.gz
PARROT_URL = http://ftp.parrot.org/releases/all/$(PARROT_VER)/$(PARROT_TGZ)
PARROT_SRC = $(SRC_DIR)/$(PARROT_TGZ)
MOAR_TGZ   = MoarVM-$(MOAR_VER).tar.gz
MOAR_URL   = http://www.moarvm.org/releases/$(MOAR_TGZ)
MOAR_SRC   = $(SRC_DIR)/$(MOAR_TGZ)

PERL   = perl
PREFIX = $(PERL) $(CURDIR)/tools/star/prefix.pl
WGET   = wget --no-check-certificate

all: rakudo nqp parrot moar manifest

always:

rakudo: nqp $(RAKUDO_SRC)
	tar --xform 's!rakudo-[^/]*!rakudo!' -xvzf $(RAKUDO_SRC)

$(RAKUDO_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(RAKUDO_URL) -O $(RAKUDO_SRC)

nqp: parrot moar $(NQP_SRC)
	tar --xform 's!nqp-[^/]*!nqp!' -xvzf $(NQP_SRC)

$(NQP_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(NQP_URL) -O $(NQP_SRC)

parrot: $(PARROT_SRC)
	tar --xform 's!parrot-[^/]*!parrot!' -xvzf $(PARROT_SRC)

$(PARROT_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(PARROT_URL) -O $(PARROT_SRC)

moar: $(MOAR_SRC)
	tar --xform 's!MoarVM-[^/]*!MoarVM!' -xvzf $(MOAR_SRC)

$(MOAR_SRC):
	mkdir -p $(SRC_DIR)
	$(WGET) $(MOAR_URL) -O $(MOAR_SRC)

modules/zavolaj/lib:
	@echo "Updating submodules"
	git submodule init
	git submodule update

manifest: modules/zavolaj/lib
	echo MANIFEST >MANIFEST
	git ls-files >>MANIFEST
	$(PREFIX) rakudo/ rakudo/MANIFEST >>MANIFEST
	$(PREFIX) nqp/ nqp/MANIFEST >>MANIFEST
	$(PREFIX) MoarVM/ MoarVM/MANIFEST >>MANIFEST
	cut -d' ' -f1 parrot/MANIFEST | $(PREFIX) parrot/ >>MANIFEST
	git submodule foreach --quiet 'git ls-files | $(PREFIX) $$path/' >>MANIFEST
	grep -v -f tools/star/MANIFEST.exclude MANIFEST >MANIFEST.1
	$(PERL) -n -e 'chomp; -f && print "$$_\n"' MANIFEST.1 >MANIFEST
	perl6 tools/build/panda-state.p6 >>MANIFEST
	sort -o MANIFEST MANIFEST
	rm MANIFEST.1

tarball: manifest
	[ -n "$(VERSION)" ] || ( echo "\nTry '$(MAKE) release VERSION=yyyy.mm'\n\n"; exit 1 )
	[ -d $(STAR_REL) ] || ln -s . $(STAR_REL)
	$(PREFIX) $(STAR_REL)/ MANIFEST | \
	    tar -zcv -T - -f $(STAR_TGZ)
	rm $(STAR_REL)

release: tarball
