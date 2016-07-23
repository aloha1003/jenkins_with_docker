FROM jenkins:alpine
COPY install_jenkins_plugin_with_dependency.sh /usr/local/bin/install_jenkins_plugin_with_dependency.sh
COPY custom.groovy /usr/share/jenkins/ref/init.groovy.d/custom.groovy
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
USER root
RUN  /usr/local/bin/install_jenkins_plugin_with_dependency.sh /usr/share/jenkins/ref/plugins.txt


