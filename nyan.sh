#!/bin/bash
#
# nyan.sh - nyan a simple netcat wrapper
#
# Copyright (c) 2013 by Christian Rebischke <echo Q2hyaXMuUmViaXNjaGtlQGdtYWlsLmNvbQo= | base64 -d>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/
#
#======================================================================
# Author: Christian Rebischke
# Email : echo Q2hyaXMuUmViaXNjaGtlQGdtYWlsLmNvbQo= | base64 -d
# Github: www.github.com/Shibumi
#
# nyan get    = nc $IP $PORT  | pv -rb > $FILE
# nyan serve  = cat $file | pv -rb | nc -l -p $PORT
# nyan raw    = nc $IP $PORT
# nyan scan   = nc -v -n -z -w 1 $IP $PORTRANGE
# nyan proxy  = mkfifo backpipe; nc -l $PORT 0<backpipe | nc $IP $PORT 1>backpipe
# nyan command= nc -l -p $PORT -e $COMMAND
# nyan server = nc -l -p $PORT
# nyan http   = { echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c <some.file)\r\n\r\n"; cat some.file; } | nc -l 8080
# nyan forward= nc -L $IP:$PORT -p $LOCALPORT

function helpout()
{
  echo "nyan 1.2.0 - a simple GNU netcat wrapper"
  echo "  +      o     +              o   "
  echo "    +             o     +       + "
  echo "o          +                      "
  echo "    o  +           +        +     "
  echo "+        o     o       +        o "
  echo "-_-_-_-_-_-_-_,------,      o     "
  echo "_-_-_-_-_-_-_-|   /\_/\           "
  echo "-_-_-_-_-_-_-~|__( ^ .^)  +     + " 
  echo "_-_-_-_-_-_-_-\"\"  \"\"          "
  echo "+      o         o   +       o    "
  echo "   +         +                    "
  echo "o        o         o      o     + "
  echo "   o           +                  "
  echo "+      +     o        o      +    "
  echo "basic usage:"
  echo "  nyan get <IP> <PORT> <FILENAME>"
  echo "  nyan serve <PORT> <FILENAME>"
  echo "  nyan raw <IP> <PORT>"
  echo "  nyan scan <IP> <PORT_MIN> <PORT_MAX>"
  echo "  nyan proxy <IP> <PORT_SRC> <PORT_DEST>"
  echo "  nyan command <PORT> <COMMAND>"
  echo "  nyan server <PORT>"
  echo "  nyan http <PORT> <FILENAME>"
  echo "  nyan forward <IP> <PORT> <LOCALPORT>"
}

function valid_ip()
{
    #thx to Mitch Frazier ( linuxjournal.com )
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function valid_localport()
{
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] 
  then
    echo "[-] Port is not a number" >&2; exit 1
  fi

  if [[ $UID == 0 ]]
  then
    if [[ $1 -gt 65535 ]]
    then
      echo "[-] port is out of range" >&2
      exit 1
    fi
  else
    if [[ $1 -lt 1024 || $1 -gt 65535 ]]
    then 
      echo "[-] port is out of range" >&2
      echo "[-] as normal user you can only specify ports between 1024 and 65535" >&2
      exit 1
    fi
  fi
}

function valid_port()
{
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]]
  then
    echo "[-] Port is not a number" >&2; exit 1
  fi

  if [[ $1 -gt 65535 ]]
  then
    echo "[-] port is out of range" >&2
    exit 1
  fi
}

if [ $# -eq 0 ]
  then
    helpout
    exit 1
fi

case $1 in 

  get) 
    if [ $# -eq 4 ]
    then
      if  valid_ip $2  &&  valid_port $3 
      then
        echo "[+] getting file.."
        nc $2 $3 | pv -rb > $4
        echo "[+] generating checksum.."
        sha512sum $4
      else
        echo "get usage:"
        echo "  With get you can get a file."
        echo "  just specify IP, port and filename."
        echo ""
        echo "  nyan get <IP> <PORT> <FILENAME>"
      fi
    else
      echo "get usage:"
      echo "  With get you can get a file." 
      echo "  Just specify IP, port and filename."
      echo ""
      echo "  nyan get <IP> <PORT> <FILENAME>"
    fi ;;

  serve) 
    if [ $# -eq 3 ]
    then
      if  valid_localport $2  
      then
        echo "[+] Generating checksum..."
        sha512sum $3
        echo "[+] serving file..."
        cat $3 | pv -rb | nc -l -p $2
      else
        echo "serve usage:"
        echo "  With serve you can serve a file."
        echo "  Just specify port and filename."
        echo ""
        echo "  nyan serve <PORT> <FILENAME>"
      fi
      else
        echo "serve usage:"
        echo "  With serve you can serve a file."
        echo "  Just specify port and filename."
        echo ""
        echo "  nyan serve <PORT> <FILENAME>"
    fi ;;

  raw) 
    if [ $# -eq 3 ]
    then
      if valid_ip $2  &&  valid_port $3
      then
        nc $2 $3
      else
        echo "raw usage:"
        echo "  With raw you can build a raw connection to a port."
        echo "  You can do a lot of things this way."
        echo "  For example building a peer to peer chat."
        echo "  Just specify IP and port" 
        echo ""
        echo "  nyan raw <IP> <PORT>"
      fi
    else
      echo "raw usage:"
      echo "  With raw you can build a raw connection to a port."
      echo "  You can do a lot of things this way."
      echo "  For example building a peer to peer chat."
      echo "  Just specify IP and port" 
      echo ""
      echo "  nyan raw <IP> <PORT>"
    fi ;;

  scan) 
    if [ $# -eq 4 ]
    then
      if valid_ip $2 && valid_port $3 && valid_port $4
      then
        nc -v -n -z -w 1 $2 $3-$4
      else
        echo "scan usage:"
        echo "  With scan you can perform simple portscans."
        echo "  Just specify the IP and the PORTRANGE with min and max port"
        echo ""
        echo "  nyan scan <IP> <PORT_MIN> <PORT_MAX>"
      fi
    else
      echo "scan usage:"
      echo "  With scan you can perform simple portscans."
      echo "  Just specify the IP and the PORTRANGE with min and max port"
      echo ""
      echo "  nyan scan <IP> <PORT_MIN> <PORT_MAX>"
    fi ;;

  proxy) 
    if [ $# -eq 4 ]
    then
      if valid_ip $2 && valid_port $3 && valid_port $4
      then
        mkfifo backpipe; nc -l $3 0<backpipe | nc $2 $4 1>backpipe
      else:
        echo "proxy usage:"
        echo "  With proxy you can build a simple proxy."
        echo "  Just specify IP, source port and destination port"
        echo ""
        echo "  nyan proxy <IP> <PORT_SRC> <PORT_DEST>"
      fi
    else
      echo "proxy usage:"
      echo "  With proxy you can build a simple proxy."
      echo "  Just specify IP, source port and destination port"
      echo ""
      echo "  nyan proxy <IP> <PORT_SRC> <PORT_DEST>"
    fi ;;

  command) 
    if [ $# -eq 3 ]
    then
      if valid_localport $2
      then
        nc -l -p $2 -e $3
      else
        echo "command usage:"
        echo "  With command you can bind a port to an executable."
        echo "  The best example for it is: /bin/sh."
        echo ""
        echo "  nyan command <PORT> <COMMAND>"
      fi
    else
      echo "command usage:"
      echo "  With command you can bind a port to an executable."
      echo "  The best example for it is: /bin/sh."
      echo ""
      echo "  nyan command <PORT> <COMMAND>"
    fi ;;

  server)
    if [ $# -eq 2 ]
    then
      if valid_localport $2
      then
        nc -l -p $2
      else
        echo "server usage:"
        echo "  With server you can listen on a port."
        echo "  This is useful for a simple chat connection."
        echo ""
        echo "  nyan server <PORT>"
      fi
    else
      echo "server usage:"
      echo "  With server you can listen on a port."
      echo "  This is useful for a simple chat connection."
      echo ""
      echo "  nyan server <PORT>"
    fi ;;

  http)
    if [ $# -eq 3 ]
    then
      if valid_localport $2
      then
        { echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c <$3)\r\n\r\n"; cat $3; } | nc -l -p $2
      else
        echo "http usage:"
        echo "  With http you can serve a file like a webserver."
        echo ""
        echo "  nyan http <PORT> <FILENAME>"
      fi
    else
      echo "http usage:"
      echo "  With http you can serve a file like a webserver."
      echo ""
      echo "  nyan http <PORT> <FILENAME>"
    fi ;;

  forward)
    if [ $# -eq 4 ]
    then
      if valid_ip $2 && valid_port $3 && valid_localport $4
      then
        nc -L $2:$3 -p $4
      else
        echo "forward usage:"
        echo "  forwards a remote port from a remote adress"
        echo "  to a local port."
        echo ""
        echo "  nyan forward <IP> <PORT> <LOCALPORT>"
      fi
    else
      echo "forward usage:"
      echo "  forwards a remote port from a remote adress"
      echo "  to a local port."
      echo ""
      echo "  nyan forward <IP> <PORT> <LOCALPORT>"
    fi ;;

  *)
    helpout 
    exit 1
esac
