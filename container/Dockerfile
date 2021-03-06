FROM    centos:8

LABEL   maintainer="Richard Bowers<richard.bowers@cruk.cam.ac.uk>"

ARG INSTALL_DIR=/opt
ARG BUILD_DIR=/var/tmp/alignment_software_build

ARG BEDTOOLS=2.29.2
ARG BWA=0.7.17
ARG BWAMEM=2.1
ARG PICARD=2.25.1
ARG SAMTOOLS=1.11
ARG STAR=2.7.7a

ARG TAROPTS="--no-same-owner --no-same-permissions"

ENV JAVA_HOME=/usr/lib/jvm/jre-11
ENV PATH=$JAVA_HOME/bin:$PATH

RUN dnf install -y dnf-plugins-core epel-release
RUN dnf config-manager --set-enabled powertools
RUN dnf makecache && dnf update -y
RUN dnf install -y \
	bzip2 bzip2-devel gcc-c++ git java-11-openjdk-headless \
	libcurl-devel make ncurses-devel openssl-devel python2 \
	R-core unzip wget xz-devel zlib-devel

RUN alternatives --set python /usr/bin/python2
RUN mkdir -p ${INSTALL_DIR} ${BUILD_DIR}

# Fastq splitter
RUN cd ${BUILD_DIR}; \
    git clone https://github.com/vasisht/fastq_splitter.git; \
    cd ${BUILD_DIR}/fastq_splitter; \
    gcc -o /usr/local/bin/splitfastq fastq_splitter.c -lz

# samtools
RUN cd ${BUILD_DIR}; \
    wget https://github.com/samtools/samtools/releases/download/${SAMTOOLS}/samtools-${SAMTOOLS}.tar.bz2 && \
    tar ${TAROPTS} -jxf samtools-${SAMTOOLS}.tar.bz2
RUN cd ${BUILD_DIR}/samtools-${SAMTOOLS}; \
    ./configure --prefix="${INSTALL_DIR}/samtools-${SAMTOOLS}" && \
    make && \
    make install

# bedtools2
RUN cd ${BUILD_DIR}; \
    wget https://github.com/arq5x/bedtools2/releases/download/v${BEDTOOLS}/bedtools-${BEDTOOLS}.tar.gz && \
    tar ${TAROPTS} -xzf ${BUILD_DIR}/bedtools-${BEDTOOLS}.tar.gz
RUN cd ${BUILD_DIR}/bedtools2; \
    make install prefix="" DESTDIR="${INSTALL_DIR}/bedtools-${BEDTOOLS}"

# BWA
RUN cd ${BUILD_DIR}; \
    wget https://github.com/lh3/bwa/releases/download/v${BWA}/bwa-${BWA}.tar.bz2
RUN cd ${INSTALL_DIR}; \
    tar ${TAROPTS} -jxf ${BUILD_DIR}/bwa-${BWA}.tar.bz2; \
    cd ${INSTALL_DIR}/bwa-${BWA}; \
    make

# BWA-mem2
RUN cd ${BUILD_DIR}; \
    wget https://github.com/bwa-mem2/bwa-mem2/releases/download/v${BWAMEM}/bwa-mem2-${BWAMEM}_x64-linux.tar.bz2
RUN cd ${INSTALL_DIR}; \
    tar ${TAROPTS} -jxf ${BUILD_DIR}/bwa-mem2-${BWAMEM}_x64-linux.tar.bz2; \
    mv bwa-mem2-${BWAMEM}_x64-linux bwa-mem2-${BWAMEM}

# STAR
RUN cd ${BUILD_DIR}; \
    wget -O STAR-${STAR}.tar.gz https://github.com/alexdobin/STAR/archive/${STAR}.tar.gz
RUN cd ${INSTALL_DIR}; \
    tar ${TAROPTS} -xzf ${BUILD_DIR}/STAR-${STAR}.tar.gz

# UCSC Tools
RUN mkdir ${INSTALL_DIR}/ucsc_tools; \
    cd ${INSTALL_DIR}/ucsc_tools; \
    wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig; \
    wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedSort; \
    chmod a+rx *

# Picard
RUN cd ${INSTALL_DIR}; \
    wget -O picard-${PICARD}.jar https://github.com/broadinstitute/picard/releases/download/${PICARD}/picard.jar


## Clean up
RUN cd / && rm -rf ${BUILD_DIR}
