FROM osrf/ros:kinetic-desktop


RUN apt-get update && apt-get install -qy\
    software-properties-common \
    wget \
    abi-compliance-checker \
    python3-pip \
    python3-venv \
    abi-dumper \
    git

RUN mkdir -p /tmp/bootstrap/extracted /tmp/pyside_ppa/extracted

WORKDIR /tmp/bootstrap
RUN wget -q http://repositories.ros.org/ubuntu/building/dists/xenial/main/binary-amd64/Packages
RUN for p in $(cat Packages | grep pyside2 | grep pool | awk '{print $2}'); do wget -q http://repos.ros.org/repos/ros_bootstrap/$p; done

RUN for p in $(ls *.deb); do dpkg -X $p extracted; done

WORKDIR /tmp/pyside_ppa
RUN add-apt-repository -s -u -y ppa:tully.foote/pyside2-reproduction
RUN for p in $(apt-cache showsrc pyside2 | grep "arch=" | awk '{print $1}' | grep -v dbg); do apt-get download $p; done

RUN for p in $(ls *.deb); do dpkg -X $p extracted; done


RUN mkdir -p /py3venv
# TODO consolidate above
# RUN apt-get update && apt-get install -qy\

# build dependencies
RUN apt-get build-dep -qy pyside2

WORKDIR /tmp
RUN git clone https://github.com/lvc/abi-compliance-checker.git
WORKDIR /tmp/abi-compliance-checker
RUN make && make install

RUN python3 -m venv /py3venv
RUN echo revision 1
RUN . /py3venv/bin/activate && pip install git+https://github.com/osrf/auto-abi-checker.git

ENV COMPILATION_FLAGS='-I/usr/include/python2.7/ -I/tmp/ -DPYSIDE_EXPORTS -DQT_CORE_LIB -DQT_NETWORK_LIB -DQT_NO_DEBUG -DQT_QML_LIB -DQT_WIDGETS_LIB -I/usr/include/x86_64-linux-gnu/qt5/QtHelp/ -DQT_NO_OPENGL -I/usr/include/x86_64-linux-gnu/qt5/QtNetwork/ -I/usr/include/x86_64-linux-gnu/qt5/QtScript -I/usr/include/x86_64-linux-gnu/qt5/QtScriptTools/ -I/usr/include/x86_64-linux-gnu/qt5/QtSql -I/usr/include/x86_64-linux-gnu/qt5/QtSvg -I/usr/include/x86_64-linux-gnu/qt5/QtTest -I/usr/include/x86_64-linux-gnu/qt5/QtXml -I/usr/include/x86_64-linux-gnu/qt5/QtXmlPatterns -I/usr/include/python2.7 -fPIC'

WORKDIR /tmp
RUN wget -q https://git.launchpad.net/ros-common/plain/PySide2/pysideqtesttouch.h?h=reproduction -O /tmp/pysideqtesttouch.h

RUN . /py3venv/bin/activate && auto-abi.py --orig-type local-dir --orig /tmp/bootstrap/extracted --new-type local-dir --new /tmp/pyside_ppa/extracted || true


