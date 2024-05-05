FROM ubuntu:22.04 AS base
ARG NINJA_VERSION=1.12.0
ARG NINJA_FILENAME=ninja-linux.zip

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y wget \
	lsb-release \
	curl \
	software-properties-common \
	gnupg \
	unzip \
	git \
	build-essential


FROM base AS llvm
ARG LLVM_VERSION=18

RUN wget https://apt.llvm.org/llvm.sh && \
	chmod +x llvm.sh && \
	./llvm.sh $LLVM_VERSION all && \
	ln -s $(which clang-${LLVM_VERSION}) /usr/bin/clang && \
	ln -s $(which clang++-${LLVM_VERSION}) /usr/bin/clang++ && \
	ln -s $(which clang-tidy-${LLVM_VERSION}) /usr/bin/clang-tidy && \
	ln -s $(which clang-format-${LLVM_VERSION}) /usr/bin/clang-format && \
	rm llvm.sh

FROM base AS cmake

RUN apt clean all &&\
	apt remove --purge --auto-remove cmake && \
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
	gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
	gpg --dearmor - | \
	tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
	apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" && \
	apt update  && \
	apt install kitware-archive-keyring && \
	rm /etc/apt/trusted.gpg.d/kitware.gpg && \
	apt update && \
	apt install -y cmake cmake-data cmake-extras extra-cmake-modules

FROM base AS vulkan

RUN wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | \
	tee /etc/apt/trusted.gpg.d/lunarg.asc && \
	wget -qO /etc/apt/sources.list.d/lunarg-vulkan-1.3.280-jammy.list https://packages.lunarg.com/vulkan/1.3.280/lunarg-vulkan-1.3.280-jammy.list && \
	apt update && \
	apt install -y vulkan-sdk xorg-dev

FROM base AS final

RUN curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh && \
	bash nodesource_setup.sh && \
	apt install -y nodejs

RUN apt install -y \
	sudo \
	libx11-dev \
	zlib1g-dev \
	libxext-dev \
	libboost-all-dev

RUN wget https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/${NINJA_FILENAME} && \
	unzip ${NINJA_FILENAME} && \
	mv ninja /usr/bin/ninja && \
	chmod +x /usr/bin/ninja

COPY --from=llvm /usr/bin/*clang* /usr/bin/
COPY --from=llvm /usr/bin/llvm* /usr/bin/
COPY --from=llvm /usr/bin/lldb* /usr/bin/
COPY --from=llvm /usr/include/llvm* /usr/include/
COPY --from=llvm /usr/include/clang* /usr/include/
COPY --from=llvm /usr/lib/cmake/clang* /usr/lib/cmake
COPY --from=llvm /usr/lib/clang /usr/lib/
COPY --from=llvm /usr/lib/llvm* /usr/lib/
COPY --from=llvm /usr/share/clang* /usr/share/

COPY --from=cmake /usr/bin/cmake /usr/bin/
COPY --from=cmake /usr/bin/cpack /usr/bin/
COPY --from=cmake /usr/bin/ctest /usr/bin/
COPY --from=cmake /usr/share/cmake* /usr/share/
COPY --from=cmake /usr/share/ECM /usr/share/

COPY --from=vulkan \
	/usr/bin/dxc \
	/usr/bin/dxc* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/gfx* \
	/usr/bin/glsl* \
	/usr/bin/spirv* \
	/usr/bin/vk* \
	/usr/bin/vulkan* \
	\
	/usr/bin/

COPY --from=vulkan \
	/usr/include/glslang \
	/usr/include/shaderc \
	/usr/include/spirv* \
	/usr/include/vk* \
	/usr/include/volk* \
	/usr/include/vulkan \
	\
	/usr/include/

COPY --from=vulkan \
	/usr/lib/dxc \
	\
	/usr/lib/

COPY --from=vulkan \
	/usr/lib/x86_64-linux-gnu/cmake/SPIRV* \
	/usr/lib/x86_64-linux-gnu/cmake/Vulkan* \
	/usr/lib/x86_64-linux-gnu/cmake/glslang \
	/usr/lib/x86_64-linux-gnu/cmake/volk \
	\
	/usr/lib/x86_64-linux-gnu/cmake/

COPY --from=vulkan \
	/usr/lib/x86_64-linux-gnu/libGenericCodeGen.a \
	/usr/lib/x86_64-linux-gnu/libMachineIndependent.a \
	/usr/lib/x86_64-linux-gnu/libOSDependent.a \
	/usr/lib/x86_64-linux-gnu/libSPIRV* \
	/usr/lib/x86_64-linux-gnu/libSPVRemapper.a \
	/usr/lib/x86_64-linux-gnu/libVkLayer* \
	/usr/lib/x86_64-linux-gnu/libVulkan* \
	/usr/lib/x86_64-linux-gnu/libglsl* \
	/usr/lib/x86_64-linux-gnu/libshaderc* \
	/usr/lib/x86_64-linux-gnu/libspirv* \
	/usr/lib/x86_64-linux-gnu/libvulkan* \
	\
	/usr/lib/x86_64-linux-gnu/

COPY --from=vulkan \
	/usr/lib/x86_64-linux-gnu/pkgconfig/SPIRV* \
	/usr/lib/x86_64-linux-gnu/pkgconfig/shaderc* \
	/usr/lib/x86_64-linux-gnu/pkgconfig/vulkan* \
	\
	/usr/lib/x86_64-linux-gnu/pkgconfig/

COPY --from=vulkan \
	/usr/share/cmake/SPIRV* \
	/usr/share/cmake/Vulkan* \
	\
	/usr/share/cmake/

COPY --from=vulkan \
	/usr/share/pkgconfig/SPIRV* \
	\
	/usr/share/pkgconfig/

COPY --from=vulkan \
	/usr/share/spirv_cross* \
	/usr/share/vulkan \
	\
	/usr/share/

COPY --from=vulkan /usr/include/GL /usr/include/GL
COPY --from=vulkan /usr/include/X11 /usr/include/X11
COPY --from=vulkan \
	/usr/lib/x86_64-linux-gnu/libFS.a \
	/usr/lib/x86_64-linux-gnu/libFS.so \
	/usr/lib/x86_64-linux-gnu/libICE.a \
	/usr/lib/x86_64-linux-gnu/libICE.so \
	/usr/lib/x86_64-linux-gnu/libSM.a \
	/usr/lib/x86_64-linux-gnu/libSM.so \
	/usr/lib/x86_64-linux-gnu/libX11.a \
	/usr/lib/x86_64-linux-gnu/libX11.so \
	/usr/lib/x86_64-linux-gnu/libXRes.a \
	/usr/lib/x86_64-linux-gnu/libXRes.so \
	/usr/lib/x86_64-linux-gnu/libXau.a \
	/usr/lib/x86_64-linux-gnu/libXau.so \
	/usr/lib/x86_64-linux-gnu/libXaw.so \
	/usr/lib/x86_64-linux-gnu/libXaw7.a \
	/usr/lib/x86_64-linux-gnu/libXaw7.so \
	/usr/lib/x86_64-linux-gnu/libXcomposite.a \
	/usr/lib/x86_64-linux-gnu/libXcomposite.so \
	/usr/lib/x86_64-linux-gnu/libXcursor.a \
	/usr/lib/x86_64-linux-gnu/libXcursor.so \
	/usr/lib/x86_64-linux-gnu/libXdamage.a \
	/usr/lib/x86_64-linux-gnu/libXdamage.so \
	/usr/lib/x86_64-linux-gnu/libXdmcp.a \
	/usr/lib/x86_64-linux-gnu/libXdmcp.so \
	/usr/lib/x86_64-linux-gnu/libXext.a \
	/usr/lib/x86_64-linux-gnu/libXext.so \
	/usr/lib/x86_64-linux-gnu/libXfixes.a \
	/usr/lib/x86_64-linux-gnu/libXfixes.so \
	/usr/lib/x86_64-linux-gnu/libXfont2.a \
	/usr/lib/x86_64-linux-gnu/libXfont2.so \
	/usr/lib/x86_64-linux-gnu/libXft.a \
	/usr/lib/x86_64-linux-gnu/libXft.so \
	/usr/lib/x86_64-linux-gnu/libXi.a \
	/usr/lib/x86_64-linux-gnu/libXi.so \
	/usr/lib/x86_64-linux-gnu/libXinerama.a \
	/usr/lib/x86_64-linux-gnu/libXinerama.so \
	/usr/lib/x86_64-linux-gnu/libXmu.a \
	/usr/lib/x86_64-linux-gnu/libXmu.so \
	/usr/lib/x86_64-linux-gnu/libXmuu.a \
	/usr/lib/x86_64-linux-gnu/libXmuu.so \
	/usr/lib/x86_64-linux-gnu/libXpm.a \
	/usr/lib/x86_64-linux-gnu/libXpm.so \
	/usr/lib/x86_64-linux-gnu/libXrandr.a \
	/usr/lib/x86_64-linux-gnu/libXrandr.so \
	/usr/lib/x86_64-linux-gnu/libXrender.a \
	/usr/lib/x86_64-linux-gnu/libXrender.so \
	/usr/lib/x86_64-linux-gnu/libXss.a \
	/usr/lib/x86_64-linux-gnu/libXss.so \
	/usr/lib/x86_64-linux-gnu/libXt.a \
	/usr/lib/x86_64-linux-gnu/libXt.so \
	/usr/lib/x86_64-linux-gnu/libXtst.a \
	/usr/lib/x86_64-linux-gnu/libXtst.so \
	/usr/lib/x86_64-linux-gnu/libXv.a \
	/usr/lib/x86_64-linux-gnu/libXv.so \
	/usr/lib/x86_64-linux-gnu/libXvMC.a \
	/usr/lib/x86_64-linux-gnu/libXvMC.so \
	/usr/lib/x86_64-linux-gnu/libXvMCW.a \
	/usr/lib/x86_64-linux-gnu/libXvMCW.so \
	/usr/lib/x86_64-linux-gnu/libXxf86dga.a \
	/usr/lib/x86_64-linux-gnu/libXxf86dga.so \
	/usr/lib/x86_64-linux-gnu/libXxf86vm.a \
	/usr/lib/x86_64-linux-gnu/libXxf86vm.so \
	/usr/lib/x86_64-linux-gnu/libdmx.a \
	/usr/lib/x86_64-linux-gnu/libdmx.so \
	/usr/lib/x86_64-linux-gnu/libfontenc.a \
	/usr/lib/x86_64-linux-gnu/libfontenc.so \
	/usr/lib/x86_64-linux-gnu/libxkbfile.a \
	/usr/lib/x86_64-linux-gnu/libxkbfile.so \
	\
	/usr/lib/x86_64-linux-gnu/
#DEST is last element


COPY --from=vulkan \
	/usr/lib/x86_64-linux-gnu/pkgconfig/dmx.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/fontenc.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/ice.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/libfs.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/sm.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/x11.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xau.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xaw7.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xcomposite.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xcursor.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xdamage.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xdmcp.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xext.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xfixes.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xfont2.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xft.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xi.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xinerama.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xkbfile.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xmu.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xmuu.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xpm.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xrandr.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xrender.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xres.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xscrnsaver.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xt.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xtst.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xv.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xvmc-wrapper.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xvmc.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xxf86dga.pc \
	/usr/lib/x86_64-linux-gnu/pkgconfig/xxf86vm.pc \
	\
	/usr/lib/x86_64-linux-gnu/pkgconfig/

COPY --from=vulkan /usr/share/lintian /usr/share/

COPY --from=vulkan \
	/usr/share/pkgconfig/applewmproto.pc \
	/usr/share/pkgconfig/bigreqsproto.pc \
	/usr/share/pkgconfig/compositeproto.pc \
	/usr/share/pkgconfig/damageproto.pc \
	/usr/share/pkgconfig/dmxproto.pc \
	/usr/share/pkgconfig/dpmsproto.pc \
	/usr/share/pkgconfig/dri2proto.pc \
	/usr/share/pkgconfig/dri3proto.pc \
	/usr/share/pkgconfig/fixesproto.pc \
	/usr/share/pkgconfig/fontsproto.pc \
	/usr/share/pkgconfig/glproto.pc \
	/usr/share/pkgconfig/inputproto.pc \
	/usr/share/pkgconfig/kbproto.pc \
	/usr/share/pkgconfig/presentproto.pc \
	/usr/share/pkgconfig/randrproto.pc \
	/usr/share/pkgconfig/recordproto.pc \
	/usr/share/pkgconfig/renderproto.pc \
	/usr/share/pkgconfig/resourceproto.pc \
	/usr/share/pkgconfig/scrnsaverproto.pc \
	/usr/share/pkgconfig/videoproto.pc \
	/usr/share/pkgconfig/xcmiscproto.pc \
	/usr/share/pkgconfig/xextproto.pc \
	/usr/share/pkgconfig/xf86bigfontproto.pc \
	/usr/share/pkgconfig/xf86dgaproto.pc \
	/usr/share/pkgconfig/xf86driproto.pc \
	/usr/share/pkgconfig/xf86vidmodeproto.pc \
	/usr/share/pkgconfig/xineramaproto.pc \
	/usr/share/pkgconfig/xproto.pc \
	\
	/usr/share/pkgconfig/
