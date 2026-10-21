.PHONY: install stow unstow restow

install:
	bash install.sh

stow:
	# pre-create ~/.claude so stow links only .claude/mods instead of folding the whole dir into a symlink
	mkdir -p ~/.claude
	stow -t ~ .

unstow:
	stow -D -t ~ .

restow:
	mkdir -p ~/.claude
	stow -R -t ~ .
