## Prerequisites

1. start Minikube.

   cd ~
   ubuntu@ip-172-31-6-168:~$ cd script/
   ubuntu@ip-172-31-6-168:~/script$ ls
   nohup.out  startDashboard.sh  startMinikube.sh
   ubuntu@ip-172-31-6-168:~/script$ ./startMinikube.sh
   ubuntu@ip-172-31-6-168:~/script$ ./startDashboard.sh
   ubuntu@ip-172-31-6-168:~/script$ nohup: appending output to 'nohup.out'
   
   ubuntu@ip-172-31-6-168:~/script$ ls
   
2. 获取repo中的chart

    helm repo update
    helm fetch helm/amplify-apim-7.7 --untar  
    
3. 使用helm chart部署到k8s 
   kubectl create ns apim
   
   helm install amplify-apim-7.7 ./amplify-apim-7.7 --set global.domainName=kube.local.com,apitraffic.replicaCount=1 -n apim
   
4. 使用port-forward进行测试： 
   kubectl get svc -n apim

   kubectl port-forward service/anm  --address 0.0.0.0 30090:8090 -n apim
   
   kubectl port-forward service/apimgr  --address 0.0.0.0 30075:8075 -n apim
   
   kubectl port-forward service/traffic  --address 0.0.0.0 30075:8065 -n apim
   
   kubectl port-forward service/traffic  --address 0.0.0.0 30080:8080 -n apim
   
 5. 使用浏览器访问k8s所在主机的公网地址和端口：
 
    https://k8s:30090
    admin/admin
   
    https://k8s:30075
    apiadmin/changeme
    
 6. 更新helm chart 配置：  
    helm upgrade amplify-apim-7.7 ./amplify-apim-7.7 -n apim
    
 7. 删除helm  chart 构建的部署：  
    helm uninstall amplify-apim-7.7 -n apim
 
 8. 删除k8s namespace：  
    kubectl delete ns apim
 
 ps： 
 1. 查看helm chart 配置是否正常：helm chart dry-run
 helm install --dry-run --debug  amplify-apim-7.7 ./amplify-apim-7.7