FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y sudo curl git \
 && rm -rf /var/lib/apt/lists/*

# Create a test user with passwordless sudo to mimic laptop usage
RUN useradd -m -s /bin/bash tester \
 && echo "tester ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tester

USER tester
WORKDIR /home/tester

COPY --chown=tester:tester . /home/tester/ws-setup/
WORKDIR /home/tester/ws-setup

CMD ["./tests/test.sh"]
