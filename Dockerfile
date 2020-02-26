FROM alpine:latest AS build

ARG VERSION

COPY work /tmp/work

WORKDIR /tmp/rakudo-star

RUN apk add --no-cache build-base git perl perl-utils openssl-dev readline-dev
RUN tar xzf "/tmp/work/release/rakudo-star-$VERSION.tar.gz"
RUN cd -- "rakudo-star-$VERSION" \
	&& perl Configure.pl --prefix=/usr/local --backend=moar --gen-moar --make-install

FROM alpine:latest

WORKDIR /root

RUN apk add --no-cache libressl

COPY --from=build /usr/local /usr/local

CMD [ "perl6" ]
