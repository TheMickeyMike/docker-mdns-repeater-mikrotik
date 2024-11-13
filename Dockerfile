FROM monstrenyatko/mdns-repeater

COPY run.sh /app/
RUN chmod +x /app/run.sh

ENTRYPOINT ["/app/run.sh"]
