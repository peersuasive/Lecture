-include Makefile.config

all: clean
	@cd embed && make allplats FULL_STATIC=1

-include Makefile.extra

linux:
	@cd embed && make FULL_STATIC=1

ios:
	@cd embed && make XCROSS=ios FULL_STATIC=1

android:
	@cd embed && make XCROSS=android FULL_STATIC=1

osx:
	@cd embed && make XCROSS=osx FULL_STATIC=1

win:
	@cd embed && make XCROSS=win FULL_STATIC=1

clean:
	@cd embed && make extraclean

.PHONY: clean

