FROM alpine:latest AS build

ARG VERSION

COPY work /tmp

RUN cd -- "$(mktemp -d)"
RUN tar xzf "/tmp/release/rakudo-star-$VERSION.tar.gz"
RUN cd -- "rakudo-star-$VERSION"
RUN apk add --no-cache build-base git perl perl-utils libressl
RUN perl Configure.pl --prefix=/usr/local --backend=moar --gen-moar --make-install

FROM alpine:latest

RUN apk add --no-cache libressl

COPY --from=build /usr/local /usr/local

CMD [ "perl6" ]
