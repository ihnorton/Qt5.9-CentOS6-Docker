FROM centos:6.7

RUN mkdir -p /bld /bld/bin
ENV PATH="/bld:/bld/bin:${PATH}" NPROC=$(nproc)

# install epel and update so we have reasonably recent CAs and other things 
RUN curl -OL http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \
    && rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm \
    && rm epel-release-6-8.noarch.rpm \
    && yum update -y

# install toolchain
#   https://www.softwarecollections.org/en/scls/rhscl/devtoolset-3/
RUN yum install centos-release-scl devtoolset-3-toolchain

# enable devtoolset-3
ENV PATH="/opt/rh/devtoolset-3/root/usr/bin:${PATH}" \
    LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib

# WebEngine deps 
#  - https://wiki.qt.io/QtWebEngine/How_to_Try#Building_QtWebengine
#  - https://src.fedoraproject.org/rpms/qt5-qtwebengine/blob/master/f/qt5-qtwebengine.spec
#  - https://bugreports.qt.io/browse/QTBUG-58790?focusedCommentId=347575&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-347575
RUN yum -y install mesa-libEGL-devel libgcrypt-devel libgcrypt pciutils-devel nss-devel libXtst-devel gperf \
                   cups-devel pulseaudio-libs-devel libgudev1-devel libcap-devel alsa-lib-devel flex bison ruby \
                   gstreamer-devel.x86_64 gstreamer-plugins-base-devel.x86_64 snappy snappy-devel re2-devel ffmpeg-devel \
                   libXcomposite-devel.x86_64 libXrandr-devel.x86_64 \
                   alsa-lib-devel bzip2-devel cairo-devel cups-devel dbus-devel dbus-glib-devel expat-devel fontconfig-devel \
                   freetype-devel giflib-devel glib2-devel gstreamer-devel libcap-devel libcurl-devel libffi-devel libgcrypt-devel \
                   libgudev1-devel libicu-devel libjpeg-devel libpng-devel libtiff-devel libX11-devel libXau-devel libxcb-devel \
                   libXcomposite-devel libXcursor-devel libXdamage-devel libXext-devel libXfixes-devel libXi-devel libxml2-devel \
                   libXrandr-devel libXrender-devel libXScrnSaver-devel libxslt-devel libXtst-devel mesa-libEGL-devel mesa-libGL-devel \
                   nspr-devel nss-devel pam-devel pango-devel pciutils-devel pulseaudio-libs-devel zlib-devel

# might need to start dbus...
RUN service messagebus restart

# need to build newer webp from source
#   note installs in /usr/local so we need to explicitly tell qt configure
RUN curl -OL http://downloads.webmproject.org/releases/webp/libwebp-1.0.0.tar.gz \
    && tar xf libwebp-1.0.0.tar.gz \
    && cd libwebp-1.0.0 \
    && ./configure \
    && make -j${NPROC} install


#  python >=2.7.5
#    2.7.8 from https://www.softwarecollections.org/en/scls/rhscl/python27/
RUN yum -y localinstall https://www.softwarecollections.org/repos/rhscl/python27/epel-6-x86_64/noarch/rhscl-python27-epel-6-x86_64-1-2.noarch.rpm
RUN yum -y install python27-python && yum clean all


ENV PATH="/opt/rh/python27/root/usr/bin:${PATH}"
    LD_LIBRARY_PATH="/opt/rh/python27/root/usr/lib64:${LD_LIBRARY_PATH}"

# ninja binary - not necessary, qt pulls it
#RUN cd /bld/bin && curl -1 https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip && \
#    unzip ninja-linux.zip && rm ninja-linux.zip 




# now finally configure...
#  TODO remove recheck
RUN ./configure -recheck \
    -prefix /bld/qt-everywhere-build-5.9.5 -release -opensource -confirm-license -c++std c++11 -silent -nomake examples -nomake tests -skip qtgamepad -skip qtcharts -skip qt3d -skip qtandroidextras -skip qtpurchasing -skip qtserialbus -skip qtserialport -skip qtwayland -skip qtspeech -skip qtlocation -skip qtsensors -skip qtcanvas3d -skip qtdoc -qt-xcb -qt-zlib -qt-libjpeg -qt-libpng -qt-xkbcommon -qt-freetype -qt-pcre -qt-freetype -qt-harfbuzz -qt-webp -qt-opus -qt-ffmpeg -openssl -I /bld/qt-everywhere-deps-5.9.5/openssl-1.0.2n/include -L /bld/qt-everywhere-deps-5.9.5/openssl-1.0.2n -webp -I /usr/local/include/webp/ -L /usr/local/lib/
