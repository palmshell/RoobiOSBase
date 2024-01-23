alias roobi="sudo /usr/Roobi/now/run"
alias ssh="sudo systemctl start sshd"
mesg n
if [ -z "${DISPLAY}" ] &&( [ "${XDG_VTNR}" -eq 1 ] || [ "${XDG_VTNR}" -eq 6 ] ); then
  	clear
	exec startx 2> /dev/null
fi

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 5 ]; then
  	alias logt="tail -f /usr/factory/progress/1.log"
  	alias log="tail -n 100 /usr/factory/progress/1.log"
  	tail -f /usr/factory/progress/1.log
fi
