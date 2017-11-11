# @(#)[:uvS>DT2{l?2;*(+$y0)-: 2017-11-11 18:02:13 Z tw@csongor]
# vim: ft=make nowrap

TARGET  = completions.ksh
OBJECTS = git_1 scp ssh rcctl_2
DEPENDS = chflags kill_1 rcctl_1 xfontsel
GIT_IGN = .gitignore

.poison empty OS_VER

all: $(TARGET)

clean:
	rm -f $(TARGET)
	rm -f $(OBJECTS)

$(TARGET): $(OBJECTS) $(DEPENDS)
	@echo $@
	@printf '# vim: ft=ksh ts=4 nowrap\n\n'   >$@
.for f in $(OBJECTS) $(DEPENDS)
	@printf 'set -A complete_$f -- '             >>$@
	@sort <$f >tmp.sort
	@tr '\n' ' ' <tmp.sort >tmp.tr
	@sed -e 's/ $$//' <tmp.tr                    >>$@
	@printf '\n'                                 >>$@
	@rm tmp.sort tmp.tr
.endfor
	@echo '.*'  >$(GIT_IGN)
	@echo $@   >>$(GIT_IGN)
.for f in $(OBJECTS)
	@echo $f   >>$(GIT_IGN)
.endfor

GIT_CONFIG=/home/tw/.config/git/config
GIT_ALIAS_PGM='/\[alias\]/ {p=1} p && /\[[a-z]/ {exit} p && / = / {print $$1}'
git_1: $(GIT_CONFIG)
	@echo $@
	@: >$@
	@git --help |awk '/^   [a-z]/ {print $$1}'>>$@
	@awk $(GIT_ALIAS_PGM) $(GIT_CONFIG) >>$@

SSH_HOSTS=$(XDG_CONFIG_HOME)/ssh/known_hosts
ssh: $(SSH_HOSTS)
	@echo $@
	@awk '{print $$1}' $(SSH_HOSTS) >tmp.awk
	@tr , '\n' <tmp.awk >tmp.tr
	@awk '/^[a-z]+(\.[a-z]+)?$$/' tmp.tr >$@
	@rm tmp.awk tmp.tr

scp: ssh
	@echo $@
	@ln -fs ssh scp

PKG_LOG = $(HOME)/hold/$(OS_VER)/pkg.log
rcctl_2: $(PKG_LOG)
	@echo $@
	@/bin/ls -1 /etc/rc.d >$@

$(PKG_LOG):
	@echo $@
	@touch $(PKG_LOG)

.PHONY: all clean
