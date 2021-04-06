# Minikube deployment

AMPLIFY API-Management solution has been deployed on minikube 1.16 installed on Windows 10 Enterprise using HYPER-V.

**The following instruction are based on this setup.**

## Prerequisites
- Install HELM V3 -> https://helm.sh/docs/intro/install/
- Install kubectl  -> https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/

- Only for Windows 10 and HYPER-V
    1. Open "Hyper-V Manager", go into "Virtual Switch Manager"
    2. Create a New virtual network switch
        Name : **InternalSwitch**
        Connection type : **Internal network**
    3. Click **Apply** button then **OK**

        ![hyperv](./img/HYPER-V_adapter.JPG)

    4. Open the network adapters panel and share your working internet connection.
    *In this case, I am going to share my WIFI connection with the virtual switch*
    - Go on Control Panel > Network and Internet > Network Connections > Wi-Fi > Right Click > Properties > Sharing > 
    - Check “Allow other network users to connect…” > Select the Virtual Switch you just created from the drop-down menu).
        ![network_sharing](./img/Network_sharing.JPG)

## Deployment

1. Install Minikube.

    Follow Step 1 (**and ONLY step 1**) from offical guide to install your minikube **depending on your target environment** : 
    https://minikube.sigs.k8s.io/docs/start/
    
2. Configure your minikube ressources.

    APIM deployment required **4vCPU and 6Go RAM** availability so you need to configure Minikube as such.
    
    Execute the two following commands to set up ressources :
    ```bash
    minikube config set cpus 4
    ```

    ```bash
    minikube config set memory 6000
    ```

    Expexted output
    ```bash
    ! These changes will take effect upon a minikube delete and then a minikube start
    ```

    And then you need to delete minikube previous setup :
    ```bash
    minikube delete
    ```

3. Start minikube

    - If you are using Windows, consider using HYPER-V and follow guide here :
    https://minikube.sigs.k8s.io/docs/drivers/hyperv/
    
    - If you are using MAC OS, consider using VirtualBox and follow guide here :
    https://minikube.sigs.k8s.io/docs/drivers/virtualbox/

    - If you are using Linux, consider using KVM2 or Docker and follow guide here :
    https://minikube.sigs.k8s.io/docs/drivers/docker/
    https://minikube.sigs.k8s.io/docs/drivers/kvm2/

    For this example, we are running on Windows 10 so starting Minikube command will be :
    ```bash
    minikube start --vm-driver hyperv --hyperv-virtual-switch "InternalSwitch"
    ```

    Expexted output example
    ```bash
    * minikube v1.xx.0 sur Microsoft Windows 10 Enterprise 10.0.19042 Build 19042
    * minikube 1.xx.0 est disponible ! Téléchargez-le ici : https://github.com/kubernetes/minikube/releases/tag/v1.xx.0
    * To disable this notice, run: 'minikube config set WantUpdateNotification false'
    
    * Utilisation du pilote hyperv basé sur la configuration de l'utilisateur
    * Downloading VM boot image ...
        > minikube-v1.13.1.iso.sha256: 65 B / 65 B [-------------] 100.00% ? p/s 0s
        > minikube-v1.13.1.iso: 173.91 MiB / 173.91 MiB [] 100.00% 65.30 MiB p/s 2s
    * Démarrage du noeud de plan de contrôle minikube dans le cluster minikube
    * Downloading Kubernetes v1.19.2 preload ...
        > preloaded-images-k8s-v6-v1.19.2-docker-overlay2-amd64.tar.lz4: 486.33 MiB
    * Création de VM hyperv (CPUs=4, Mémoire=6000MB, Disque=20000MB)...
    * Préparation de Kubernetes v1.19.2 sur Docker 19.03.12...
    * Verifying Kubernetes components...
    * Enabled addons: storage-provisioner, default-storageclass
    * Done! kubectl is now configured to use "minikube" by default
    ```

4. Activate ingress plugin.

    Enabling the add-on provisions the following:
    - a configMap for the Nginx loadbalancer
    - the Nginx ingress controller
    - a service that exposes a default Nginx backend pod for handling unmapped requests.
    
    Command to activate ingress plugin :
    ```bash
    minikube addons enable ingress
    ```

    Expected output example
    ```bash
    * Verifying ingress addon...
    * The 'ingress' addon is enabled
    ```

    Verify Ingress is correctly running :
    ```bash
    kubectl get po -A
    ```

    Expected output example :
    ```bash
    ingress-nginx-admission-create-xxxx        0/1     Completed
    ingress-nginx-admission-patch-xxxx         0/1     Completed
    ingress-nginx-controller-799c9469f7-xxxx   1/1     Running
    ...
    ```
    
    You should have ingress-nginx-controller at running state.
   
    check the minikube addons
   ```bash
    minikube addons list
   ```

5. Install a certificat manager

    Execute the following command to install cert-manager :
    ```bash
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.1.1/cert-manager.yaml
    ```
    
    Check cert-manager is correctly running :
    ```bash
    kubectl get pods --namespace cert-manager
    ```

    Expected output example :
    ```bash
    cert-manager-cainjector-fc6c787db-xxxx   1/1     Running
    cert-manager-d994d94d7-xxxx              1/1     Running
    cert-manager-webhook-845d9df8bf-xxxx     1/1     Running
    ```

6. Update your HELM repository.

    You must update you HELM repository in order to be able to get the latest Axway charts for APIM solution.

    First, execute the following command to add axway repository :
    ```bash
    helm repo add axway 'https://axwaysourcesproducts.blob.core.windows.net/helm/?sv=2019-12-12&ss=b&srt=co&sp=rlx&se=2021-12-31T21:28:20Z&st=2021-01-25T13:28:20Z&spr=https&sig=%2FeVcNlH%2BqU8l4qZefbGNxaMhxSnDysmt4fq3ZGG5dRg%3D'
    ```
    *Note : key access (in the URL) for HELM repository is working until January 2022*

    Expected output :
    ```bash
    "axway" has been added to your repositories
    ```

    Then, perform an update :
    ```bash
    helm repo update
    ```

    Finally you check repository acces : 
    ```bash
    helm search repo
    ```

    Expected output example :
    ```bash
    NAME                    CHART VERSION   APP VERSION     DESCRIPTION
    axway/amplify-apim-7.7  1.2.0           7.7-*           Package for demo instance of Axway AMPLIFY API ...  
    ```
   
   因为axway chart repo更新慢，现将源代码下载下来，更新到本地jfrog jcr helm 仓库：
   https://github.com/samxu-tech/Cloud-Automation/tree/master/APIM/Helmchart
   
   在Jenkins服务器http://18.166.217.11:8080/
   运行pipeline: apim-helmchart
   
   然后在k8s服务器，更新并获取helmchart
   
   将helm chart获取到本地
   ubuntu@ip-172-31-6-168:~/helm/charts$ helm repo ls
   NAME            URL                                        
   helm-prod       http://art.local:8081/artifactory/helm-prod
   helm            http://art.local:8081/artifactory/helm  
   
   ubuntu@ip-172-31-6-168:~/helm/charts$ helm repo update
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "helm-prod" chart repository
   ...Successfully got an update from the "helm" chart repository
   Update Complete. ⎈Happy Helming!⎈
   
   ubuntu@ip-172-31-6-168:~/helm/charts$ cd /home/ubuntu/helm/charts
   ubuntu@ip-172-31-6-168:~/helm/charts$ helm fetch helm/amplify-apim-7.7 --untar
   
   ubuntu@ip-172-31-6-168:~/helm/charts$ ls
   amplify-apim-7.7  apim-old  foo  notebook
   
7. Deploy APIM using HELM.
    kubectl create namespace dev

    Execute the following command to deploy with minimal parameters :
    ```bash
    helm install amplify-apim-7.7 ./amplify-apim-7.7 --set global.domainName=kube.local.com,apitraffic.replicaCount=1 -n apim
    ```
    helm upgrade amplify-apim-7.7 ./amplify-apim-7.7 --reuse-values --set dynamicLicense=true -n apim2

    Expected output example :
    ```bash
    NAME: <HELM_RELEASE_NAME>
    LAST DEPLOYED: DD MM 22 hh:mm:ss YYYY
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ```

    Then you can execute the following command until all pods are running
    ```bash
    kubectl get po -A
    ```
    
    You should reach this status when APIM EMT is deployed :
    ```bash
    default        anm-67dcbb7669-ql4ft                                              1/1     Running            
    default        apimgr-6d7499587c-mqzgc                                           1/1     Running 
    default        cassandra-0                                                       1/1     Running
    default        db-create-mysql-apigw-4bdbbfa8-e96c-470f-96e1-36b2e742d9e4zf4qc   1/1     Running
    default        mysql-aga-b578b84d8-j5lrg                                         1/1     Running
    default        traffic-78f8c9c9fc-j87k2                                          1/1     Running
    ```
    
    You can also check ingress :
    ```bash
    kubectl get ingress -A
    ```

    Expected output example :
    ```bash
    NAMESPACE   NAME             CLASS    HOSTS                    ADDRESS           PORTS     AGE
    default     apimanager       <none>   api-mgr.kube.local.com   xxx.xxx.xxx.xxx   80, 443   11m
    default     gatewaymanager   <none>   anm.kube.local.com       xxx.xxx.xxx.xxx   80, 443   11m
    default     traffic          <none>   api.kube.local.com       xxx.xxx.xxx.xxx   80, 443   11m
    ```

8. Accessing UIs

    Access APIM UI 
    - Admin node manager UI : https://anm.kube.local.com/
    - API Manager UI : https://apimgr.kube.local.com/
    - API traffic : https://api.kube.local.com/healthcheck
    
    **For Windows 10**
    If you are on a Windows environment you first need to get Minikube IP address :
    ```bash
    minikube ip
    ```

    Expected output 
    ```bash
    <MINIKUBE_IP_ADDRESS>
    ```

    Then modify your **hosts** file located in "C:\Windows\System32\drivers\etc" and add the following line :
    ```bash
    <MINIKUBE_IP_ADDRESS> api.kube.local.com anm.kube.local.com api-mgr.kube.local.com
    ```

9. Uninstall using HELM

    If you want to delete APIM from Minikube, you can execute the following command :
    ```bash
    helm uninstall <HELM_RELEASE_NAME>
    ubuntu@ip-172-31-6-168:~/helm/charts$ helm uninstall amplify-apim-7.7 -n dev
    ```

    Expected output example
    ```bash
    release "<HELM_RELEASE_NAME>" uninstalled
    ```
    Delete namespace:
    ```bash
    kubectl delete namespaces dev
    ```
10. Stop Minikube

    If you want to stop minikube, you can execute the following command :
    ```bash
    minikube stop
    ```

11. Delete Minikube

    If you want to start again, you can delete minikube with the following command and go back to step 3 :
    ```bash
    minikube delete
    ```

## Troubleshooting

ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl get pods -n dev

ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl describe pods -n dev

ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl get deployment -n dev

### 0/1 nodes are available: 1 pod has unbound immediate PersistentVolumeClaims. 
ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl get pvc -n dev
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
apigw-events                 Bound    pvc-8120a975-6aa6-43bc-a89d-6fce3e2b30c9   1Gi        RWX            standard       54m
cassandra-data-cassandra-0   Bound    pvc-89f46ab8-b961-4deb-ac08-02bd99d7ebcf   2Gi        RWO            standard       54m
mysql-analytics-pvc          Bound    pvc-e45186e2-0810-4cf4-8161-2366c54d2570   10Gi       RWO            standard       54m

ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl get pvc apigw-events -n dev
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
apigw-events   Bound    pvc-8120a975-6aa6-43bc-a89d-6fce3e2b30c9   1Gi        RWX            standard       57m
ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl get pvc cassandra-data-cassandra-0 -n dev
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cassandra-data-cassandra-0   Bound    pvc-89f46ab8-b961-4deb-ac08-02bd99d7ebcf   2Gi        RWO            standard       57m
ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl get pvc mysql-analytics-pvc -n dev
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-analytics-pvc   Bound    pvc-e45186e2-0810-4cf4-8161-2366c54d2570   10Gi       RWO            standard       57m


### ImagePullBackOff
If you have a "ImagePullBackOff" error when executing "kubectl get po -A" command :
```bash
default        apimgr-6d7499587c-nrcq4          0/1     ImagePullBackOff 
```
    
Execute the following command to know more about it :
    
```bash
kubectl describe po <POD>
```
    
If you have an error of this type :
```bash
Failed to pull image "xxx": rpc error: code = Unknown desc = Error response from daemon: Get https://registry-1.docker.io/v2/: dial tcp: lookup registry-1.docker.io on 172.21.144.1:53: read udp 172.21.151.242:34660->172.21.144.1:53: i/o timeout
```
    
**It means your VM encounter difficulties to access Internet.**

To be sure, execute this command : 
```bash
minikube ssh "curl -v google.com"
```

Expected output example :
```bash
> GET / HTTP/1.1
> Host: google.com
> User-Agent: curl/7.66.0
> Accept: */*
>
< HTTP/1.1 301 Moved Permanently
< Location: http://www.google.com/
< Content-Type: text/html; charset=UTF-8
< Date: xxxx GMT
< Expires: xxx GMT
< Cache-Control: public, max-age=2592000
< Server: gws
< Content-Length: 219
< X-XSS-Protection: 0
< X-Frame-Options: SAMEORIGIN
<
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="http://www.google.com/">here</A>.
</BODY></HTML>
```

If ssh command return this, it confirm internet access issue :
```bash
* Could not resolve host: google.com
curl: (6) Could not resolve host: google.com
ssh: Process exited with status 6
```

**Solution 1** -> delete you minikube, reboot you computer or VM and start from step 3.

**Solution 2** -> make sure Docker repository is accessible and image with targeted build tag exists.


### Timeout
When you execute a command with minikube or kubectl cli, if you encounter this kind of issue : 
```bash
Unable to connect to the server: net/http: TLS handshake timeout
```

**It probably means you didn't allocate enough ressources to Minikube.**
Please make sure you follow step "2. Configure your minikube ressources."

### Cassandra pod Terminating
When you launch uninstall HELm command, cassandra pod can remains in Terminating status for a long time.

```bash
default        cassandra-0                                 1/1     Terminating
```

You can delete this pod with the following command : 
```bash
kubectl delete pods cassandra-0 --grace-period=0 --force
```

Exepected output :
```bash
warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "cassandra-0" force deleted
```

参考命令：

helm upgrade amplify-apim-7.7 ./amplify-apim-7.7 --reuse-values --set global.enableDynamicLicense=true -n apim2

kubectl get po  -n apim -o wide

kubectl describe po apimgr-6df7d877b5-828dw -n apim

ubuntu@ip-172-31-6-168:~/helm/charts$ kubectl logs  apimgr-6df7d877b5-828dw  -n apim2
Launching API Gateway in EMT mode...
Setting Java heap size to 1024 MB
cannot add license file /opt/Axway/apigateway/conf/licenses/lic.lic to set: license expired at Wed, 31 Mar 2021 17:19:09 GMT, time now Sat, 03 Apr 2021 09:07:17 GMT
NO PRODUCT LICENSE FOUND in /opt/Axway/apigateway/conf/licenses
Host details:
host.name=apimgr-6df7d877b5-828dw, net.hw=02:42:ac:11:00:0b, net.inet=172.17.0.11, version=7, version=7.7
Needs a valid license to run, shutting down...

helm install --dry-run --debug  amplify-apim-7.7 ./amplify-apim-7.7

helm upgrade amplify-apim-7.7 ./amplify-apim-7.7 -n apim

helm uninstall amplify-apim-7.7 -n apim


helm repo update
helm fetch helm/amplify-apim-7.7 --untar


helm install amplify-apim-7.7 ./amplify-apim-7.7 --set global.domainName=kube.local.com,apitraffic.replicaCount=1 -n apim