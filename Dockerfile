# SPDX-License-Identifier: GPL-2.0-only
# kaiHEN's binaries, built in the Switch 2 devkit's image.
#   docker build --output out .
#     ->  out/ro/main, out/hen/main, out/bootstrap.bin, out/libkaihen/
#   docker build --target build -t kaihen-build .   (the build environment)
# DEVKIT_IMAGE is the devkit's image: build it from the devkit repository, tagged
# ounce-devkit, or name another with --build-arg DEVKIT_IMAGE=...
ARG DEVKIT_IMAGE=ounce-devkit:latest
FROM ${DEVKIT_IMAGE} AS build
COPY . /src
WORKDIR /src
RUN make -j"$(nproc)" \
    && mkdir -p /out/ro /out/hen /out/libkaihen \
    && cp ro/build/main /out/ro/main \
    && cp hen/build/main /out/hen/main \
    && cp bootstrap/build/bootstrap.bin /out/bootstrap.bin \
    && cp libkaihen/build/kaihen-jit.o libkaihen/build/libkaihen.a \
          libkaihen/build/libkaihen_plugin.a /out/libkaihen/

FROM scratch
COPY --from=build /out/ /
