PARROT_VER = 3.11.0
PARROT_REL = supported/$(PARROT_VER)
RAKUDO_VER = 2012.01

DISTDIR = rakudo-star-$(VERSION)

PARROT      = parrot-$(PARROT_VER)
PARROT_TGZ  = $(PARROT).tar.gz
PARROT_DIR  = $(DISTDIR)/$(PARROT)

RAKUDO_DIR  = $(DISTDIR)/rakudo
RAKUDO_TGZ  = rakudo-$(RAKUDO_VER).tar.gz
BUILD_DIR   = $(DISTDIR)/build
MODULES_DIR = $(DISTDIR)/modules

## If you add a module here, don't forget to update MODULES
## in skel/build/Makefile.in to actually install it
MODULES = \
  http://github.com/masak/ufo \
  http://github.com/jnthn/zavolaj \
  http://github.com/masak/xml-writer \
  http://github.com/moritz/svg \
  http://github.com/moritz/svg-plot \
  http://github.com/moritz/Math-RungeKutta \
  http://github.com/moritz/Math-Model \
  http://github.com/tadzik/perl6-Term-ANSIColor \
  http://github.com/arnsholt/Algorithm-Viterbi \
  http://github.com/jnthn/test-mock \
  http://github.com/moritz/json \
  http://github.com/snarkyboojum/Perl6-MIME-Base64 \
  http://github.com/cosimo/perl6-lwp-simple \
  http://github.com/cosimo/perl6-digest-md5 \
  http://github.com/tadzik/perl6-File-Tools \
  http://github.com/tadzik/perl6-Config-INI \
  http://github.com/tadzik/panda \
  https://github.com/mberends/http-server-simple

DISTTARGETS = \
  $(PARROT_DIR) \
  $(RAKUDO_DIR) \
  $(MODULES_DIR) \
  $(BUILD_DIR)/PARROT_REVISION \
  star-patches \
  $(DISTDIR)/MANIFEST \

dist: version_check $(DISTDIR) $(DISTTARGETS)

version_check:
	@[ -n "$(VERSION)" ] || ( echo "\nTry 'make VERSION=yyyy.mm'\n\n"; exit 1)

always:

$(DISTDIR): always
	cp -av skel $(DISTDIR)

$(PARROT_DIR): $(PARROT_TGZ)
	tar -C $(DISTDIR) -xvzf $(PARROT_TGZ)

$(PARROT_TGZ):
	wget http://ftp.parrot.org/releases/$(PARROT_REL)/$(PARROT_TGZ)

$(RAKUDO_DIR): $(RAKUDO_TGZ)
	tar -C $(DISTDIR) -xvzf $(RAKUDO_TGZ)
	mv $(DISTDIR)/rakudo-$(RAKUDO_VER) $(RAKUDO_DIR)
	
$(RAKUDO_TGZ):
	wget --no-check-certificate https://github.com/downloads/rakudo/rakudo/$(RAKUDO_TGZ)

$(BUILD_DIR)/PARROT_REVISION: $(RAKUDO_DIR) $(RAKUDO_DIR)/build/PARROT_REVISION
	cp $(RAKUDO_DIR)/build/PARROT_REVISION $(BUILD_DIR)

$(MODULES_DIR): always
	mkdir -p $(MODULES_DIR)
	cd $(MODULES_DIR); for repo in $(MODULES); do git clone $$repo.git; done
	# cd $(MODULES_DIR)/yaml-pm6; git checkout rakudo-star-1

star-patches:
	[ ! -f build/$(VERSION)-patch.pl ] || DISTDIR=$(DISTDIR) perl build/$(VERSION)-patch.pl

$(DISTDIR)/MANIFEST:
	touch $(DISTDIR)/MANIFEST
	find $(DISTDIR) -name '.*' -prune -o -type f -print | sed -e 's|^[^/]*/||' >$(DISTDIR)/MANIFEST
	## add the two dot-files from Parrot MANIFEST
	echo "$(PARROT)/.gitignore" >>$(DISTDIR)/MANIFEST
	echo "$(PARROT)/tools/dev/.gdbinit" >>$(DISTDIR)/MANIFEST

release: dist tarball

tarball:
	perl -ne 'print "$(DISTDIR)/$$_"' $(DISTDIR)/MANIFEST |\
	    tar -zcv -T - -f $(DISTDIR).tar.gz
