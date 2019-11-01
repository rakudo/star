FROM alpine:latest AS build

ARG VERSION

COPY work /tmp

RUN cd -- /tmp/rakudo-star-$VERSION
RUN apk add --no-cache build-base git perl perl-utils libressl
RUN perl Configure.pl --prefix=/usr/local --backend=moar --gen-moar --make-install

FROM alpine:latest

COPY --from=build /usr/local /usr/local

CMD [ "perl6" ]
