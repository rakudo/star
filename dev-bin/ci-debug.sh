#! /usr/bin/env sh

#
# This is an additional script, ran during CI testing. This is intended to
# debug issues that show up only during CI testing.
#

main()
{
	perl6 -v
	perl6 -e 'dd $*KERNEL.signal("SIGHUP"), $*KERNEL.signal("HUP")'
	perl6 -e 'dd $*KERNEL.signal(SIGHUP)'
	perl6 -e 'dd $*KERNEL.signal("SIGHUP")'
	perl6 -e 'dd $*KERNEL.signal(HUP)'
	perl6 -e 'dd $*KERNEL.signal("HUP")'
	perl6 -e 'dd Signal.enums'
	perl6 -e 'dd $*KERNEL.signals'
	uname -a
}

main "$@"
