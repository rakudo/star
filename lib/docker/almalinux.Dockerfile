FROM almalinux:latest AS base


RUN groupadd -r rstar && useradd -m -r -g rstar rstar
COPY . /home/rstar
RUN chown -R rstar:rstar /home/rstar

RUN yum -y install perl git gcc make
RUN /home/rstar/bin/rstar install -p /home/rstar
RUN yum -y remove perl git gcc make

FROM almalinux:latest

COPY --from=base /home/rstar /usr/local
COPY --from=base /usr/lib64 /usr/lib64

ENV PATH=/usr/local/share/perl6/site/bin:$PATH
ENV PATH=/usr/local/share/perl6/vendor/bin:$PATH
ENV PATH=/usr/local/share/perl6/core/bin:$PATH
ENV RAKULIB=/app/lib

WORKDIR /app

CMD ["raku"]
