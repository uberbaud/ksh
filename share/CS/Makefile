# <@(#)tag:csongor.greyshirt.net,2017-11-11:tw/18.02.13z/29dd912>
# vim: ft=make nowrap

TARGET      = completions.ksh
# things make builds (don't git)
OBJECTS     = git_1 help scp ssh rcctl_2 sysctl
# things hand crafted (git them)
DEPENDS     = chflags fossil_1 inc kill_1 mediainfo mget perlbrew pkg_1
DEPENDS    += poco rcctl_1 sndioctl xfontsel xinput_1 xinput_2
GIT_IGN     = .gitignore

.poison empty OSREV
.poison empty KDOTDIR
.poison empty XDG_CONFIG_HOME

all: $(TARGET)

clean:
	rm -f $(TARGET)
	rm -f $(OBJECTS)

$(TARGET): $(OBJECTS) $(DEPENDS)
	@printf '# vim: ft=ksh ts=4 nowrap\n\n'      >$@
.for f in $(OBJECTS) $(DEPENDS)
	@printf 'set -A complete_$f -- '             >>$@
	@sort <$f >tmp.sort
	@tr '\n' ' ' <tmp.sort >tmp.tr
	@sed -e 's/ $$//' <tmp.tr                    >>$@
	@printf '\n'                                 >>$@
	@rm tmp.sort tmp.tr
.endfor
	@echo '.*'       >$(GIT_IGN)
	@echo $@        >>$(GIT_IGN)
	@echo make.out  >>$(GIT_IGN)
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

HELP_UPBIN=$(KDOTDIR)/share/BS/update-help-completions.ksh
HELP_FCHG=$(KDOTDIR)/share/FS/.LAST_UPDATED
HELP_HCHG=$(KDOTDIR)/share/HS/.LAST_UPDATED
help: $(HELP_FCHG) $(HELP_HCHG)
	@$(HELP_UPBIN)

MAIL_ACCT_DIR=$(XDG_CONFIG_HOME)/fetchmail
MAIL_ACCOUNTS=$(MAIL_ACCT_DIR)/accounts
mget: $(MAIL_ACCOUNTS)
	@echo $@
	@$(MAIL_ACCT_DIR)/listAccts.ksh -r >$@

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

sysctl:
	@echo $@
	@sysctl >tmp.sysctl
	@awk -F= '/^[^ \t]/ {print $$1}' tmp.sysctl >$@
	@rm tmp.sysctl

PKG_LOG = $(HOME)/hold/$(OSREV)/pkg.log
rcctl_2: $(PKG_LOG)
	@echo $@
	@/bin/ls -1 /etc/rc.d >$@

$(PKG_LOG):
	@echo $@
	@mkdir -p $(PKG_LOG:H)
	@touch $(PKG_LOG)

.PHONY: all clean