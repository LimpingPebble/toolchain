FROM ubuntu:22.04
ARG LLVM_VERSION=18
ARG NINJA_VERSION=1.12.0
ARG NINJA_FILENAME=ninja-linux.zip

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y wget \
	curl \
	sudo \
	lsb-release \
	software-properties-common \
	gnupg \
	unzip \
	libvulkan-dev \
	git

RUN adduser --disabled-password runner
RUN usermod -aG sudo runner
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN wget https://apt.llvm.org/llvm.sh && \
	chmod +x llvm.sh && \
	./llvm.sh $LLVM_VERSION all && \
	ln -s $(which clang-${LLVM_VERSION}) /usr/bin/clang && \
	ln -s $(which clang++-${LLVM_VERSION}) /usr/bin/clang++ && \
	ln -s $(which clang-tidy-${LLVM_VERSION}) /usr/bin/clang-tidy && \
	ln -s $(which clang-format-${LLVM_VERSION}) /usr/bin/clang-format && \
	rm llvm.sh

RUN apt clean all &&\
	apt remove --purge --auto-remove cmake && \
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
	gpg --dearmor - | \
	sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
	apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" && \
	apt update  && \
	apt install kitware-archive-keyring && \
	rm /etc/apt/trusted.gpg.d/kitware.gpg && \
	apt update && \
	apt install -y cmake cmake-data cmake-extras extra-cmake-modules

RUN wget https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/${NINJA_FILENAME} && \
	unzip ${NINJA_FILENAME} && \
	mv ninja /usr/bin/ninja && \
	chmod +x /usr/bin/ninja

USER runner
WORKDIR /home/runner
