## messagebank
This project presents an example how to utilize a Message Bank InterSystems IRIS Interoperability solution. The Message Bank receives Messages and Logs from other InterSystems IRIS Productions so they can be viewed or resent. This is very handy if you have multiple productions running.

## What The Message Bank Does
The Message Bank has an interoperability [production](https://github.com/oliverwilms/messagebank/blob/master/src/MessageBank/Production.cls) with two Services.
<img width="1411" alt="Screenshot of Production" src="https://github.com/oliverwilms/bilder/blob/main/Capture_MessageBank_Production.PNG">

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation: ZPM

Create if necessary and open Terminal (IRIS session) in IRIS Namespace with Interoperability enabled:
MESSAGEBANK>zpm "install messagebank"

## Installation: Docker
Clone/git pull the repo into any local directory

```
$ git clone https://github.com/oliverwilms/messagebank.git
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

3. Run the IRIS container with your project:

```
$ docker-compose up -d
```



## How to Run the Message Bank

docker run --init --detach -p 9192:9192 -p 52773:52773 -p 51773:51773 --name messagebank --volume mbk-vol:/voldata --env ISC_DATA_DIRECTORY=/voldata/iconfig --env ISC_CPF_MERGE_FILE=”/ICS/merge.cpf” --volume /hostinfo:/hostinfo --volume /efs/ICS:/ICS messagebank -b /ICS/vcopy.sh

vcopy.sh copies IRIS data base files from the image to Message Bank volume (mbk-vol) before IRIS starts running in the container.

Open the [production](http://localhost:52795/csp/messagebank/EnsPortal.ProductionConfig.zen?PRODUCTION=MessageBank.Production) and start it if it is not running already.

I use IRIS Interoperability production in AWS Elastic Container Service. We have a file on host volume at /hostinfo/host.config with the Host IP Address. I use a CPF Merge file to define the ECP Server that I use to store data in mapped globals in a remote database. When the Message Bank Production starts and stops, I update a global with information about the Message Bank, so that containers running another IRIS Interoperability production can update their Message Bank Operation setting with the IP Address to find the Message Bank. 

## How to Look for and Resend Messages

You can use the portal to identify and resend messages, or you can automate this task.

## Task to Schedule Resend

Create a new Task in System Management Portal via System Operation > Task Manager. Choose MESSAGEBANK namespace to be able to find the Message Bank Resend task:
<img width="1411" alt="Screenshot of Production" src="https://github.com/oliverwilms/bilder/blob/main/Capture_MessageBank_NewTask.PNG">

## Automate Resending Messages

Once the Message Bank Resend Task is defined and scheduled, it will check for messages that need to be resent and attempt to automatically resend them.

## Message Resend Status Persistent Table

There is a built on persistent class where you can see Resend Status details.
Created code to locate messages
