FROM centos:latest AS base

COPY . /home/rstar

RUN yum -y install perl git gcc make
RUN /home/rstar/bin/rstar install -p /home/raku
RUN yum -y remove perl git gcc make

FROM centos:latest

COPY --from=base /home/raku /usr/local
COPY --from=base /usr/lib64 /usr/lib64

ENV PATH=/usr/local/share/perl6/site/bin:$PATH
ENV PATH=/usr/local/share/perl6/vendor/bin:$PATH
ENV PATH=/usr/local/share/perl6/core/bin:$PATH
ENV PERL6LIB=/app/lib

WORKDIR /app

CMD ["raku"]
