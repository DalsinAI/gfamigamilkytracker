# Host tests: make test
CC ?= cc
test:
	sh test-part.sh
	$(CC) -Wall -Werror -I../compat -o /tmp/amiga_path_test amiga_path_test.c ../compat/amiga_path.c
	/tmp/amiga_path_test
.PHONY: test
