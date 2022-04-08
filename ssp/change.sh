#/bin/bash

echo omgeving aanpassen

echo wat is uw klantnummer
read klantnummer

echo wat is uw klantnaam
read klantnaam

while true; do
    read -p $'Wil je de test of prodductie omgeving aanpassen? \n a) test \n b) productie \n Vul hier uw antwoord in: ' ab
    case $ab in
        [Aa]* ) omgeving=test; break;;
        [Bb]* ) omgeving=productie; break;;
    esac
done


while true; do
    read -p $'Hoeveel werkgeheugen moeten de webservers hebben? \n a) 1024 \n b) 2048 \n Vul hier uw antwoord in: ' ab
    case $ab in
        [Aa]* ) werkgeheugen=1024; break;;
        [Bb]* ) werkgeheugen=2048; break;;
    esac
done

echo Hoeveel web servers wil je
read aantal_webservers

echo Uw opgegeven klantnummer: $klantnummer
echo Uw opgegeven klantnaam: $klantnaam
echo Uw opgegeven aantal webservers: $aantal_webservers

klantdir=/home/student/IAC/klanten/$klantnummer/$omgeving
klantnet=192.168.$klantnummer
klantkey=/home/student/.ssh/id_rsa_$klantnummer-$omgeving

#Webserver array op basis van het aantal webservers
declare -a webserver_array=()
for ((i=1; i<=$aantal_webservers; i++)); do
    webserver_array+=("$klantnaam-$klantnummer-web-$i-$omgeving")
done

yes | cp -rf /home/student/IAC/vagrant-files/"$omgeving-Vagrantfile" $klantdir/Vagrantfile
yes | cp -rf /home/student/IAC/config-files/haproxy.cfg $klantdir/haproxy.cfg

#Custom Vagrantfile maken
sed -i "s+klantnaam+$klantnaam+g" $klantdir/Vagrantfile
sed -i "s+klantnummer+$klantnummer+g" $klantdir/Vagrantfile
sed -i "s+aantal_webservers+$aantal_webservers+g" $klantdir/Vagrantfile
sed -i "s+omgeving+$omgeving+g" $klantdir/Vagrantfile
sed -i "s+werkgeheugen+$werkgeheugen+g" $klantdir/Vagrantfile
sed -i "s+klantkey+$klantkey+g" $klantdir/Vagrantfile

#Custom gemaakt .php
for i in "${webserver_array[@]}"
do    
    cp /home/student/IAC/website-files/index.php $klantdir/$i.php
    sed -i "s+webserver+$i+g" $klantdir/$i.php
    sed -i "s+dbserver+$klantnet.29+g" $klantdir/$i.php
done

#Custom gemaakt ansible playbook
ansibleplaybook="webserver.yaml"
yes | cp -rf /home/student/IAC/playbooks/$ansibleplaybook $klantdir/$ansibleplaybook
for i in "${webserver_array[@]}"
do    
    echo -e "\n
- name: Update web servers
  hosts: $i ansible_user=vagrant

  become: true
  tasks:

  - name: Provision php file
    ansible.builtin.copy:
      src: '$i.php'
      dest: /var/www/html/index.php" >> $klantdir/$ansibleplaybook
done

#Custom gemaakte haproxy.cfg
if [[ $omgeving == "test" ]]
then
    ip_addr=11
elif [[ $omgeving == "productie" ]]
then
    ip_addr=21
fi

for i in "${webserver_array[@]}"
do    
    echo -e "\t\tserver \t$i"   $klantnet.$ip_addr:80 >> $klantdir/haproxy.cfg
    ((ip_addr+=1))
done

#Toevoegen van webservers aan /etc/hosts
if [[ $omgeving == "test" ]]
then
    ip_addr=11
elif [[ $omgeving == "productie" ]]
then
    ip_addr=21
fi

for i in "${webserver_array[@]}"
do
    echo $klantnet.$ip_addr "$i" | sudo tee -a /etc/hosts
    ((ip_addr+=1))
done


#Toevoegen van webservers aan ansible inventory
echo "[webservers]" | tee -a $klantdir/inventory
for i in "${webserver_array[@]}"
do
    echo "$i ansible_user=vagrant" | tee -a $klantdir/inventory
done

cd $klantdir
vagrant up

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

ansible-playbook -i inventory $klantdir/$ansibleplaybook

