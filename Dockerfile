FROM debian:stretch-slim

ARG DEBIAN_FRONTEND=noninteractive

COPY clean-apt /usr/bin
COPY Gemfile /Gemfile

# 1. Install & configure dependencies.
# 2. Install fluentd via ruby.
# 3. Remove build dependencies.
# 4. Cleanup leftover caches & files.
RUN BUILD_DEPS="make gcc g++ libc6-dev ruby-dev libffi-dev" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
                     $BUILD_DEPS \
                     ca-certificates \
                     libjemalloc1 \
                     ruby && \
    echo 'gem: --no-document' >> /etc/gemrc && \
    gem install --file Gemfile && \
    apt-get purge -y --auto-remove \
                     -o APT::AutoRemove::RecommendsImportant=false \
                     $BUILD_DEPS && \
    clean-apt && \

# Copy the Fluentd configuration file for logging Docker container logs.
COPY fluent.conf /etc/fluent/fluent.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Expose prometheus metrics.
EXPOSE 80

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

# Start Fluentd to pick up our config that watches Docker container logs.
CMD /docker-entrypoint.sh $FLUENTD_ARGS