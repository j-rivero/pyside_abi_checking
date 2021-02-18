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
RUN wget -q http://repositories.ros.org/ubuntu/main/dists/xenial/main/binary-amd64/Packages && \
for p in $(cat Packages | grep shiboken2 | grep pool | grep -v python3 | grep -v dbg | awk '{print $2}'); do wget -q http://repositories.ros.org/ubuntu/main/$p; done

RUN for p in $(ls *.deb); do dpkg -X $p extracted; done

WORKDIR /tmp/pyside_ppa
RUN add-apt-repository -s -u -y ppa:tully.foote/pyside2-reproduction
RUN for p in $(apt-cache showsrc shiboken2 | grep "arch=" | awk '{print $1}' | grep -v dbg); do apt-get download $p; done

RUN for p in $(ls *.deb); do dpkg -X $p extracted; done


RUN mkdir -p /py3venv
RUN apt-get build-dep -qy pyside2

WORKDIR /tmp
RUN git clone https://github.com/lvc/abi-compliance-checker.git
WORKDIR /tmp/abi-compliance-checker
RUN make && make install

RUN python3 -m venv /py3venv
RUN echo revision 1
RUN . /py3venv/bin/activate && pip install git+https://github.com/osrf/auto-abi-checker.git

ENV COMPILATION_FLAGS='-I/usr/include/python2.7/ -I/tmp/ -fPIC'

RUN . /py3venv/bin/activate && auto-abi.py --orig-type local-dir --orig /tmp/bootstrap/extracted --new-type local-dir --new /tmp/pyside_ppa/extracted || true
