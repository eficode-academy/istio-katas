IMAGE ?= michaelvl/jwt
VERSION ?= v1

.PHONY: build
build:
	docker build -t $(IMAGE):$(VERSION) .

.PHONY: push
push:
	docker push $(IMAGE):$(VERSION)

.PHONY: jwt
jwt:
	docker run --user $(shell id -u):$(shell id -g) --rm -v $(PWD):/work:rw $(IMAGE):$(VERSION)

.PHONY: show-jwts
show-jwts:
	cat user1.jwt | cut -d '.' -f 2  | base64 -d
	-echo ""
	cat user2.jwt | cut -d '.' -f 2  | base64 -d
	-echo ""
	cat admin1.jwt | cut -d '.' -f 2 | base64 -d
	-echo ""
