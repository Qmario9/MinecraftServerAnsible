# MineCraft Server

Today we will be installing a Minecraft server with Ansible and Terraform(and a few other scripts) using AWS!
<br>
### To run
Make sure you have cloned the repo and changed the following down below in the requirements before you do these steps!
> terraform init

> terraform plan

> ansible-playbook -i hosts.yaml anstemp.yaml


### Some common errors
* Cannot have a paraphrase in the key pair
* Make sure you change all the keys and directory and credentials in the files

### **Requirements**

### Tools
We will be using ansible and terraform as mentioned.

MacOS
> brew install ansible terraform

Linux
> sudo apt install -y ansible terraform

### Credentials
There is a credential file that you will need to add your AWS credentials in order for terraform to be able to access AWS.
* aws_access_key_id
* aws_secret_access_key
* aws_session_token

### SSH key pair
You will need to create a SSH key pair, however you want to get it done. After you have created them, you will need to change the file name in both anstemp.yaml and main.tf files. You may keep your pair in the main directory.

anstemp.yaml
>       vars:
>           private_key_path: "change_your_ssh_private_key_file"

main.tf
>       resource "aws_key_pair" "my_key_pair" {
>           key_name   = "my-key-pair"  
>           public_key = file("change_your_public_key_file")
>       }

<br>
<br>

### Your path directory
Make sure you change it on the anstemp.yaml file

<br>
<br>

### **What is going on?**
Here are all the steps of the pipeline which we will go into individually.
* Terraform creates EC2 instance
* Retreiving terraform output
* Set instance IP as a variable
* Add a host to dynamic_inventory
* Change hosts
* Install packages
* Copy all the scripts in /scripts to the instance
* Move each script to it's respective folder in the isntance
* Run service

<br>
<br>

#### **Terraform creates EC2 instance**
There are three main focuses here, aws_security_group, provider and aws_insatnce. 
* **aww_security_group:**
This is where the inbound and outbound rules are set. We will need two ports opened, port 22 and 25565(SSH and Minecraft). They will both need to allow traffic from anywhere in order to be able to connect to it later.

>       ingress {
>           from_port   = 25565
>           to_port     = 25565
>           protocol    = "tcp"
>           cidr_blocks = ["0.0.0.0/0"]
>       }
>       ingress {
>           from_port   = 22
>           to_port     = 22
>           protocol    = "tcp"
>           cidr_blocks = ["0.0.0.0/0"]
>       }

* **provider:**
The credintials, region and profile are set here. After you have added your AWS credentials make sure that it is indeed working. Make sure region is set to us-east-1.
>       provider "aws" {
>           region = "us-east-1"
>           shared_credentials_files = ["credentials"]
>           profile = "default"
>       }

* **aws_instance:**
Inside this block is where we choose the ami and instance type, however the focus is on transferring a script and running that script as it's initializing.
>       provisioner "file" {
>           source="scripts/script.sh"
>           destination="/tmp/script.sh"
>       }
>       provisioner "remote-exec" {
>           inline = [
>               "chmod +x /tmp/script.sh",
>               "sudo bash /tmp/script.sh"
>           ]
>       }
>       connection {
>           type        = "ssh"
>           user        = "ubuntu"
>           private_key = file("finalProj")
>           host        = self.public_ip
>       }
Provisioer "file" sends the script over, provisioner "remote-exec" runs the necessary commands to run the script, and connection allows to connect for remote execution.
<br>
<br>

#### **Retreiving terraform output**
All this task does is it retrieves the output we set in the main.tf file. Although it is a small task, it is very critical in getting the instance ip address to the ansible script for further use. We then use that output to set as a variable.

>       - name: Set dynamic host for the created instance
>           set_fact:
>           instance_ip: "{{ terraform_output.stdout | regex_replace('\"', '') }}"

<br>


#### **Add a host to dynamic_inventory**
Now that we were able to get the IP address of the instance as shown above, we are able to dynamically add a new host. This requires the following:
* name(the name of the host which we will use next)
* ansible_host
* ansible_ssh_private_key_file
* ansible_user
* ansible_connections
* ansible_ssh_common_args

<br>

#### **Change hosts**
Up until now, we have been using localhost as our host, however now we need to run scripts inside the isntance we created. We are able to do this by using the host we created above. We start a new playbook witha different host.
>       - name: Install Packages on Instance
>           hosts: newHost
>           gather_facts: false
>           #become: true
>           become_user: ubuntu

<br>

#### **Install packages**
Now that we are connected to our instance, we are able to run commands including the ones we need for our Minecraft server. This includes:

> sudo apt update

> sudo apt install -y openjdk-17-jdk openjdk-17-jre

Which happen first before we can transfer any scripts.

<br>

#### **Copy all the scripts in /scripts to the instance**
We have a couple of scripts that need to be sent to our instance, which was simple to accomplish with this task:

>       - name: Transferring scripts
>           copy:
>           src: scripts/
>           dest: /home/ubuntu
>           mode: 0755

It takes the scripts directory from our local host and sends it to our instance, specifically at /home/ubuntu.

<br>

#### **Move each script and run service**
Now we disperse! Send all the script files to their respective place. 

Finally, after everything is set and ready, ansible finished, we are ready to WAIT some more. Although service is up and ready, it takes 2-3 minutes for the server to fully be ready. After a few minutes have past now we are ready to connect to our Minecraft server.

> telnet < instance ip > 25565

<br>
<br>
<br>

## Honorable Mentions
Scripts and what they do:
* **script.sh:** This is ran during the terraform process. This creates the directory /opt/minecraft/server which is our working directory. It also downloads the minecraft server into this directory to be ready to use. Finally, it allows user ubuntu to have sudo priveliges to be able to install packages later on.

* **eula.sh:** This script gets put to use after all the scripts have been sent and placed correctly. This runs the minecraft server for the first time
> java -Xmx1024M -Xms1024M -jar server.jar nogui

when it runs the for the first time it outputs an error stating the we need to agree to minecraft "". After that, we run 
> sed -i 's/false/true/g' eula.txt

This just agrees.
Finally, we enable and start the service.
> sudo systemctl daemon-reload
>
> sudo systemctl enable mineFinal.service
>
> sudo systemctl start mineFinal.service

