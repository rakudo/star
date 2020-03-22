#!/usr/bin/env raku

use v6.d;

#| Install a Raku module.
sub MAIN (
	#| The path to the Raku module sources.
	IO() $path is copy,

	#| The repository to install it in. Options are "site" (ment for
	#| user-installed modules), "vendor" (ment for distributions that want
	#| to include more modules) and "core" (ment for modules distributed
	#| along with Raku itself).
	Str:D :$repo = 'vendor',

	#| Force installation of the module.
	Bool:D :$force = True,
) {
	CATCH {
		default { $_.say; exit 1; }
	}

	my $repository = CompUnit::RepositoryRegistry.repository-for-name($repo);
	my $meta-file = $path.add('META6.json');
	my $dist = Distribution::Path.new($path, :$meta-file);

	$repository.install($dist, :$force);
}
