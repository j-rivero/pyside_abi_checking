FROM osrf/ros:kinetic-desktop


RUN apt-get update && apt-get install -qy\
    software-properties-common \
    wget \
    abi-compliance-checker

RUN mkdir -p /tmp/boostrap/extracted /tmp/pyside_ppa/extracted

WORKDIR /tmp/bootstrap
RUN wget http://repositories.ros.org/ubuntu/building/dists/xenial/main/binary-amd64/Packages
RUN for p in $(cat Packages | grep pyside2 | grep pool | awk '{print $2}'); do wget -q http://repos.ros.org/repos/ros_bootstrap/$p; done

RUN for p in $(ls *.deb); do dpkg -X $p extracted; done

WORKDIR /tmp/bootstrap
RUN add-apt-repository -s -u -y ppa:tully.foote/pyside2-reproduction
RUN for p in $(apt-cache showsrc pyside2 | grep "arch=" | awk '{print $1}' | grep -v dbg); do apt-get download $p; done

RUN for p in $(ls *.deb); do dpkg -X $p extracted; done
