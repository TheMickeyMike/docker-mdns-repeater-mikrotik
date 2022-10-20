container_name := mdns-repeater

default: container/arm64
all: container/arm64 container/arm-v6
clean:
	rm -f *.tar

container/%:
	docker buildx build --network host --no-cache --platform linux/$(subst -,/,$*) -t $(container_name) .
	docker save $(container_name) -o $(container_name)-$*.tar
