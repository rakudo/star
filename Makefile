PARROT_VER = 2.6.0
RAKUDO_TAG = master

DISTDIR = dist

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

$(DISTDIR): $(DISTTARGETS)

$(PARROT_DIR): $(PARROT_TGZ)
	mkdir -p $(DISTDIR)
	tar -C $(DISTDIR) -xvzf $(PARROT_TGZ)
$(PARROT).tar.gz:
	wget http://ftp.parrot.org/releases/supported/$(PARROT_VER)/$(PARROT_TGZ)

$(RAKUDO_DIR):
	git clone git@github.com:rakudo/rakudo.git $(RAKUDO_DIR)
	cd $(RAKUDO_DIR); git checkout $(RAKUDO_VER)

$(DISTDIR)/Configure.pl: build/Configure.pl
	cp build/Configure.pl $(DISTDIR)

$(BUILD_DIR): $(BUILD_FILES)
	mkdir -p $(BUILD_DIR)
	cp $(BUILD_FILES) $(BUILD_DIR)

$(BUILD_DIR)/PARROT_REVISION: $(RAKUDO_DIR) $(RAKUDO_DIR)/build/PARROT_REVISION
	cp $(RAKUDO_DIR)/build/PARROT_REVISION $(BUILD_DIR)

