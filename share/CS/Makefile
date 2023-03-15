# <@(#)tag:csongor.greyshirt.net,2017-11-11:tw/18.02.13z/29dd912>
# vim: ft=make nowrap

TARGET      = completions.ksh
# things make builds (don't git)
GENERATE   != sed -E -e '/^\#/d' $(.CURDIR)/GENERATE
# things hand crafted (git them)
SHARED     != sed -E -e '/^\#/d' $(.CURDIR)/SHARED

GIT_IGN     = .gitignore

# ========================================================================
# === DON'T DO ANYTHING IN SOME CASES ====================================
# ========================================================================
LINKFROM    = $(KDOTDIR)/share/CS
FORHOST     = $(.CURDIR:H:T)
################################################### IF ##########
.if $(FORHOST) == share
all clean $(TARGET) $(GENERATE) $(SHARED):
	@echo '  Attempted to run in /share/'

.PHONY: all clean
################################################### ELIF ########
.elif $(HOST) != $(FORHOST)
all $(TARGET) $(GENERATE) $(SHARED):
	@echo '  Attempted to run on the wrong host'
	@echo '  <$(HOST)> is not <$(FORHOST)>'

clean:
	@echo '  <$(HOST)> is not <$(FORHOST)>'
	@echo '  try: make forceclean'

forceclean:
	rm -f $(TARGET)
	rm -f $(GENERATE)
	rm -f $(SHARED)

.PHONY: all clean forceclean
################################################### ELSE ########
.else
# ========================================================================

.poison empty OSREV
.poison empty KDOTDIR
.poison empty XDG_CONFIG_HOME

all: $(TARGET)


clean:
	rm -f $(TARGET)
	rm -f $(GENERATE)
	rm -f $(SHARED)

$(SHARED):
	@echo $@
	@ln -fs $(LINKFROM)/$@ $@

$(TARGET): $(GENERATE) $(SHARED) Makefile
	@printf '# vim: ft=ksh ts=4 nowrap\n\n'      >$@
	@echo '.gitignore'  >$(GIT_IGN)
.for f in $(GENERATE) $(SHARED)
	@printf 'set -A complete_$f -- '             >>$@
	@sort <$f >tmp.sort
	@tr '\n' ' ' <tmp.sort >tmp.tr
	@sed -e 's/ $$//' <tmp.tr                    >>$@
	@printf '\n'                                 >>$@
	@rm tmp.sort tmp.tr
	@echo $f           >>$(GIT_IGN)
.endfor
	@echo $@           >>$(GIT_IGN)
	@echo make.out     >>$(GIT_IGN)

CABAL_AWK  = /^Commands:$$/ {p=1;next}
CABAL_AWK += p && /^[^[:space:]]/ {exit}
CABAL_AWK += p && $$1 ~ /^[a-z]/ {print $$1}
cabal_1:
	@echo $@
	@cabal --help |awk '$(CABAL_AWK)' >$@

CARGO_AWK  = $$1 == "Installed" {next} $$1 ~ /../ {print $$1}
cargo_1:
	@echo $@
	@cargo --list | awk '$(CARGO_AWK)' >$@

ELM_AWK    = /^    elm [^[:space:]]+[[:space:]]+--help$$/ {print $$2}
elm_1:
	@echo $@
	@elm --help 2>&1|awk '$(ELM_AWK)' >$@

GIT_CONFIG=/home/tw/config/git/config
git_1: $(GIT_CONFIG)
	@echo $@
	@git help --all |awk '/^   [a-z-]+ / {print $$1}' >$@

got_1:
	@echo $@
	@got -h 2>&1|awk -F': ' '/^commands: / {gsub(" ","\n",$$2);print $$2}' >$@

HELP_UPBIN=$(KDOTDIR)/share/BS/update-help-completions.ksh
HELP_FCHG=$(KDOTDIR)/share/FS/.LAST_UPDATED
HELP_HCHG=$(KDOTDIR)/share/HS/.LAST_UPDATED
help: $(HELP_FCHG) $(HELP_HCHG)
	@$(HELP_UPBIN)

PKG_LOG = $(HOME)/hold/$(OSREV)/pkg.log
MAN_CONF = /etc/man.conf
LIST_MAN_PAGES = $(KDOTDIR)/share/BS/list-man-pages.ksh
man: $(PKG_LOG) $(MAN_CONF)
	@echo $@
	@$(LIST_MAN_PAGES) >$@

MAIL_ACCT_DIR=$(XDG_CONFIG_HOME)/fetchmail
MAIL_ACCOUNTS=$(MAIL_ACCT_DIR)/accounts
m_2: $(MAIL_ACCOUNTS)
	@echo $@
	@$(MAIL_ACCT_DIR)/listAccts.ksh -r | sort >$@

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

rcctl_2: $(PKG_LOG)
	@echo $@
	@/bin/ls -1 /etc/rc.d >$@

ts:
	@echo $@
	@tree-sitter -h >tmp.tree-sitter
	@awk '/^SUBCOMMANDS:/ {p=1;next} p {print $$1}' tmp.tree-sitter >$@
	@rm tmp.tree-sitter

vmgr_1:
	@echo $@
	@vmgr cmdlist >$@

$(PKG_LOG):
	@echo $@
	@mkdir -p $(PKG_LOG:H)
	@touch $(PKG_LOG)

.PHONY: all clean
# ========================================================================
.endif # WHOLE FILE
