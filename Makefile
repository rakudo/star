PARROT_VER = 2.6.0
RAKUDO_TAG = master

DISTDIR = rakudo-star-$(VERSION)

PARROT      = parrot-$(PARROT_VER)
PARROT_TGZ  = $(PARROT).tar.gz
PARROT_DIR  = $(DISTDIR)/$(PARROT)

RAKUDO_DIR  = $(DISTDIR)/rakudo
BUILD_DIR   = $(DISTDIR)/build
MODULES_DIR = $(DISTDIR)/modules

## If you add a module here, don't forget to update MODULES
## in skel/build/Makefile.in to actually install it
MODULES = \
  git://github.com/masak/ufo \
  git://github.com/masak/proto \
  git://github.com/jnthn/zavolaj \
  git://github.com/jnthn/blizkost \
  git://github.com/mberends/MiniDBI \
  git://github.com/masak/xml-writer \
  git://github.com/moritz/svg \
  git://github.com/moritz/svg-plot \
  git://github.com/moritz/Math-RungeKutta \
  git://github.com/moritz/Math-Model \
  git://github.com/mathw/form \
  git://github.com/tadzik/perl6-Config-INI \
  git://github.com/tadzik/perl6-File-Find \
  git://github.com/tadzik/perl6-Term-ANSIColor \
  git://github.com/arnsholt/Algorithm-Viterbi \
  git://gitorious.org/http-daemon/mainline \
  git://github.com/jnthn/test-mock \
  git://github.com/ingydotnet/yaml-pm6 \
  git://github.com/moritz/json \
  git://github.com/snarkyboojum/Perl6-MIME-Base64 \
  git://github.com/cosimo/perl6-lwp-simple \


DISTTARGETS = \
  $(PARROT_DIR) \
  $(RAKUDO_DIR) \
  $(MODULES_DIR) \
  $(BUILD_DIR)/PARROT_REVISION \
  $(DISTDIR)/MANIFEST \

dist: version_check $(DISTDIR) $(DISTTARGETS)

version_check:
	@[ -n "$(VERSION)" ] || ( echo "\nTry 'make VERSION=yyyy.mm'\n\n"; exit 1)

always:

$(DISTDIR): always
	cp -auv skel $(DISTDIR)

$(PARROT_DIR): $(PARROT_TGZ)
	tar -C $(DISTDIR) -xvzf $(PARROT_TGZ)
$(PARROT).tar.gz:
	wget http://ftp.parrot.org/releases/supported/$(PARROT_VER)/$(PARROT_TGZ)

$(RAKUDO_DIR):
	git clone git://github.com/rakudo/rakudo.git $(RAKUDO_DIR)
	cd $(RAKUDO_DIR); git checkout $(RAKUDO_VER)

$(BUILD_DIR)/PARROT_REVISION: $(RAKUDO_DIR) $(RAKUDO_DIR)/build/PARROT_REVISION
	cp $(RAKUDO_DIR)/build/PARROT_REVISION $(BUILD_DIR)

$(MODULES_DIR): always
	mkdir -p $(MODULES_DIR)
	cd $(MODULES_DIR); for repo in $(MODULES); do git clone $$repo.git; done

$(DISTDIR)/Configure.pl: build/Configure.pl
	cp build/Configure.pl $(DISTDIR)

$(DISTDIR)/MANIFEST:
	touch $(DISTDIR)/MANIFEST
	find $(DISTDIR) -name '.*' -prune -o -type f -printf '%P\n' >$(DISTDIR)/MANIFEST
	## add the two dot-files from Parrot MANIFEST
	echo "$(PARROT)/.gitignore" >>$(DISTDIR)/MANIFEST
	echo "$(PARROT)/tools/dev/.gdbinit" >>$(DISTDIR)/MANIFEST

release: dist
	perl -ne 'print "$(DISTDIR)/$$_"' $(DISTDIR)/MANIFEST |\
	    tar -zcv -T - -f $(DISTDIR).tar.gz
	
