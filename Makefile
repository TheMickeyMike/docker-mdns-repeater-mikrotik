container_name := mdns-repeater
repo_name := mag1024/mikrotik-docker-mdns-repeater

default: container/arm64
all: container/arm64 container/arm-v6
clean:
	rm -f *.tar

container/%:
	docker buildx build --load --platform linux/$(subst -,/,$*) -t $(container_name) .
	docker save $(container_name) -o $(container_name)-$*.tar

push:
	docker buildx build --platform linux/arm64,linux/arm/v6 --push github.com/$(repo_name) -t $(repo_name):latest
