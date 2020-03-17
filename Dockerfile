FROM alpine:3.11 as builder

RUN apk add --no-cache \
	git \
	build-base \
	gperf \
	autoconf \
	flex \
	bison \
	zlib-dev \
	bzip2-dev \
	readline-dev

WORKDIR /work

#download sources
RUN git clone --branch v10-branch https://github.com/steveicarus/iverilog.git
RUN wget https://github.com/myhdl/myhdl/archive/0.11.tar.gz && tar xzvf 0.11.tar.gz && rm 0.11.tar.gz

#build icarus
RUN cd iverilog && sh autoconf.sh && ./configure && make -j4 && make install DESTDIR=/work/install

#install for myhdl build
RUN cd iverilog && make install

#build myhdl cosim
RUN cd myhdl-0.11/cosimulation/icarus && make

FROM alpine:3.11

RUN apk add --no-cache \
        python3 \
        py3-pip \
        zlib \
        bzip2 \
        readline \
	libgcc \
	libstdc++

COPY --from=builder /work/install .
COPY --from=builder /work/myhdl-0.11 /myhdl
RUN pip3 install -e /myhdl
RUN ln -s /myhdl/cosimulation/icarus/myhdl.vpi /usr/local/lib/ivl/myhdl.vpi
RUN pip3 install pytest-xdist

RUN adduser --disabled-password user
USER user
WORKDIR /home/user
