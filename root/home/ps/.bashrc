alias roobi="sudo /usr/Roobi/now/run"
alias ssh="sudo systemctl start sshd"
mesg n
if [ -z "${DISPLAY}" ] &&( [ "${XDG_VTNR}" -eq 1 ]); then
  	clear
	exec startx 2> /dev/null
fi
