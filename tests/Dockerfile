FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
COPY packages/base.txt /tmp/base.txt
RUN printf 'path-include=/usr/share/doc/fzf/examples/*\n' > /etc/dpkg/dpkg.cfg.d/ws-test-fzf \
 && apt-get update \
 && apt-get install -y sudo $(sed '/^#/d; /^$/d' /tmp/base.txt) \
 && useradd --create-home --uid 1001 --shell /bin/bash tester \
 && printf 'tester ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/tester \
 && chmod 0440 /etc/sudoers.d/tester \
 && rm -rf /var/lib/apt/lists/*
USER tester
WORKDIR /work
ENV PATH="/home/tester/.local/bin:${PATH}"
CMD ["bash", "tests/test.sh"]
