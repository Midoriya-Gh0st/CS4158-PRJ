all: clean parse

parse: parse.l parse.y
	bison -d parse.y
	flex parse.l
	gcc -o $@ parse.tab.c lex.yy.c -lm
	./parse < invalid.jibuc > testout.txt

clean:
	clear
	rm -f parse \
	lex.yy.c parse.tab.c parse.tab.h