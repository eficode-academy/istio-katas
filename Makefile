.PHONY: all exercises

exercisemdpp := $(wildcard mdpp/*.mdpp)
exercisemd := $(exercisemdpp:mdpp/%.mdpp=%.md)

all: exercises

exercises: $(exercisemd)

%.md : mdpp/%.mdpp
	docker run --rm -it --user $(shell id -u):$(shell id -g) -v $(shell pwd):/work michaelvl/markdown-pp $< -o $@
	chmod u-w $@
