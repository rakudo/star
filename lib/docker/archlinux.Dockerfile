FROM archlinux:latest AS base

COPY . /home/rstar

RUN pacman -Sy
RUN pacman --noconfirm -S gcc make
RUN /home/rstar/bin/rstar install -p /home/raku
RUN pacman --noconfirm -Rs gcc make

FROM archlinux:latest

COPY --from=base /home/raku /usr/local
COPY --from=base /usr/lib   /usr/lib

ENV PATH=/usr/local/share/perl6/site/bin:$PATH
ENV PATH=/usr/local/share/perl6/vendor/bin:$PATH
ENV PATH=/usr/local/share/perl6/core/bin:$PATH
ENV PERL6LIB=/app/lib

WORKDIR /app

CMD [ "raku" ]
