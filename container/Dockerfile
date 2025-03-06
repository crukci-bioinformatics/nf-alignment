FROM    rockylinux/rockylinux:9.5

LABEL   maintainer="Richard Bowers<richard.bowers@cruk.cam.ac.uk>"

ARG INSTALL_DIR=/opt
ARG BUILD_DIR=/var/tmp/alignment_software_build

ARG GROOVY_V=4.0.25

ARG BEDTOOLS_V=2.31.1
ARG BOWTIE2_V=2.5.4
ARG BWA_V=0.7.18
ARG BWAMEM_V=2.2.1
ARG PICARD_V=3.3.0
ARG HTSLIB_V=1.21
ARG SAMTOOLS_V=1.21
ARG STAR_V=2.7.11b

ARG TAROPTS="--no-same-owner --no-same-permissions"

ENV JAVA_HOME=/usr/lib/jvm/jre-21
ENV GROOVY_HOME=${INSTALL_DIR}/groovy-${GROOVY_V}
ENV PATH=$JAVA_HOME/bin:$GROOVY_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

RUN dnf install -y dnf-plugins-core epel-release
RUN dnf config-manager --set-enabled crb
RUN dnf makecache && dnf update -y
RUN dnf install -y \
    bzip2 bzip2-devel gcc-c++ git java-21-openjdk-headless \
    libcurl-devel make ncurses-devel openssl-devel \
    perl-Sys-Hostname procps-ng R-core \
    unzip wget xz-devel zlib-devel

RUN mkdir -p ${INSTALL_DIR} ${BUILD_DIR}

# Groovy
RUN cd ${BUILD_DIR}; \
    wget -O groovy.zip https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-${GROOVY_V}.zip && \
    unzip -d ${INSTALL_DIR} groovy.zip

# Fastq splitter
RUN cd ${BUILD_DIR}; \
    git clone https://github.com/vasisht/fastq_splitter.git; \
    cd ${BUILD_DIR}/fastq_splitter; \
    gcc -o /usr/local/bin/splitfastq fastq_splitter.c -lz

# htslib (separate build to include bgzip and tabix)
RUN cd ${BUILD_DIR}; \
    wget https://github.com/samtools/htslib/releases/download/${HTSLIB_V}/htslib-${HTSLIB_V}.tar.bz2 && \
    tar ${TAROPTS} -jxf htslib-${HTSLIB_V}.tar.bz2
RUN cd ${BUILD_DIR}/htslib-${HTSLIB_V}; \
    ./configure --prefix=/usr/local && \
    make && \
    make install

# samtools
RUN cd ${BUILD_DIR}; \
    wget https://github.com/samtools/samtools/releases/download/${SAMTOOLS_V}/samtools-${SAMTOOLS_V}.tar.bz2 && \
    tar ${TAROPTS} -jxf samtools-${SAMTOOLS_V}.tar.bz2
RUN cd ${BUILD_DIR}/samtools-${SAMTOOLS_V}; \
    ./configure --prefix=/usr/local --with-htslib=/usr/local/lib && \
    make && \
    make install

# bedtools2
RUN cd ${BUILD_DIR}; \
    wget https://github.com/arq5x/bedtools2/releases/download/v${BEDTOOLS_V}/bedtools-${BEDTOOLS_V}.tar.gz && \
    tar ${TAROPTS} -xzf ${BUILD_DIR}/bedtools-${BEDTOOLS_V}.tar.gz && \
    cd ${BUILD_DIR}/bedtools2 && \
    make install prefix="" DESTDIR=/usr/local

# BWA
RUN cd ${BUILD_DIR}; \
    wget -O bwa-${BWA_V}.tar.gz https://github.com/lh3/bwa/archive/refs/tags/v${BWA_V}.tar.gz && \
    tar ${TAROPTS} -xf ${BUILD_DIR}/bwa-${BWA_V}.tar.gz && \
    cd bwa-${BWA_V} && \
    make && \
    cp -p bwa /usr/local/bin

# BWA-mem2
RUN cd ${BUILD_DIR}; \
    wget https://github.com/bwa-mem2/bwa-mem2/releases/download/v${BWAMEM_V}/bwa-mem2-${BWAMEM_V}_x64-linux.tar.bz2 && \
    tar ${TAROPTS} -jxf ${BUILD_DIR}/bwa-mem2-${BWAMEM_V}_x64-linux.tar.bz2 && \
    cp -p bwa-mem2-${BWAMEM_V}_x64-linux/bwa-mem2* /usr/local/bin

# STAR
RUN cd ${BUILD_DIR}; \
    wget -O STAR-${STAR_V}.tar.gz https://github.com/alexdobin/STAR/archive/${STAR_V}.tar.gz && \
    tar ${TAROPTS} -xzf ${BUILD_DIR}/STAR-${STAR_V}.tar.gz && \
    cp -p STAR-${STAR_V}/bin/Linux_x86_64_static/* /usr/local/bin

# Bowtie 2
RUN cd ${BUILD_DIR}; \
    wget -O bowtie2-${BOWTIE2_V}.zip "https://sourceforge.net/projects/bowtie-bio/files/bowtie2/${BOWTIE2_V}/bowtie2-${BOWTIE2_V}-linux-x86_64.zip/download" && \
    unzip bowtie2-${BOWTIE2_V}.zip && \
    cp -p bowtie2-${BOWTIE2_V}-linux-x86_64/bowtie2* /usr/local/bin

# UCSC Tools
# Newer versions won't run on Rocky8: glibc is tool old.
# Salmon won't build on Rocky 9 (glibc too new!).
RUN cd /usr/local/bin; \
    wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64.v385/bedGraphToBigWig; \
    wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64.v385/bedSort; \
    chmod a+rx bedGraphToBigWig bedSort

# Picard
RUN cd /usr/local/lib; \
    wget -O picard.jar https://github.com/broadinstitute/picard/releases/download/${PICARD_V}/picard.jar


## Clean up
RUN cd / && rm -rf ${BUILD_DIR}
