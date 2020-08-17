# Implementing a container cloud architecture. 

#### We will deploy application in Dotnet Core 3.1 in Docker Containers to Container Registry in Azure, creating a Kubernetes Cluster with MiniKube.

## Introduction:
#### The evolution of technology, the decentralization of data, the speed of innovation, adaptation to changes, has led us to think of a new way of developing software, which has led us to a new way of designing our solutions.
#### The cloud paradigm has made us rethink the correct use of resources.
#### The container architecture allows us to have small instances of our software components, but in order to achieve this we need to understand how they are orchestrated, managed, deployed, they grow, or they are reduced, etc.


## 1. Requirements

#### In this scenario we are going to work with windows computers Using Visual Studio Code using PowerShell as Console

Visual Studio Code
https://code.visualstudio.com/

Dotnet Core SDK 3.1
https://dotnet.microsoft.com/download/dotnet-core/thank-you/sdk-3.1.201-windows-x64-installer

Git
https://github.com/git-for-windows/git/releases/download/v2.26.2.windows.1/Git-2.26.2-64-bit.exe

Docker

https://docs.docker.com/docker-for-windows/install/

* Note that Docker installation requires that they enable Hypertreading on their machines, verify that docker is running

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/0.JPG?raw=true)

Azure Cli

https://docs.microsoft.com/es-es/cli/azure/install-azure-cli-windows?view=azure-cli-latest#install-or-update

Kubernetes

`Install-Script -Name install-kubectl -Scope CurrentUser -Force`
`install-kubectl.ps1`

Choco, to install Terraform

`Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`

MiniKube
`$ choco install minikube kubernetes-cli`

## 2. Create project

Create a new folder to work
`mkdir myproject`
`cd myproject`

Now we will create a new application using DotNet Core and specifying the Web App template, this will create a folder with everything necessary for our first application.
`dotnet new webapp`

Now we restore the solution so that it implements the packages of the dependencies that we could have.
`dotnet restore ./`

Build the solution.
`dotnet build ./`

Publish the solution, it will create a folder with the binaries in a folder within our project bin/Release/netcoreapp3.1/publish/
`dotnet publish -c Release`

If we want to see our solution running we execute the following command and open our browser on localhost in the indicated port.
`dotnet run  ./`

## 3. Mount it inside a Docker container on our local machine

Inside our project we create a file called Dockerfile
`New-Item -Path './Dockerfile' -ItemType File`

We open the file with Visual Studio Code
`code ./Dockerfile`


We copy the following code, replacing the tag with the name of our project
```
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1

COPY bin/Release/netcoreapp3.1/publish/ App/
WORKDIR /App
ENTRYPOINT ["dotnet", "myproject.dll"]

```
In the previous code the first line tells us that we are going to take the image published by Microsoft for aspnet Projects in DotNetCore 3.1
In the next block of lines we specify that we are going to copy the content of our publication folder, that is, the binaries inside a folder called App/ and we put a ENTRYPOINT to run "dotnet myproject.dll" at startup.

Now we return to the console in the same path where our Dockerfile is, we built it and labeled it with version one
`docker build ./ --tag "myproject:1"`

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/1.JPG?raw=true)

With the above docker will build an image which we can see if we execute
`docker images`

To get inside the cluster and run the image, run
`docker run -it -p 80:80 myproject:1`

With the previous one, Docker will implement the image inside a container, where with -p we specify that it will map port 80 of our machine to port 80 of the container.

To see it working, we open our browser on localhost, we must make sure that there is no other application using port 80, failing that we can map some other port.

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/2.JPG?raw=true)


If we want to see the containers running we can run
`docker ps`



### 4. MiniKube


```
cd ..
mkdir yaml
cd ./yaml

```

Create a file to define our deployment and the service of this deployment.
`New-Item -Path './Deploymeny-Service.yaml' -ItemType File` `
With the content.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myimage
  labels:
    app: myimage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myimage
  template:
    metadata:
      labels:
        app: myimage
    spec:
      containers:
        - name: myimage
          image: myacr.azurecr.io/myproject:1
          ports:
            - containerPort: 80
          env:
            - name: ASPNETCORE_ENVIRONMENT
              value: dev
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: myimage321
  name: myimage-service
spec:
  type: LoadBalancer
  ports:
   - port: 80
  selector:
    app: myimage
```

In the previous code block, the kind Deployment defines that we are going to start a new definition for a Deployment.

The attributes that we are going to replace are:

* name: myimage // which is how it will be identified within the cluster, to continue with the same standard we will put the same name that we put to our local docker "myimage" defined in the variable $imageName.
* replicas: 1 // it goes within spect and it is how many replicas this service will be able to have, that is, the number of pods it can create to manage its scalability.
* image:  myacr.azurecr.io/myproject:1 // The url of the image inside the ACR as previously defined, we have this in the variable.


the "---" indicator specifies that we are going to start with another object; the following we are going to create a service defining the kind: Service.

The attributes that we are going to replace are
* name: myimage-service // we define what our service will be called
* service.beta.kubernetes.io/azure-dns-label-name: myimage321 // 
it must be and unique name to create the dns inside of Azure Region and associate with the public created IP
* app: myimage321 // the name of the created deployment

Guardamos el archivo y las aplicaciones con Kubernetes.

`kubectl apply -f .\Deploymeny-Service.yaml`

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/17.JPG?raw=true)

In order to see the created pods from the terminal, we execute.

`kubectl get pods`

To be able to see the deployments.

`kubectl get deployments`

To see the services

`kubectl get services`

Here we can see the external IP
![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/18.JPG?raw=true)

Likewise we can ask Kubernetes to describe each object, to describe the service we execute.

`kubectl describe services myimage-service`

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/19.JPG?raw=true)

If there are no errors, it will show us the dns label and we will be able to show our application from the browser, leaving a url composed of the name of dns that we define, the region and the domain of apps from Azure "http://myimage321.eastus.cloudapp.azure.com/"

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/20.JPG?raw=true)

A useful tool to manage the cluster is the Terraform Board, to start it we execute.

`az aks browse --resource-group $groupName  --name $aksName`
This will not open a browser window.

![](https://github.com/internetgdl/KubernetesAzure/blob/master/images/21.JPG?raw=true)


With this we have finished

So if you have any questions please feel free to contact me.

* Email: eduardo@eduardo.mx
* Web: [Eduardo Estrada](http://eduardo.mx "Eduardo Estrada")
* Twitter: [Twiter Eduardo Estrada](https://twitter.com/internetgdl "Twiter Eduardo Estrada")
* LinkedIn: https://www.linkedin.com/in/luis-eduardo-estrada/
* GitHub: [GitHub Eduardo Estrada](https://github.com/internetgdl "GitHub Eduardo Estrada")
* Eduardo Estrada
