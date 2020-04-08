FROM alpine:latest AS base

COPY . /home/rstar

RUN apk add --no-cache bash build-base git perl readline
RUN /home/rstar/bin/rstar install -p /home/raku
RUN apk del bash build-base git perl

FROM alpine:latest

COPY --from=base /home/raku /usr/local
COPY --from=base /usr/lib   /usr/lib

ENV PATH=/usr/local/share/perl6/site/bin:$PATH
ENV PATH=/usr/local/share/perl6/vendor/bin:$PATH
ENV PATH=/usr/local/share/perl6/core/bin:$PATH
ENV PERL6LIB=/app/lib

WORKDIR /app

CMD [ "raku" ]
