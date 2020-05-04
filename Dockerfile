FROM ubuntu:18.04

# Set language. Some packages depend on this.
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

ENV APP_DIR /app


# Enable MANPAGES in ubuntu docker image
RUN sed -i 's:^path-exclude=/usr/share/man:#path-exclude=/usr/share/man:' \
        /etc/dpkg/dpkg.cfg.d/excludes

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y

# Core dependencies. Some packages can fail in odd ways if these are missing
RUN apt-get install -y \
      locales \
      dialog \
      ca-certificates \
      gnupg
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Main application dependencies.
RUN apt-get install -y \
      ruby-full

# Optional debugging or development utilities.
RUN apt-get install -y \
      man \
      manpages-posix \
      curl \
      file \
      less \
      nano \
      tmux \
      iproute2


RUN gem install bundler

# Set the working directory to /app
WORKDIR $APP_DIR


COPY entrypoint.sh entrypoint.sh

# Use array notation for ENTRYPOINT and CMD
ENTRYPOINT [ "./entrypoint.sh" ]
CMD ["./your-application", "--serve"]
