
all: exercises

.PHONY: all exercises

exercisemdpp := $(wildcard markdown-source/*.mdpp)
exercisemd := $(exercisemdpp:markdown-source/%.mdpp=%.md)

exercises: $(exercisemd)

# Run markdown sources through a preprocessor to inject source snippets etc.
%.md : markdown-source/%.mdpp
	-chmod u+w $@
	docker run --rm -it --user $(shell id -u):$(shell id -g) -v $(shell pwd):/work michaelvl/markdown-pp $< -o $@
	chmod u-w $@

-include Makefile.local
