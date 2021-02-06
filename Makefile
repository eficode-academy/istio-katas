
all: exercises

.PHONY: all exercises

exercisemdpp := $(wildcard mdpp/*.mdpp)
exercisemd := $(exercisemdpp:mdpp/%.mdpp=%.md)

exercises: $(exercisemd)

%.md : mdpp/%.mdpp
	chmod u+w $@
	docker run --rm -it --user $(shell id -u):$(shell id -g) -v $(shell pwd):/work michaelvl/markdown-pp $< -o $@
	chmod u-w $@

-include Makefile.local
