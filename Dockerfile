FROM aemdesign/aem-base:jdk11

MAINTAINER devops <devops@aem.design>

LABEL   os="centos 7" \
        java="oracle 8" \
        container.description="aem instance, will run as author unless specified otherwise" \
        version="6.5.5.0" \
        imagename="aem" \
        test.command=" java -version 2>&1 | grep 'java version' | sed -e 's/.*java version "\(.*\)".*/\1/'" \
        test.command.verify="1.8"

ARG AEM_JVM_OPTS="-server -Xms1024m -Xmx1024m -XX:MaxDirectMemorySize=256M -XX:+CMSClassUnloadingEnabled -Djava.awt.headless=true -Dorg.apache.felix.http.host=0.0.0.0"
ARG AEM_JVM_OPTS="${AEM_JVM_OPTS} -XX:+UseParallelGC --add-opens=java.desktop/com.sun.imageio.plugins.jpeg=ALL-UNNAMED --add-opens=java.base/sun.net.www.protocol.jrt=ALL-UNNAMED --add-opens=java.naming/javax.naming.spi=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.dom=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED -Dnashorn.args=--no-deprecation-warning"
ARG AEM_START_OPTS="start -c /aem/crx-quickstart -i launchpad -p 8080 -a 0.0.0.0 -Dsling.properties=conf/sling.properties"
ARG AEM_RUNMODE="-Dsling.run.modes=author,crx3,crx3tar,nosamplecontent"
ARG PACKAGE_PATH="./crx-quickstart/install"

ENV AEM_JVM_OPTS="${AEM_JVM_OPTS}" \
    AEM_START_OPTS="${AEM_START_OPTS}"\
    AEM_RUNMODE="${AEM_RUNMODE}"

WORKDIR /aem

COPY scripts/*.sh /aem/
COPY jar/aem-quickstart.jar ./aem-quickstart.jar

#unpack the jar
RUN java -jar aem-quickstart.jar -unpack && \
    rm aem-quickstart.jar && \
    export AEM_JARFILE=$(find /aem/crx-quickstart/app -name cq-quickstart-cloudready-*)

COPY dist/install.first/*.config ./crx-quickstart/install/
COPY dist/install.first/logs/*.config ./crx-quickstart/install/
COPY dist/install.first/conf/sling.properties ./crx-quickstart/conf/sling.properties

COPY packages/ $PACKAGE_PATH/

#expose port
EXPOSE 8080 58242 57345 57346

VOLUME ["/aem/crx-quickstart/repository", "/aem/crx-quickstart/logs", "/aem/backup"]

#ensure script has exec permissions
RUN chmod +x /aem/*.sh

#make java pid 1
ENTRYPOINT ["/bin/tini", "--", "/aem/run-tini.sh"]
