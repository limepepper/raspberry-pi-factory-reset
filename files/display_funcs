#!/bin/bash


# https://misc.flogisoft.com/bash/tip_colors_and_formatting

bufferstring=""
ev()
{
  varname="$1"
  #let bufferstring
  bufferstring="${bufferstring}\n$1=${!varname}"
}

show_var()
{
  varname="$1"
  echo "$1=${!varname}"
}



shellquote()
{
a="$1"

#$a =~ s/[\n]/'\n'/go;
#$a =~ s/[\002-\011\013-\032\\\#\?\`\(\)\{\}\[\]\^\*\<\=\>\~\|\; \"\!\$\&\'\202-\377]/\\$&/go;
# quote newline as '\n'
echo  "$a" | sed -r "s/[\n]/'\n'/g"
}

parse_tokens()
{
a="$1"

for K in "${!COLOR[@]}"; do
    #echo $K --- ${COLOR[$K]};
    a="$(echo "$a" | sed -r "s/[$]{1,1}\{$K\}/${COLOR[$K]}/g")"
done

echo "$a"

#eval 'echo' "$a"

}
# | sed -e 's/.*\bWARN.*/\x1b[7m&\x1b[0m/i' -e 's/.*\bERR.*/\x1b[93;41 m&\x1b[0m/i'


pr_head()
{
    declare alert_header=""
    [[ "$1" == "warn" ]] && \
    alert_header=1

  while read -r  line; do
      # printf "%s" "$data"

      if [[ $alert_header ]] ; then
       echo -en "${RED}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo
        else
       parse_tokens "${line:0:80}"
       fi

  done
# ansi chars line wrapping screws things up.
}


# | sed -e 's/.*\bWARN.*/\x1b[7m&\x1b[0m/i' -e 's/.*\bERR.*/\x1b[93;41 m&\x1b[0m/i'

# # Reset
# Color_Off='\033[0m'       # Text Reset

# # Regular Colors
# Black='\033[0;30m'        # Black
# Red='\033[0;31m'          # Red
# Green='\033[0;32m'        # Green
# Yellow='\033[0;33m'       # Yellow
# Blue='\033[0;34m'         # Blue
# Purple='\033[0;35m'       # Purple
# Cyan='\033[0;36m'         # Cyan
# White='\033[0;37m'        # White

# In Bash, the <Esc> character can be obtained with the following syntaxes:

# \e
# \033
# \x1B


pr_header()
{

  [[ $# -gt 0 ]] && \
  {
    line="$@"
      echo ""
       echo -en "${BLUE}${WHITEBG}"
       printf "%s" "${line:0:100}"
       echo -en "${RESET}"
       echo

  } || \
  {
  while read -r  line; do
      # printf "%s" "$data"
       echo -en "${PINK}"
       printf "%s" "${line:0:100}"
       echo -en "${RESET}"
       echo
  done

  }
}



pr_warn()
{

  [[ $# -gt 0 ]] && \
  {
    line=$1

       echo -en "${PINK}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo

  } || \
  {
  while read -r  line; do
      # printf "%s" "$data"
       echo -en "${PINK}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo
  done

  }
}


pr_ok()
{

  [[ $# -gt 0 ]] && \
  {
    line=$1

       echo -en "${GREEN}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo

  } || \
  {
  while read -r  line; do
      # printf "%s" "$data"
       echo -en "${GREEN}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo
  done

  }
}



pr_alert()
{

  [[ $# -gt 0 ]] && \
  {
    line=$1

       echo -en "${RED}${WHITEBG}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo

  } || \
  {
  while read -r  line; do
      # printf "%s" "$data"
       echo -en "${RED}"
       printf "%s" "${line:0:80}"
       echo -en "${RESET}"
       echo
  done

  }
# ansi chars line wrapping screws things up.
}

# takes a
pr_table()
{
echo -e "$1"

}

printval()
{
  msg=$1
  char='='

  if [[ $(awk -F"${char}" '{print NF-1}' <<< "$msg") -eq 1 ]] ; then
  #echo hee11
      echo "${MAGENTAFG}${msg%%=*}${RESET}=${BLUE}${msg##*=}${RESET}"
      #${stringZ#a*C}
   #   echo hee
  elif [[ "$msg" =~ ^vdvrergv$ ]] ;then
      echo "${BLUEFG}${msg}${RESET}"
  echo rgjerigo
  elif [[ "joijij2" == "joijio"  ]] ;then
echo rgjerigo
  else
   echo "${YELLOWFB}${msg}${RESET}"
  fi
}

wasX=""
[[ "$-" =~ 'x'  ]] && wasX=true && set +x

##$ bash --version   # Must be at least version 4 to have associative arrays
#GNU bash, version 4.2.24(1)-release (x86_64-pc-linux-gnu)

# Define a few Colours
    BLACKFG=$(tput setaf 0  2>/dev/null )
    BLACKBG=$(tput setab 0  2>/dev/null  )
        RED=$(tput setaf 1    2>/dev/null )
       PINK=$(tput setaf 134   2>/dev/null )
      REDFG=$(tput setaf 1   2>/dev/null )
      REDBG=$(tput setab 1  2>/dev/null )
      GREEN=$(tput setaf 2  2>/dev/null )
    GREENFG=$(tput setaf 2  2>/dev/null )
    GREENBG=$(tput setab 2  2>/dev/null )
   YELLOWFG=$(tput setaf 3  2>/dev/null )
   YELLOWBG=$(tput setab 3  2>/dev/null )
       BLUE=$(tput setaf 4   2>/dev/null )
     BLUEFG=$(tput setaf 4  2>/dev/null )
     BLUEBG=$(tput setab 4   2>/dev/null )
  MAGENTAFG=$(tput setaf 5   2>/dev/null )
  MAGENTABG=$(tput setab 5   2>/dev/null )
     CYANFG=$(tput setaf 6  2>/dev/null )
     CYANBG=$(tput setab 6    2>/dev/null )
    WHITEFG=$(tput setaf 7   2>/dev/null )
    WHITEBG=$(tput setab 7  2>/dev/null )
     PURPLE=$(tput setaf 8  2>/dev/null )
  DEFAULTFG=$(tput setaf 9  2>/dev/null )
  DEFAULTBG=$(tput setab 9  2>/dev/null )
    PURPLE2=$(tput setaf 125  2>/dev/null )
      BLINK=$(tput blink  2>/dev/null )
    REVERSE=$(tput smso   2>/dev/null )
  UNDERLINE=$(tput smul  2>/dev/null )
LIME_YELLOW=$(tput setaf 190  2>/dev/null )
POWDER_BLUE=$(tput setaf 153  2>/dev/null )
      RESET=$(tput sgr0  2>/dev/null )

declare -A COLOR
    COLOR[BLACKFG]=${BLACKFG}
    COLOR[WHITEFG]=${WHITEFG}
  COLOR[DEFAULTFG]=${DEFAULTFG}
  COLOR[DEFAULTBG]=${DEFAULTBG}
COLOR[POWDER_BLUE]=${POWDER_BLUE}
     COLOR[CYANFG]=${CYANFG}
     COLOR[CYANBG]=${CYANBG}
    COLOR[GREENFG]=${GREENFG}
    COLOR[GREENBG]=${GREENBG}
     COLOR[BLUEFG]=${BLUEFG}
     COLOR[BLUEBG]=${BLUEBG}
   COLOR[YELLOWFG]=${YELLOWFG}
   COLOR[YELLOWBG]=${YELLOWBG}
       COLOR[PINK]=${PINK}
      COLOR[RESET]=${RESET}
      COLOR[REDFG]=${REDFG}
      COLOR[REDBG]=${REDBG}



[[ -n "${wasX}" ]] && set -x
unset wasX