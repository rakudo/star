FROM alpine:latest AS Abase

COPY . /home/rstar

RUN apk add --no-cache bash build-base git perl readline
RUN /home/rstar/bin/rstar install -p /home/raku
RUN apk del bash build-base git perl

FROM alpine:latest

COPY --from=Abase /home/raku /usr/local
COPY --from=Abase /usr/lib   /usr/lib

ENV PATH=/usr/local/share/perl6/site/bin:$PATH
ENV PATH=/usr/local/share/perl6/vendor/bin:$PATH
ENV PATH=/usr/local/share/perl6/core/bin:$PATH
ENV RAKULIB=/app/lib

WORKDIR /app

CMD [ "raku" ]
