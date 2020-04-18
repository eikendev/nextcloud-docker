IMAGE := nextcloud

.PHONY: build
build:
	podman build \
		-t \
		local/${IMAGE} .

.PHONY: run
run:
	podman run \
		-ti \
		-v ./volume/config:/volume/config \
		-v ./volume/custom_apps:/volume/custom_apps \
		-v ./volume/data:/volume/data \
		-v ./volume/themes:/volume/themes \
		-p 9000:8080 \
		--rm \
		--security-opt label=disable \
		--name=${IMAGE} \
		local/${IMAGE}
