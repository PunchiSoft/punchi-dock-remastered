# syntax=docker/dockerfile:1

FROM debian:13 AS toolchain

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash punchi-builder \
    && printf 'punchi-builder ALL=(root) NOPASSWD: /usr/bin/apt-get\n' \
        > /etc/sudoers.d/punchi-builder-apt \
    && chmod 0440 /etc/sudoers.d/punchi-builder-apt

WORKDIR /workspace
COPY --chown=punchi-builder:punchi-builder scripts-user/ ./scripts-user/
COPY --chown=punchi-builder:punchi-builder scripts-dev/ ./scripts-dev/

USER punchi-builder
RUN ./scripts-dev/distro/debian13-setup.sh --yes --dependencies-only
COPY --chown=punchi-builder:punchi-builder containers/debian13/dist.keep /workspace/dist/.keep

ENV XDG_MENU_PREFIX=plasma-
RUN kbuildsycoca6 --noincremental

COPY --chown=punchi-builder:punchi-builder . .

FROM toolchain AS test

RUN ./scripts-dev/distro/debian13-package.sh

CMD ["/bin/bash"]

FROM scratch AS artifact

COPY --from=test /workspace/dist/*.plasmoid /
