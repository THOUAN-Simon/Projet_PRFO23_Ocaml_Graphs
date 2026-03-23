.PHONY: all clean

TARGET = main
TEST = test_base

all: priority.cmo analyse.cmo base.cmo 
	ocamlc $^ -o main

test: test_base.cmo
	ocamlc $^ -o test

%.cmi: %.mli
	ocamlc -c $< -o $@

%.cmo: %.ml
	ocamlc -c $< -o $@

clean:
	rm -fv *~ *.cm[io] $(TARGET)

main : priority.cmi analyse.cmi base.cmi 
base.cmo: base.cmi priority.cmi
analyse.cmo: analyse.cmi
priority.cmo: priority.cmi
test_base.cmo: base.cmi