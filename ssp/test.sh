declare -a webserver_array=()

aantal_webservers=1
klantnaam="bob"
klantnummer=5
omgeving="productie"
klantnet=192.168.$klantnummer
#klantdir=/home/student/IAC/klanten/"$klantnummer"

for ((i=1; i<=$aantal_webservers; i++)); do
    webserver_array+=("$klantnaam-$klantnummer-web-$i-$omgeving")
done


#ssh-keyscan voor de webservers
if [[ $omgeving == "test" ]]
then
    ip_addr=11
elif [[ $omgeving == "productie" ]]
then
    ip_addr=21
fi

for i in "${webserver_array[@]}"
do
    ssh-keyscan "$i" $klantnet.$ip_addr >> /home/student/.ssh/known_hosts
    ((ip_addr+=1))
done