#
# NetBeans 8.1 + JDK 1.8u71 bundle
#
#Run like so:
#   docker run -ti --rm            
#       -e DISPLAY=$DISPLAY \
#       -e XAUTHORITY=$XAUTH \        
#       -v /tmp/.X11-unix:/tmp/.X11-unix \            
#       -v /home/kisira/workspace:/home/developer/ \
#       -v /home/kisira/Development/docker-netbeans/workspace:/workspace \
#       kisira/netbeans
#
#Additionally Create a symbolic link as below on terminal: 
#   ln -s ./bin ./script
#to run the rails project in Netbeans succesfully.
#
FROM ubuntu
MAINTAINER Agola Kisira Odero "agolakisira@gmail.com"

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get install -y build-essential software-properties-common \
    apt-utils curl wget zlib1g-dev patch sudo libxml2-dev libxslt1-dev gksu \   
    liblzma-dev libcurl4-openssl-dev python-software-properties ruby-pkg-config \
    libffi-dev libreadline-dev debconf-utils xvfb nodejs ruby ruby-dev ruby-bundler \
    openssl libreadline6 zlib1g libssl-dev libyaml-dev \
    libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev \
    automake libtool bison subversion pkg-config \
    libpq-dev libxext-dev libxrender-dev libxtst-dev unzip firefox && \    
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN add-apt-repository ppa:git-core/ppa -y && \
    apt-get update && \
    apt-get install -y git-core && \                
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

#RUN mkdir /etc/mysql/conf.d/ 
#COPY ./my.cnf /etc/mysql/conf.d/mysql.cnf
RUN export DEBIAN_FRONTEND="noninteractive" && \    
    apt-get update && apt-get -q -y install mysql-server libmysqlclient-dev && \    
    apt-get clean && \    
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

ENV NETBEANS_URL=http://download.oracle.com/otn-pub/java/jdk-nb/8u71-8.1/jdk-8u71-nb-8_1-linux-x64.sh
ENV POLICY_URL=http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip 
ENV COOKIE="Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie"
#ENV NETBEANS_PLUGIN=http://plugins.netbeans.org/download/plugin/3696
ENV NETBEANS_PLUGIN=./netbeans_ruby_and_rails.zip
    

RUN wget --progress=bar:force $NETBEANS_URL -O /tmp/netbeans.sh \
    --no-cookies --no-check-certificate --header "$COOKIE" && \
    chmod +x /tmp/netbeans.sh && \
    echo 'Installing netbeans' && \
    /tmp/netbeans.sh --silent && \
    rm -rf /tmp/* && \
    ln -s $(ls -d /usr/local/netbeans-*) /usr/local/netbeans

# Download & install the unlimited strength policy jars
RUN curl -L $POLICY_URL -o /tmp/policy.zip \
		--cookie 'oraclelicense=accept-securebackup-cookie;' \
	&& JAVA_HOME=$(ls -d /usr/local/jdk1.*) \
        && unzip -j -o /tmp/policy.zip -d $JAVA_HOME/jre/lib/security \
	&& rm /tmp/policy.zip
	
RUN mkdir -p /home/plugins 

#file:/home/plugins/ruby_and_rails/updates.xml
#RUN wget --progress=bar:force $NETBEANS_PLUGIN -O /home/plugins/1434628827_ruby_and_rails.zip && \ 
    #unzip /home/plugins/1434628827_ruby_and_rails.zip -d /home/plugins/ruby_and_rails

#Download the netbeans Ruby and Rails Plugin from http://plugins.netbeans.org/download/plugin/3696 to the current folder 
#name it ruby_and_rails.zip. Eventually in netbeans->tools->plugins-settings->add the file url below:
#file:/home/plugins/ruby_and_rails/updates.xml
COPY $NETBEANS_PLUGIN /home/plugins/ruby_and_rails.zip
RUN unzip /home/plugins/ruby_and_rails.zip -d /home/plugins/ruby_and_rails

RUN mkdir /home/ruby  && \
    git clone https://github.com/rbenv/rbenv.git /home/ruby/.rbenv && \    
    git clone https://github.com/rbenv/ruby-build.git /home/ruby/.rbenv/plugins/ruby-build && \    
    git clone https://github.com/rbenv/rbenv-gem-rehash.git /home/ruby/.rbenv/plugins/rbenv-gem-rehash     

RUN /home/ruby/.rbenv/plugins/ruby-build/install.sh

ENV PATH /home/ruby/.rbenv/bin:$PATH #ENV PATH /root/.rbenv/bin:$PATH
#RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> .bashrc
RUN echo 'eval "$(rbenv init -)"' >> $HOME/.bash_profile

# Install ruby version 2.3.0
ENV CONFIGURE_OPTS --disable-install-doc
RUN xargs -L 1 rbenv install 2.3.0

RUN bash -l -c 'gem update --system'
RUN bash -l -c 'gem update'
RUN bash -l -c 'gem install nokogiri' #RUN bash -l -c 'gem install nokogiri -- --use-system-libraries'

# Install Bundler for ruby
RUN bash -l -c 'rbenv global 2.3.0; gem install bundler;'
RUN bash -l -c 'gem install rails-api --no-rdoc --no-ri'
RUN bash -l -c 'gem install mime-types-data --no-rdoc --no-ri'
RUN bash -l -c 'gem install rails --no-rdoc --no-ri'
RUN bash -l -c 'gem install mysql2 --no-rdoc --no-ri'
RUN bash -l -c 'gem install ruby-debug-ide --no-rdoc --no-ri'

# install RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN \curl -L https://get.rvm.io | bash -s stable --rails
RUN bash -l -c 'source /usr/local/rvm/scripts/rvm'

ENV PATH=/usr/local/netbeans/bin:$PATH

EXPOSE 3306
EXPOSE 22
EXPOSE 80
EXPOSE 3389
EXPOSE 3000

RUN export uid=1000 gid=1000 && \  
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    echo 'export PATH="/home/ruby/.rbenv/bin:$PATH"' >> /home/developer/.bashrc && \
    echo 'export PATH="/home/ruby/.rbenv/plugins/ruby-build/bin:$PATH"' >> /home/developer/.bashrc && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

#RUN /usr/sbin/mysqld 
    #& \
    #sleep 10s &&\
    #echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'changeme' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
    
USER developer
ENV HOME /home/developer
WORKDIR /home/developer
CMD sudo service mysql start && bash #/usr/local/netbeans/bin/netbeans 
#CMD bash 
