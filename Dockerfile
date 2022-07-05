FROM alpine AS builder
ARG MDNS_REPEATER_VERSION=local
ADD mdns-repeater.c mdns-repeater.c
RUN set -ex && \
    apk add build-base && \
    gcc -o /bin/mdns-repeater mdns-repeater.c -DMDNS_REPEATER_VERSION=\"${MDNS_REPEATER_VERSION}\"

FROM alpine

RUN set -ex && \
    apk add vlan libcap bash
COPY --from=builder /bin/mdns-repeater /bin/mdns-repeater
RUN chmod +x /bin/mdns-repeater
RUN setcap cap_net_raw=+ep /bin/mdns-repeater

COPY run.sh /app/
RUN chmod +x /app/run.sh

ENTRYPOINT ["/app/run.sh"]
CMD ["/bin/mdns-repeater", "-f", "eth0.20", "eth0.100"]
