declare -a webserver_array=()

aantal_webservers=5
klantnaam="tyme"
klantnummer=60
omgeving="test"

for ((i=1; i<=$aantal_webservers; i++)); do
    webserver_array+=("$klantnaam-$klantnummer-web-$i-$omgeving")
done

for i in "${webserver_array[@]}"
do
    echo "$i ansible_user=vagrant"
done

for ((i=1; i<=$aantal_webservers; i++)); do
    webserver_array+=("$klantnaam-$klantnummer-web-$i-$omgeving")
done


#voor ansbile inventory file
for i in "${webserver_array[@]}"
do
    echo "$i ansible_user=vagrant"
done

#voor /etc/hosts
ip_addr=11
for i in "${webserver_array[@]}"
do
    echo $klantnet.$ip_addr "$i"
    ((ip_addr+=1))
done

ip_addr=11
#Voor ssh-keyscan
for i in "${webserver_array[@]}"
do    echo "$i"   $klantnet.$ip_addr

    ((ip_addr+=1))
done


echo "$klantnet.11   $web1" | sudo tee -a /etc/hosts

echo "[webservers]" | tee -a $klantdir/inventory
echo "$web1 ansible_user=vagrant" | tee -a $klantdir/inventory

ssh-keyscan "$web1" $klantnet.11 >> /home/student/.ssh/known_hosts


for ((i=1; i<=$aantal_webservers; i++)); do
    webserver_array+=("$klantnaam-$klantnummer-web-$i-$omgeving")
done

ip_addr=11
for i in "${webserver_array[@]}"
do    
    echo -e "\n- name: Update web servers
  hosts: $i ansible_user=vagrant
  become: true" >> $klantdir/test_omgeving.yaml
done

#Custom gemaakt .hmtl
for i in "${webserver_array[@]}"
do    
    cp /home/student/IAC/website-files/index.html $klantdir/$i.html
    sed -i "s+webserver+$i+g" $klantdir/$i.html
done

ip_addr=11
for i in "${webserver_array[@]}"
do    
    echo -e "\t\tserver \t$i"   $klantnet.$ip_addr:80 >> $klantdir/haproxy.cfg
    ((ip_addr+=1))
done


while true; do
    read -p $'Hoeveel werkgeheugen moeten de webservers hebben? \n a) 512 \n b) 1024 \n Vul hier uw antwoord in: ' ab
    case $ab in
        [Aa]* ) werkgeheugen=512; break;;
        [Bb]* ) werkgeheugen=1024; break;;
    esac
done

while true; do
    read -p $'Wil je een test of prodductie omgeving? \n a) test \n b) productie \n Vul hier uw antwoord in: ' ab
    case $ab in
        [Aa]* ) omgeving=test; break;;
        [Bb]* ) omgeving=productie; break;;
    esac
done

echo "Werkgeheugen = $werkgeheugen"
echo "Omgeving = $omgeving"