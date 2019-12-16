FROM ubuntu:18.04

#Needed to set-up Mongo repository
RUN apt-get update --fix-missing
RUN apt-get update
RUN apt-get install -y gnupg wget

#Mongo settings
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list

#Ubuntu libraries 
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential mongodb-org cpanminus unzip vim

#Perl libraries
RUN cpanm -i --notest Mojolicious MongoDB IO::Prompter Template Array::Utils LWP::UserAgent JSON Mojolicious::Plugin::TemplateToolkit Template::Plugin::String::Compare

#Software installation (by github)
RUN wget https://github.com/cym0n/BalanceOfPower/archive/0.500000.zip
RUN unzip 0.500000.zip
RUN cp -r BalanceOfPower-0.500000/src/lib /opt
RUN cp -r BalanceOfPower-0.500000/src/script /opt
RUN cp -r BalanceOfPower-0.500000/src/public /opt
RUN cp -r BalanceOfPower-0.500000/src/templates /opt
COPY balance_of_power-web.conf /opt
COPY entrypoint.sh /etc/init.d
RUN chmod +x /etc/init.d/entrypoint.sh

ENV PERL5LIB /opt/lib
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/script

CMD /etc/init.d/entrypoint.sh

#CMD tail -f


