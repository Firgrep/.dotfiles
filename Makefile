.PHONY: stow unstow restow

stow:
	stow -t ~ .

unstow:
	stow -D -t ~ .

restow:
	stow -R -t ~ .
