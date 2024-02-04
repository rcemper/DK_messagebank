ARG IMAGE=intersystemsdc/iris-community
FROM $IMAGE

USER root
        
WORKDIR /opt/messagebank
#  RUN mkdir /ghostdb/ && mkdir /voldata/ && mkdir /voldata/irisdb/ && chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/messagebank /ghostdb/ /voldata/ /voldata/irisdb/
RUN mkdir /ghostdb/ && mkdir /voldata/ && mkdir /voldata/irisdb/ && chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_MGRUSER} /opt/messagebank /ghostdb/ /voldata/ /voldata/irisdb/
USER ${ISC_PACKAGE_MGRUSER}

COPY  Installer.cls .
COPY  src src
COPY iris.script /tmp/iris.script

RUN iris start IRIS \
    && iris session IRIS < /tmp/iris.script \
    && iris stop IRIS quietly

HEALTHCHECK --interval=10s --timeout=3s --retries=2 CMD wget localhost:52773/csp/user/cache_status.cxw || exit 1

USER root
COPY vcopy.sh vcopy.sh
RUN rm -f $ISC_PACKAGE_INSTALLDIR/mgr/alerts.log $ISC_PACKAGE_INSTALLDIR/mgr/IRIS.WIJ $ISC_PACKAGE_INSTALLDIR/mgr/journal/* && cp -Rpf /voldata/* /ghostdb/ && rm -fr /voldata/* \
  && chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_MGRUSER} /opt/messagebank/vcopy.sh /voldata && chmod +x /opt/messagebank/vcopy.sh

USER ${ISC_PACKAGE_MGRUSER}  