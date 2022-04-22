#!/bin/bash

#temp file is used to store DSL Query and is removed at the end of the script
temp_file="./temp_file_pulse"
#rm temp file if already in system
rm $temp_file &> /dev/null
#normalize pulse output file 

#handle file if passed via arg
if [ -f "$1" ];then
    initial_var=$(sed -n '1,500 p' "$1"|tr "\n" ","|sed '$ s/.$//')
    input_file="$1"
    echo "File detected."
else
    initial_var="$1"
    echo "User Input Detected."
fi
clean_data(){
    unset initial_var
    if [ -f "$input_file" ];then
        echo "cleaning file"
        initial_var="$(tail -n +2 "$input_file"|cut -d , -f 1|sed 's/\"//g'|sed -n '1,500 p'|tr "\n" ","|sed '$ s/.$//')"
        echo "File detected."
    else
        read -p "Pulse Output file to 'normalize': " input_file
        initial_var="$(tail -n +2 "$input_file"|cut -d , -f 1|sed 's/\"//g'|sed -n '1,500 p'|tr "\n" ","|sed '$ s/.$//')"
        echo "User Input Detected."
    fi
        
        echo "$initial_var"|pbcopy
        echo "Copied to clipboard"
        dirty_lines=$(wc -l < $input_file)
        if [[ $dirty_lines -gt 500 ]];then
            #assume file has more than 500 lines
            printf "\n\nPaste content to approriate section before moving on"
            read -p "Press Enter when ready for the next batch"
            counter=1
            while [[ $dirty_lines -gt 500 ]];do
                counter=$(($counter + 500))
                initial_var=$(tail -n +2 "$input_file"|cut -d , -f 1|sed 's/\"//g'|sed -n "$counter,$(($counter + 500)) p"|tr '\n' ','|sed '$ s/.$//')
                echo "$initial_var"|pbcopy
                echo "copied lines: $counter through $(($counter + 500))"
                printf "\n\nPaste content to approriate section before moving on:\n"
                read -p "press enter when ready for the next batch"
                dirty_lines=$(($dirty_lines - 500))
                done
        
        
        fi
}       
######### user name option
username_func(){
    if [ -z "$initial_var" ]; then
        read -p "Paste usernames (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    #clean data by removing new lines
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        #loop to use each value to create a json query
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"match_phrase\": {
                \"username\": \"${pulse_value}\"
            }
            },";done)
        echo -e "$pulse_body"|sed \$d >> $temp_file
        unset $pulse_body
}
image_func(){
    if [ -z "$initial_var" ]; then
        read -p "Paste usernames (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"match_phrase\": {
                \"image\": \"${pulse_value}\"
            }
            },";done)
        echo -e "$pulse_body"|sed \$d >> $temp_file
        unset $pulse_body
}

url_func(){
    ######### Geo Location option 
    if [ -z "$initial_var" ]; then
        read -p "Paste URLs (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "{
        \"wildcard\": {
        \"meta.links.results\": \"${pulse_value}*\"
        }
    },";done)
echo -e "$pulse_body"|sed \$d >> $temp_file
unset $pulse_body
}

geo_func(){
    ######### Geo Location option 
    if [ -z "$initial_var" ]; then
        read -p "Paste Locations (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
        {
        \"wildcard\": {
        \"author_place\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"meta.geo_place.results.value\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"meta.author_geo_place.results.value\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"doc.place.full_name\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"doc.place.country\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"doc.place.name\": \"${pulse_value}*\"
        }
    },
    {
        \"wildcard\": {
        \"meta.ml_ner.results.location.text\": \"${pulse_value}*\"
        }
    
    },";done)
echo -e "$pulse_body"|sed \$d >> $temp_file
unset $pulse_body
}
hashtag_func(){
    ######### hashtag option meta.hashtag.results
    if [ -z "$initial_var" ]; then
        read -p "Paste Hashtags (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
        pulse_body=$(IFS=","
        for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"wildcard\": {
                \"meta.hashtag.results\": \"${pulse_value}*\"
            }
            },
            {
            \"match_phrase\": {
                \"doc.user.description\": \"${pulse_value}\"
            }
            },";done)
    echo -e "$pulse_body"|sed \$d >> $temp_file
    unset $pulse_body
}
custom_exact(){
    pulse_body=$(IFS=","
    for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"match_phrase\": {
                \"$custom_var\": \"${pulse_value}\"
            }
            },";done)
    echo -e "$pulse_body"|sed \$d >> $temp_file
    unset $pulse_body
}
custom_wildcard(){
    pulse_body=$(IFS=","
    for fullWord in $pulse_var;do
        pulse_value=$(echo "$fullWord"|sed 's/"//g'|sed 's/^ //g')
        echo -e "
            {
            \"wildcard\": {
                \"$custom_var\": \"${pulse_value}*\"
            }
            },";done);break
    echo -e "$pulse_body"|sed \$d >> $temp_file
    unset $pulse_body
}
custom_func(){
    ######### hashtag option meta.hashtag.results
    read -p "custome metadata labeel: " custom_var
    if [ -z "$initial_var" ]; then
        read -p "Paste metadata value (sep. with comma): " initial_var
        if [ -z "initial_var" ];then
            #if user did not input name then get name from url
            initial_var="$*"
        fi
    fi
    pulse_var=${initial_var//$'\n'/}
    #prepare for loop
    

    #prompt for wildcard or not
    PS3='Please enter your choice: '
    options=("Wildcard" "Exact Match" "Quit")
    select opt in "${options[@]}";do
        case $opt in
            "Wildcard")
                custom_wildcard;break
                ;;
            "Exact Match")
                custom_exact;break
                ;;
            "Quit")
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
    
        
}
header(){
    echo -e "
    {
    \"query\": {
        \"bool\": {
        \"minimum_should_match\": 1,
        \"should\": [
        " >> $temp_file
}
footer(){
    #print out the body above minus 1 line to snip that last comma
    printf "}\n]\n}\n}\n}" >> $temp_file
    cat $temp_file |pbcopy && echo "copied to clipboard"
    rm $temp_file
}

#print header data to temp file
header

#menu to prompt user for option
PS3='Please enter your choice: '
options=("Usernames" "Hashtags" "Locations" "URLs" "Images" "Custom" "Clean Data" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Usernames")
            username_func;footer;break
            ;;
        "Hashtags")
            hashtag_func;
            footer;break
            ;;
        "Locations")
            geo_func;
            footer;break
            ;;
        "URLs")
            url_func;
            footer;break
            ;;
        "Images")
            image_func;
            footer;break
            ;;
        "Custom")
            custom_func;
            footer;break
            ;;
        "Clean Data")
            #this will loop back into menu to allow user to do stuff with that data that is cleaned
            clean_data;
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

