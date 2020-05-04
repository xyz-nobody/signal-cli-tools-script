#!/bin/bash
# https://github.com/AsamK/signal-cli
# documentation
# https://github.com/AsamK/signal-cli/blob/master/man/signal-cli.1.adoc
# Tested with signal-cli version: 0.6.7
# An automatic answering chatbot with forwarding of the initial message to a new number


#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.


USERNAME=+XXXXXXXXXXXX
NEWPHONENUMBER=+XXXXXXXXXX
AUTOREPLY_MESSAGE="Bonjour,\n
Je suis un chat bot qui vous répond automatiquement, la personne que vous essayez de contacter à changé de numéro.\n
Merci de la contacter au numéro $NEWPHONENUMBER\n
Merci d'avance\n\n

Hello,\n
I am a chat bot that automatically answers you, the person you are trying to contact has change the number.\n
Please contact her at $NEWPHONENUMBER\n
Thanks\n"

signalclipath="/usr/local/bin/signal-cli -u $USERNAME"

# values to check in the output (usefull for futures changes)
envelopefrom="Sender: “null” "
body="Body:"
timestamp="Timestamp:"


#$signalclipath -v
# check receive sms
receive="$($signalclipath receive)"

# output to array
my_array=()
while IFS= read -r line; do
    my_array+=( "$line" )
done < <( echo "$receive" )

# loop the array
for i in "${my_array[@]}"
do
  if [[ $i == *"$envelopefrom"* ]]; then
    newenvelopefrom=$i
  fi
  if [[ $i == *"$timestamp"* ]]; then
    newtimestamp=$i
  fi
  if [[ $i == *"$body"* ]]; then
    # if the sms get a body, then we have to respond

    # remove "body:" first 5 letters from body text
    newbody=${i:5}

    # get only the first numbers from string
    newenvelopefrom=$(echo $newenvelopefrom | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')
    # add + to the current phone number
    newenvelopefrom="+"$newenvelopefrom

    # nice to have
    echo "Sender:" $newenvelopefrom
    echo $newtimestamp
    echo "Body: "$newbody

    # nice to have 2 (save output in file output.txt)
    echo ""
    now=$(date)
    now=$(date +'%m/%d/%Y-%H:%M:%S')
    echo "----------------$now----------------" >> /opt/script/output.txt
    echo "Sender:" $newenvelopefrom >> /opt/script/output.txt
    echo $newtimestamp >> /opt/script/output.txt
    echo "Body: "$newbody >> /opt/script/output.txt
    echo "" >> /opt/script/output.txt

    # sending sms to sender
    echo "Sending message to $newenvelopefrom"
    echo -e "$AUTOREPLY_MESSAGE" | $signalclipath send $newenvelopefrom
    # sending sms to me
    echo "Notify me: $NEWPHONENUMBER"
    echo -e "$newenvelopefrom has been trying to contact me. He/She wrote: $newbody" | $signalclipath send $NEWPHONENUMBER
  fi
done
