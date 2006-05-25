HCFLAGS = -O

.PHONY : all prof clean exposed

all:
	ghc $(HCFLAGS) -o exi -hide-package portage --make Main.hs

prof:
	ghc $(HCFLAGS) -prof -o exi.p -hide-package portage --make -auto-all Main.hs

clean:
	rm *.o *.hi
	find Portage \( -name '*.o' -o -name '*.hi' \) -exec rm '{}' \;

exposed:
	find Portage -name '*.hs' | sed -e 's|/|.|g' -e 's|.hs$$|,|' -e 's/^/\t\t\t/'
