# <@(#)tag:csongor.greyshirt.net,2017-11-11:tw/18.02.13z/29dd912>
# vim: ft=make nowrap

TARGET      = completions.ksh
# things make builds (don't git)
GENERATE   != sed -E -e '/^\#/d' $(.CURDIR)/GENERATE
# things hand crafted (git them)
SHARED     != sed -E -e '/^\#/d' $(.CURDIR)/SHARED

GIT_IGN     = .gitignore
CARGO_BIN   = $(CARGO_HOME)/bin

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

AS_PATH    = /home/apps
as_1: $(AS_PATH)/last_added
	@echo $@
	@stest -d $(AS_PATH)/* | sed 's|^.*/||' >$@

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

got_1: /usr/local/bin/got
	@echo $@
	@got -h 2>&1|awk -F': ' '/^commands: / {gsub(" ","\n",$$2);print $$2}' >$@

HELP_UPBIN=$(KDOTDIR)/share/BS/update-help-completions.ksh
HELP_FCHG=$(KDOTDIR)/share/FS/.LAST_UPDATED
HELP_HCHG=$(KDOTDIR)/share/HS/.LAST_UPDATED
help: $(HELP_FCHG) $(HELP_HCHG)
	@$(HELP_UPBIN)

jj_1: $(CARGO_BIN)/jj
	@echo $@
	@jj -h | awk 'p && /^$$/ {nextfile} p {print $$1} /^Commands:/ {p=1}' >$@

PKG_LOG = $(HOME)/hold/$(OSREV)/pkg.log
MAN_CONF = /etc/man.conf
LIST_MAN_PAGES = $(KDOTDIR)/share/BS/list-man-pages.ksh
man: $(PKG_LOG) $(MAN_CONF)
	@echo $@
	@$(LIST_MAN_PAGES) >$@

MAIL_ACCT_DIR=$(XDG_CONFIG_HOME)/mail
MAIL_UDATED=$(MAIL_ACCT_DIR)/.LAST_UPDATED
MAIL_BIN=$(KDOTDIR)/share/BS/m-list-accts.ksh
m_2: $(MAIL_UPDATED)
	@echo $@
	@$(MAIL_BIN) -ar >$@

pijul_1: $(CARGO_BIN)/pijul
	@echo $@
	@pijul -h | awk 'p && /^    [a-z]/ {print $$1} /^SUBCOMMANDS:/ {p=1}' >$@

pkgcfg: /usr/bin/pkg-config
	@echo '$@ (pkg-config alias)'
	@pkg-config -h|awk '/^--/ {print $$1}' >$@

PRJ_BIN=$(KDOTDIR)/share/BS/prj.ksh
prj_1: $(PRJ_BIN)
	@echo $@
	@$(PRJ_BIN) -L >$@

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

sysctl: /usr/sbin/sysctl
	@echo $@
	@sysctl >tmp.sysctl
	@awk -F= '/^[^ \t]/ {print $$1}' tmp.sysctl >$@
	@rm tmp.sysctl

rcctl_2: $(PKG_LOG)
	@echo $@
	@/bin/ls -1 /etc/rc.d >$@

ts: $(CARGO_BIN)/tree-sitter
	@echo $@
	@tree-sitter -h >tmp.tree-sitter
	@awk '/^SUBCOMMANDS:/ {p=1;next} p {print $$1}' tmp.tree-sitter >$@
	@rm tmp.tree-sitter

vmgr_1: /home/tw/config/ksh/share/BS/vmgr.ksh
	@echo $@
	@vmgr cmdlist >$@

$(PKG_LOG):
	@echo $@
	@mkdir -p $(PKG_LOG:H)
	@touch $(PKG_LOG)

.PHONY: all clean
# ========================================================================
.endif # WHOLE FILE
