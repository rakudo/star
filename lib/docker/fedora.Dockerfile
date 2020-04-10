FROM fedora:latest AS base

COPY . /home/rstar

RUN dnf install -y gcc make perl
RUN /home/rstar/bin/rstar install -p /home/raku
RUN dnf remove -y gcc make perl

FROM fedora:latest

COPY --from=base /home/raku /usr/local
COPY --from=base /usr/lib   /usr/lib

ENV PATH=/usr/local/share/perl6/site/bin:$PATH
ENV PATH=/usr/local/share/perl6/vendor/bin:$PATH
ENV PATH=/usr/local/share/perl6/core/bin:$PATH
ENV PERL6LIB=/app/lib

WORKDIR /app

CMD [ "raku" ]
