PARROT_VER = 2.6.0
RAKUDO_TAG = master

DISTDIR = rakudo-star-$(VERSION)

PARROT     = parrot-$(PARROT_VER)
PARROT_TGZ = $(PARROT).tar.gz
PARROT_DIR = $(DISTDIR)/$(PARROT)

RAKUDO_DIR = $(DISTDIR)/rakudo
BUILD_DIR  = $(DISTDIR)/build

BUILD_FILES = \
  build/gen_parrot.pl \
  build/Makefile.in \

DISTTARGETS = \
  $(PARROT_DIR) \
  $(RAKUDO_DIR) \
  $(BUILD_DIR) \
  $(BUILD_DIR)/PARROT_REVISION \
  $(DISTDIR)/Configure.pl \
  $(DISTDIR)/MANIFEST \

$(DISTDIR): version_check $(DISTTARGETS)

$(PARROT_DIR): $(PARROT_TGZ)
	mkdir -p $(DISTDIR)
	tar -C $(DISTDIR) -xvzf $(PARROT_TGZ)
$(PARROT).tar.gz:
	wget http://ftp.parrot.org/releases/supported/$(PARROT_VER)/$(PARROT_TGZ)

$(RAKUDO_DIR):
	git clone git@github.com:rakudo/rakudo.git $(RAKUDO_DIR)
	cd $(RAKUDO_DIR); git checkout $(RAKUDO_VER)

$(BUILD_DIR): $(BUILD_FILES)
	mkdir -p $(BUILD_DIR)
	cp $(BUILD_FILES) $(BUILD_DIR)

$(BUILD_DIR)/PARROT_REVISION: $(RAKUDO_DIR) $(RAKUDO_DIR)/build/PARROT_REVISION
	cp $(RAKUDO_DIR)/build/PARROT_REVISION $(BUILD_DIR)

$(DISTDIR)/Configure.pl: build/Configure.pl
	cp build/Configure.pl $(DISTDIR)

$(DISTDIR)/MANIFEST:
	touch $(DISTDIR)/MANIFEST
	find $(DISTDIR) -name '.*' -prune -o -type f -printf '%P\n' >$(DISTDIR)/MANIFEST
	## add the two dot-files from Parrot MANIFEST
	echo "$(PARROT)/.gitignore" >>$(DISTDIR)/MANIFEST
	echo "$(PARROT)/tools/dev/.gdbinit" >>$(DISTDIR)/MANIFEST

version_check:
	@[ -n "$(VERSION)" ] || ( echo "\nTry 'make VERSION=yyyy.mm'\n\n"; exit 1)

release: $(DISTDIR)
	perl -ne 'print "$(DISTDIR)/$$_"' $(DISTDIR)/MANIFEST |\
	    tar -zcv -T - -f $(DISTDIR).tar.gz
	
