# vim: ft=ksh ts=4 nowrap

set -A complete_git_1 -- add bisect branch clone commit diff fetch grep init log merge mv pull push rebase reset restore rm show sparse-checkout status switch tag
set -A complete_help -- S SQL SQLify add-exit-action amuse:create-cmd-wrappers amuse:edit amuse:env amuse:file-from-id amuse:playing amuse:send-cmd ansi-attr as-root chomp clearout cmd-in-use cond-rlwrap count-down cowmath csongor-colors desparkle die dir-is-empty f-b f-bc f-cd f-chibi-scheme f-clear f-cpan f-cpanm f-espeak f-fc f-fortune f-git f-go f-halt f-help f-r f-reboot f-syspatch f-tclsh f-v f-which f-xxdiff find-function flash-parent-window-of-pid fmark forceline fpop fpush fsave ftry fullstop generate-exclusive-lock-name get-exclusive-lock get-exclusive-lock-or-exit gsub h1 h2 hN histmark i-can-haz-inet in-ancestor-path is-known-host list-known-hosts log log-stderr lolcow ls-cfuncs ls-lan ls-redirs ls-todos m m-groups m-list-new m-msgcount m-save make-on-filechange markdown-to-html matching-commands math mcd message needs new-array newest nextfd note notify now obsd p pad pass path pc pipedit pkg pre-prompt present prn-cmd qvis realbin recode-to-ogg-vorbis release-exclusive-lock reshell resolve-alias roll ruler s2hms save-function scheme search-path sel-from-list set-alternate-screen set-colors-bg-fg set-perl5lib showvar sparkle splitstr sql-fields sql-reply ssh-askfirst ssh-clonedir t tdump today todo trackfile unset-alternate-screen utf8codes vtmp warn with-defaults x11-windowid-for-pid xat xget xput yes-or-no
set -A complete_rcctl_2 -- amd apmd avahi_daemon avahi_dnsconfd bgpd bootparamd cron cups_browsed cupsd dhcpd dhcrelay dhcrelay6 dvmrpd eigrpd ftpd ftpproxy ftpproxy6 gitdaemon honk hostapd hotplugd httpd identd ifstated iked inetd isakmpd iscsid ldapd ldattach ldomd ldpd lockd lpd messagebus mopd mountd mrouted nfsd npppd nsd ntpd ospf6d ospfd pflogd portmap postgresql rad radiusd rarpd rbootd rc.subr relayd ripd route6d rsyncd saslauthd sasyncd sensorsd slaacd slowcgi smtpd sndiod snmpd spamd spamlogd sshd statd svnserve switchd syslogd tftpd tftpproxy unbound unwind vmd watchdogd wsmoused xenodm ypbind ypldap ypserv
set -A complete_scp -- fred.lan github.com leroy.lan sam sam.lan uberbaud.net yt yt.lan
set -A complete_ssh -- fred.lan github.com leroy.lan sam sam.lan uberbaud.net yt yt.lan
set -A complete_sysctl -- ddb.console ddb.log ddb.max_line ddb.max_width ddb.panic ddb.radix ddb.tab_stop_width ddb.trigger fs.posix.setuid hw.allowpowerdown hw.byteorder hw.cpuspeed hw.diskcount hw.disknames hw.machine hw.model hw.ncpu hw.ncpufound hw.ncpuonline hw.pagesize hw.perfpolicy hw.physmem hw.product hw.sensors.acpiac0.indicator0 hw.sensors.acpibat0.power0 hw.sensors.acpibat0.raw0 hw.sensors.acpibat0.volt0 hw.sensors.acpibat0.volt1 hw.sensors.acpibat0.watthour0 hw.sensors.acpibat0.watthour1 hw.sensors.acpibat0.watthour2 hw.sensors.acpibat0.watthour3 hw.sensors.acpibat0.watthour4 hw.sensors.acpibat1.power0 hw.sensors.acpibat1.raw0 hw.sensors.acpibat1.volt0 hw.sensors.acpibat1.volt1 hw.sensors.acpibat1.watthour0 hw.sensors.acpibat1.watthour1 hw.sensors.acpibat1.watthour2 hw.sensors.acpibat1.watthour3 hw.sensors.acpibat1.watthour4 hw.sensors.acpibtn0.indicator0 hw.sensors.acpithinkpad0.fan0 hw.sensors.acpithinkpad0.indicator0 hw.sensors.acpithinkpad0.temp0 hw.sensors.acpithinkpad0.temp1 hw.sensors.acpithinkpad0.temp2 hw.sensors.acpithinkpad0.temp3 hw.sensors.acpithinkpad0.temp4 hw.sensors.acpithinkpad0.temp5 hw.sensors.acpithinkpad0.temp6 hw.sensors.acpithinkpad0.temp7 hw.sensors.acpitz0.temp0 hw.sensors.cpu0.temp0 hw.sensors.pchtemp0.temp0 hw.serialno hw.setperf hw.smt hw.usermem hw.uuid hw.vendor hw.version kern.allowdt kern.allowkmem kern.argmax kern.audio.record kern.boottime kern.bufcachepercent kern.ccpu kern.clockrate kern.consbufsize kern.consdev kern.cp_time kern.domainname kern.forkstat.fork_pages kern.forkstat.forks kern.forkstat.kthread_pages kern.forkstat.kthreads kern.forkstat.tfork_pages kern.forkstat.tforks kern.forkstat.vfork_pages kern.forkstat.vforks kern.fscale kern.fsync kern.global_ptrace kern.hostid kern.hostname kern.job_control kern.malloc.bucket.1024 kern.malloc.bucket.128 kern.malloc.bucket.131072 kern.malloc.bucket.16 kern.malloc.bucket.16384 kern.malloc.bucket.2048 kern.malloc.bucket.256 kern.malloc.bucket.262144 kern.malloc.bucket.32 kern.malloc.bucket.32768 kern.malloc.bucket.4096 kern.malloc.bucket.512 kern.malloc.bucket.524288 kern.malloc.bucket.64 kern.malloc.bucket.65536 kern.malloc.bucket.8192 kern.malloc.buckets kern.malloc.kmemnames kern.malloc.kmemstat.ACPI kern.malloc.kmemstat.AGP_Memory kern.malloc.kmemstat.DRM kern.malloc.kmemstat.Export_Host kern.malloc.kmemstat.IPsec_creds kern.malloc.kmemstat.ISOFS_mount kern.malloc.kmemstat.ISOFS_node kern.malloc.kmemstat.MFS_node kern.malloc.kmemstat.MSDOSFS_fat kern.malloc.kmemstat.MSDOSFS_mount kern.malloc.kmemstat.MSDOSFS_node kern.malloc.kmemstat.NDP kern.malloc.kmemstat.NFS_daemon kern.malloc.kmemstat.NFS_mount kern.malloc.kmemstat.NFS_req kern.malloc.kmemstat.NFS_srvsock kern.malloc.kmemstat.NTFS_attr kern.malloc.kmemstat.NTFS_data kern.malloc.kmemstat.NTFS_decomp kern.malloc.kmemstat.NTFS_dir kern.malloc.kmemstat.NTFS_fnode kern.malloc.kmemstat.NTFS_hash kern.malloc.kmemstat.NTFS_mount kern.malloc.kmemstat.NTFS_node kern.malloc.kmemstat.NTFS_vrun kern.malloc.kmemstat.SYN_cache kern.malloc.kmemstat.UDF_file_entry kern.malloc.kmemstat.UDF_file_id kern.malloc.kmemstat.UDF_mount kern.malloc.kmemstat.UFS_mount kern.malloc.kmemstat.UFS_quota kern.malloc.kmemstat.USB kern.malloc.kmemstat.USB_HC kern.malloc.kmemstat.USB_device kern.malloc.kmemstat.UVM_amap kern.malloc.kmemstat.UVM_aobj kern.malloc.kmemstat.VFS_cluster kern.malloc.kmemstat.VM_map kern.malloc.kmemstat.VM_pmap kern.malloc.kmemstat.VM_swap kern.malloc.kmemstat.counters kern.malloc.kmemstat.crypto_data kern.malloc.kmemstat.devbuf kern.malloc.kmemstat.dirhash kern.malloc.kmemstat.emuldata kern.malloc.kmemstat.ether_multi kern.malloc.kmemstat.exec kern.malloc.kmemstat.file kern.malloc.kmemstat.file_desc kern.malloc.kmemstat.free kern.malloc.kmemstat.fusefs_mount kern.malloc.kmemstat.ifaddr kern.malloc.kmemstat.in_multi kern.malloc.kmemstat.indirdep kern.malloc.kmemstat.inodedep kern.malloc.kmemstat.ioctlops kern.malloc.kmemstat.iov kern.malloc.kmemstat.ip6_options kern.malloc.kmemstat.ip_moptions kern.malloc.kmemstat.kqueue kern.malloc.kmemstat.memdesc kern.malloc.kmemstat.miscfs_mount kern.malloc.kmemstat.mount kern.malloc.kmemstat.mrt kern.malloc.kmemstat.namecache kern.malloc.kmemstat.newblk kern.malloc.kmemstat.pagedep kern.malloc.kmemstat.pcb kern.malloc.kmemstat.pfkey_data kern.malloc.kmemstat.proc kern.malloc.kmemstat.rtable kern.malloc.kmemstat.sem kern.malloc.kmemstat.shm kern.malloc.kmemstat.sigio kern.malloc.kmemstat.soopts kern.malloc.kmemstat.subproc kern.malloc.kmemstat.sysctl kern.malloc.kmemstat.tdb kern.malloc.kmemstat.temp kern.malloc.kmemstat.ttys kern.malloc.kmemstat.vnodes kern.malloc.kmemstat.witness kern.malloc.kmemstat.xform_data kern.maxclusters kern.maxfiles kern.maxlocksperuid kern.maxpartitions kern.maxproc kern.maxthread kern.maxvnodes kern.msgbufsize kern.nchstats.2passes kern.nchstats.bad_hits kern.nchstats.false_hits kern.nchstats.good_hits kern.nchstats.long_names kern.nchstats.misses kern.nchstats.nch_dotdothits kern.nchstats.ncs_dothits kern.nchstats.ncs_revhits kern.nchstats.ncs_revmiss kern.nchstats.negative_hits kern.nchstats.pass2 kern.netlivelocks kern.nfiles kern.ngroups kern.nosuidcoredump kern.nprocs kern.nselcoll kern.nthreads kern.numvnodes kern.osrelease kern.osrevision kern.ostype kern.osversion kern.pool_debug kern.posix1version kern.rawpartition kern.saved_ids kern.securelevel kern.seminfo.semaem kern.seminfo.semmni kern.seminfo.semmns kern.seminfo.semmnu kern.seminfo.semmsl kern.seminfo.semopm kern.seminfo.semume kern.seminfo.semusz kern.seminfo.semvmx kern.shminfo.shmall kern.shminfo.shmmax kern.shminfo.shmmin kern.shminfo.shmmni kern.shminfo.shmseg kern.somaxconn kern.sominconn kern.splassert kern.stackgap_random kern.sysvmsg kern.sysvsem kern.sysvshm kern.timecounter.choice kern.timecounter.hardware kern.timecounter.tick kern.timecounter.timestepwarnings kern.timeout_stats kern.tty.tk_cancc kern.tty.tk_nin kern.tty.tk_nout kern.tty.tk_rawcc kern.ttycount kern.utc_offset kern.version kern.wxabort machdep.allowaperture machdep.bios.cksumlen machdep.bios.diskinfo.128 machdep.console_device machdep.cpufeature machdep.cpuid machdep.cpuvendor machdep.forceukbd machdep.invarianttsc machdep.kbdreset machdep.lidaction machdep.pwraction machdep.tscfreq machdep.xcrypt net.bpf.bufsize net.bpf.maxbufsize net.inet.ah.enable net.inet.carp.allow net.inet.carp.log net.inet.carp.preempt net.inet.divert.recvspace net.inet.divert.sendspace net.inet.esp.enable net.inet.esp.udpencap net.inet.esp.udpencap_port net.inet.etherip.allow net.inet.gre.allow net.inet.gre.wccp net.inet.icmp.bmcastecho net.inet.icmp.errppslimit net.inet.icmp.maskrepl net.inet.icmp.rediraccept net.inet.icmp.redirtimeout net.inet.icmp.tstamprepl net.inet.ip.arpdown net.inet.ip.arpq.drops net.inet.ip.arpq.len net.inet.ip.arpq.maxlen net.inet.ip.arpqueued net.inet.ip.arptimeout net.inet.ip.directed-broadcast net.inet.ip.encdebug net.inet.ip.forwarding net.inet.ip.ipsec-allocs net.inet.ip.ipsec-auth-alg net.inet.ip.ipsec-bytes net.inet.ip.ipsec-comp-alg net.inet.ip.ipsec-enc-alg net.inet.ip.ipsec-expire-acquire net.inet.ip.ipsec-firstuse net.inet.ip.ipsec-invalid-life net.inet.ip.ipsec-pfs net.inet.ip.ipsec-soft-allocs net.inet.ip.ipsec-soft-bytes net.inet.ip.ipsec-soft-firstuse net.inet.ip.ipsec-soft-timeout net.inet.ip.ipsec-timeout net.inet.ip.maxqueue net.inet.ip.mforwarding net.inet.ip.mrtproto net.inet.ip.mtudisc net.inet.ip.mtudisctimeout net.inet.ip.multipath net.inet.ip.portfirst net.inet.ip.porthifirst net.inet.ip.porthilast net.inet.ip.portlast net.inet.ip.redirect net.inet.ip.sourceroute net.inet.ip.ttl net.inet.ipcomp.enable net.inet.ipip.allow net.inet.tcp.ackonpush net.inet.tcp.always_keepalive net.inet.tcp.baddynamic net.inet.tcp.ecn net.inet.tcp.keepidle net.inet.tcp.keepinittime net.inet.tcp.keepintvl net.inet.tcp.mssdflt net.inet.tcp.reasslimit net.inet.tcp.rfc1323 net.inet.tcp.rfc3390 net.inet.tcp.rootonly net.inet.tcp.rstppslimit net.inet.tcp.sack net.inet.tcp.sackholelimit net.inet.tcp.slowhz net.inet.tcp.synbucketlimit net.inet.tcp.syncachelimit net.inet.tcp.synhashsize net.inet.tcp.synuselimit net.inet.udp.baddynamic net.inet.udp.checksum net.inet.udp.recvspace net.inet.udp.rootonly net.inet.udp.sendspace net.inet6.divert.recvspace net.inet6.divert.sendspace net.inet6.icmp6.errppslimit net.inet6.icmp6.mtudisc_hiwat net.inet6.icmp6.mtudisc_lowat net.inet6.icmp6.nd6_debug net.inet6.icmp6.nd6_delay net.inet6.icmp6.nd6_maxnudhint net.inet6.icmp6.nd6_mmaxtries net.inet6.icmp6.nd6_umaxtries net.inet6.icmp6.redirtimeout net.inet6.ip6.auto_flowlabel net.inet6.ip6.dad_count net.inet6.ip6.dad_pending net.inet6.ip6.defmcasthlim net.inet6.ip6.forwarding net.inet6.ip6.hdrnestlimit net.inet6.ip6.hlim net.inet6.ip6.log_interval net.inet6.ip6.maxdynroutes net.inet6.ip6.maxfragpackets net.inet6.ip6.maxfrags net.inet6.ip6.mforwarding net.inet6.ip6.mrtproto net.inet6.ip6.mtudisctimeout net.inet6.ip6.multicast_mtudisc net.inet6.ip6.multipath net.inet6.ip6.neighborgcthresh net.inet6.ip6.redirect net.inet6.ip6.use_deprecated net.mpls.mapttl_ip net.mpls.mapttl_ip6 net.mpls.ttl net.pipex.enable vfs.ffs.dirhash_dirsize vfs.ffs.dirhash_maxmem vfs.ffs.dirhash_mem vfs.ffs.max_softdeps vfs.ffs.sd_blk_limit_hit vfs.ffs.sd_blk_limit_push vfs.ffs.sd_dir_entry vfs.ffs.sd_direct_blk_ptrs vfs.ffs.sd_indir_blk_ptrs vfs.ffs.sd_ino_limit_hit vfs.ffs.sd_ino_limit_push vfs.ffs.sd_inode_bitmap vfs.ffs.sd_sync_limit_hit vfs.ffs.sd_tickdelay vfs.ffs.sd_worklist_push vfs.fuse.fusefs_fbufs_in vfs.fuse.fusefs_fbufs_wait vfs.fuse.fusefs_open_devices vfs.fuse.fusefs_pool_pages vfs.mounts.ffs has 9 mounted instances vfs.nfs.iothreads vm.anonmin vm.loadavg vm.malloc_conf vm.nkmempages vm.psstrings vm.swapencrypt.enable vm.swapencrypt.keyscreated vm.swapencrypt.keysdeleted vm.vnodemin vm.vtextmin
set -A complete_chflags -- nodump nonodump nosappnd noschg nouappnd nouchg sappnd schg uappnd uchg
set -A complete_fossil_1 -- 3-way-merge add addremove alerts all amend annotate artifact attachment backoffice backup bisect blame branch bundle cache cat cgi changes checkout ci clean clone close co commit configuration dbstat deconstruct delete descendants diff export extras finfo forget fts-config fusefs gdiff git grep hash-policy help hook http import info init leaves login-group ls md5sum merge mv new open pop3d praise publish pull purge push rebuild reconstruct redo remote remote-url rename reparent revert rm rss scrub search server settings sha1sum sha3sum shell smtpd sql sqlar sqlite3 stash status sync tag tarball ticket timeline tls-config touch ui undo unpublished unset unversioned update user uv version whatis wiki zip
set -A complete_inc -- +inbox -help -nochangecur
set -A complete_kill_1 -- -9 -CONT -HUP -INFO -INT -KILL -STOP -USR1 -USR2
set -A complete_mediainfo -- --Help-Output --Info-Parameters --Output='General;%Duration/String3%,Audio;%OverallBitRate%'
set -A complete_mget -- 
set -A complete_perlbrew -- alias available clean clone-modules download exec help info init install install-cpanm install-multiple install-patchperl lib list off self-install self-upgrade switch switch-off uninstall upgrade-perl use version
set -A complete_pkg_1 -- add check delete grep installed query update web www
set -A complete_poco -- copies= duplex economy fit-to-page manualfeed page-ranges= raw reverse
set -A complete_rcctl_1 -- 'ls all' 'ls failed' 'ls off' 'ls on' 'ls started' 'ls stopped' check daemon disable enable get getdef order reload restart set start stop
set -A complete_sndioctl -- input.level input.mute output.level output.mute
set -A complete_xfontsel -- -pattern -print -sample -sample16 -sampleUCS -scaled
set -A complete_xinput_1 -- create-master delete-prop disable enable float get-button-map get-feedbacks list list-props map-to-output query-state reattach remove-master set-atom-prop set-button-map set-cp set-float-prop set-int-prop set-integer-feedback set-mode set-pointer set-prop set-ptr-feedback test test-xi2 watch-props
set -A complete_xinput_2 -- /dev/wskbd /dev/wsmouse /dev/wsmouse0
