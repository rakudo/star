

If there are any new modules to be added, use C<git submodule> to add
its repo to the modules/ directory.  Also add the module directory
name to the C<modules/MODULES.txt> file.

  $ git submodule add git@github.com:user/acme-example modules/acme-example
  $ echo acme-example >>modules/MODULES.txt
  $ git commit . -m "Added acme-example to installed modules."
