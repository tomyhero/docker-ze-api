FROM kazeburo/perl-build
MAINTAINER Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

# COPY FROM https://raw.githubusercontent.com/kazeburo/docker-perl/master/Dockerfile

ENV BUILD_PERL_VER 5.20
ENV BUILD_PERL_REL 0

RUN perl-build -DDEBUGGING=-g $BUILD_PERL_VER.$BUILD_PERL_REL /opt/perl-$BUILD_PERL_VER > /tmp/perl-install.log 2>&1
RUN rm -f /tmp/perl-install.log
RUN echo "export PATH=/opt/perl-$BUILD_PERL_VER/bin:\$PATH" > /etc/profile.d/perl-build.sh

# install cpanm,carton and start_server
RUN curl -s --sslv3 -L http://cpanmin.us/ | /opt/perl-$BUILD_PERL_VER/bin/perl - --notest App::cpanminus Carton Server::Starter
# env
ENV PATH /opt/perl-$BUILD_PERL_VER/bin:$PATH

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN /opt/perl-$BUILD_PERL_VER/bin/perl - App::cpanminus Module::Install 

CMD perl -v

# env ---

RUN apt-get -y install vim
RUN apt-get install telnet

RUN git config --global user.email "root@localhsot" \
 && git config --global user.name "root"
# memcached -----


RUN apt-get -y install memcached

# mysql ---------

RUN apt-get update \
 && apt-get install -y libmysqlclient-dev \
 && apt-get install -y mysql-server 

# ze ---------


RUN apt-get -y install libssl-dev


# XXX
RUN curl -0  https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm > /opt/perl-$BUILD_PERL_VER/bin/cpanm \
 && chmod 775 /opt/perl-$BUILD_PERL_VER/bin/cpanm

RUN cpanm --notest Module::Install 
RUN cpanm --notest Module::Install::AuthorTests 
RUN cpanm --notest Module::Install::TestBase 
RUN cpanm --notest http://github.com/tomyhero/p5-App-Home/tarball/master 

RUN cpanm --notest --force Module::Setup

RUN cpanm --notest --force Devel::Size 
RUN cpanm --notest LWP::Protocol::https 
RUN cpanm --notest http://github.com/tomyhero/Ze/tarball/master

RUN cpanm --notest http://github.com/tomyhero/p5-Aplon/tarball/master 
RUN cpanm --notest --force http://github.com/kazeburo/Cache-Memcached-IronPlate/tarball/master 
RUN cpanm --notest http://github.com/onishi/perl5-devel-kytprof/tarball/master 
RUN cpanm --notest DBD::mysql 
RUN cpanm Furl

RUN cd /tmp \
 && ze-setup MyApp API \
 && ln -s MyApp/misc/asset-sample/ asset \
 && cd MyApp \
 && cpanm --installdeps .

RUN service mysql start \
 && service memcached start \
 && cd /tmp/MyApp \
 && chmod 775 ./bin/devel/setup.sh \
 && ./bin/devel/setup.sh \
 && mysql -u root < misc/dbuser.sql \
 && mysqladmin create myapp_local \
 && mysql -u root myapp_local  < misc/myapp.sql

# need an account to prove this application test
# TODO create an account
# && export MYAPP_ENV=local \
# && cd /tmp/MyApp \
# && prove -lr t
