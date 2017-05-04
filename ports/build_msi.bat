rem needs strawberry perl installed and WiX Toolset in the %path%
rmdir /q/s \rakudo
perl Configure.pl  --prefix=C:\rakudo --gen-moar
gmake install
rem following two lines are temporary hack
rem main rakudo star Configure.pl needs fixing for windows
copy c:\strawberry\perl\bin\libgcc_s_sjlj-1.dll c:\rakudo\bin
copy c:\strawberry\perl\bin\libwinpthread-1.dll c:\rakudo\bin
gmake msi
