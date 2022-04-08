#/bin/bash
echo "Goedendag, welkom bij het self-service portaal."

while true; do
    read -p $'Wilt u een nieuwe omgeving aanvragen? of een bestaandomgeving aanpassen? \n a) Nieuwe omgeving \n b) Bestaande omgeving aanpassen \n Vul hier uw antwoord in:' ab
    case $ab in
        [Aa]* ) taak=nieuwe; break;;
        [Bb]* ) taak=bestaand; break;;
    esac
done

if [[ $taak == "bestaand" ]] 
then
    ./change.sh
    exit
fi


echo wat is uw klantnummer
read klantnummer

echo wat is uw klantnaam
read klantnaam

echo Hoeveel web servers wil je
read aantal_webservers

while true; do
    read -p $'Wil je een test of prodductie omgeving? \n a) test \n b) productie \n Vul hier uw antwoord in: ' ab
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

echo Uw opgegeven klantnummer: $klantnummer
echo Uw opgegeven klantnaam: $klantnaam
echo Uw opgegeven aantal webservers: $aantal_webservers

mkdir -p /home/student/IAC/klanten/$klantnummer/$omgeving

klantdir=/home/student/IAC/klanten/$klantnummer/$omgeving
klantnet=192.168.$klantnummer
klantkey=/home/student/.ssh/id_rsa_$klantnummer-$omgeving

#Webserver array op basis van het aantal webservers
declare -a webserver_array=()
for ((i=1; i<=$aantal_webservers; i++)); do
    webserver_array+=("$klantnaam-$klantnummer-web-$i-$omgeving")
done

ssh-keygen -f $klantkey
ssh-add $klantkey

cp /home/student/IAC/vagrant-files/"$omgeving-Vagrantfile" $klantdir/Vagrantfile
cp /home/student/IAC/config-files/haproxy.cfg $klantdir/haproxy.cfg

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
ansibleplaybook="$omgeving-omgeving.yaml"
cp /home/student/IAC/playbooks/$ansibleplaybook $klantdir/$ansibleplaybook
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
#cp /home/student/IAC/config-files/haproxy.cfg $klantdir/haproxy.cfg

lb1="${klantnaam}-${klantnummer}-lb-1-${omgeving}"
db1="${klantnaam}-${klantnummer}-db-1-${omgeving}"

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

#Toevoegen van loadbalancer aan /etc/hosts
if [[ $omgeving == "test" ]]
then
    echo "$klantnet.10 $lb1" | sudo tee -a /etc/hosts
elif [[ $omgeving == "productie" ]]
then
    echo "$klantnet.20 $lb1" | sudo tee -a /etc/hosts
    echo "$klantnet.29 $db1" | sudo tee -a /etc/hosts
fi

#Toevoegen van webservers aan ansible inventory
echo "[webservers]" | tee -a $klantdir/inventory
for i in "${webserver_array[@]}"
do
    echo "$i ansible_user=vagrant" | tee -a $klantdir/inventory
done

#Toevoegen van loadbalanver & database aan ansible inventory
echo "[loadbalancer]" | tee -a $klantdir/inventory
echo "$lb1 ansible_user=vagrant" | tee -a $klantdir/inventory

if [[ $omgeving == "productie" ]]
then
    echo "[database]" | tee -a $klantdir/inventory
    echo "$db1 ansible_user=vagrant" | tee -a $klantdir/inventory
fi

cd $klantdir
vagrant up


#ssh-keyscan voor de loadbalancer
if [[ $omgeving == "test" ]]
then
    ssh-keyscan $lb1 $klantnet.10 >> /home/student/.ssh/known_hosts
elif [[ $omgeving == "productie" ]]
then
    ssh-keyscan $lb1 $klantnet.20 >> /home/student/.ssh/known_hosts
    ssh-keyscan $db1 $klantnet.29 >> /home/student/.ssh/known_hosts
fi


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


cd $klantdir
ansible all -i inventory -m ping
ansible-playbook -i inventory $klantdir/$ansibleplaybook
#ansible-playbook -i inventory /home/student/vagrant/playbooks/webserver.yaml
#ansible-playbook -i inventory /home/student/vagrant/playbooks/loadbalancer.yaml