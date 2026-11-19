# OpenShift Introduction 

| Field | Value |
|---|---|
| Date / window | 18-19th November 2026 |


## 1. Objective
Gain an introduction into Red Hat OpenShift, with a main focus on containerisation of applications. The objective is to get a web application (most likely apache) to be running and available through the public internet, with TLS enabled. This will give me an insight in how to construct a service, deploy it and configure the necessary networking functions for it to be safely accessible. 

## 2. Scope
- **In scope:** Deploy a simple web app that is accessible from the public internet, with TLS enabled. 
- **Out of scope:** Gitops, virtualisation, CI/CD

## 3. Implementation steps
| # | Action / command | Result | Notes |
|---|---|---|---|
| 1 | Signed up and opened console | Account set up and active | 30 day timer started |
| 2 | Clicked on + in the top right, clicked "container images" | Deploy a pod using the UI | This deployed a serverless (knative) container with limited set up - not much learning opportunity. |
| 3 | Downloaded oc CLI tar file and installed the oc utility  |  |  |
| 4 | Logged in using oc login --token... | logged in to the cli. exploring the help command | |
| 5 | 'oc delete svc/httpd-24' | container configured earlier has been deleted | rechecked with 'oc status' and its still showing - knative recreated it, see row 6|
| 6 | 'oc delete deployment httpd-24-00001-deployment' deletes it from the namespace | deployment refreshed - 'oc status' shows it starting back up. knative owned this service, meaning delete ksvc is required to remove | | 
| 7 | 'oc delete ksvc httpd-24' | service successfully deleted - oc get all shows clean account | need to learn more precise flags for deployment type |
| 8 | 'oc create deployment httpd --image=httpd' | httpd running as a deployment with a replica, not exposed yet so not accessible | |
| 9 | 'oc expose deployment httpd --port=8080' | httpd deployment now exposed and has been given a cluster IP, and port 8080 | the --help pages are very useful, there is no man page for oc |
| 10 | pod is running, exposed and route is set using 'oc create route edge httpd-route --service=httpd' | 'oc get all' shows that the previous commands have worked, but the pod is stuck in a crash loop | |
| 11 | 'oc logs httpd-778cb57d******* -c httpd' | logs show error when trying to bind to port 80 - permission denied | OpenShift pods run containers as a non-root user with a random UID |
| 12 | due to time passed, pod has been idled by the platform | pods idled, 0 replicas showing. Scaling back up required | |
| 13 | 'oc scale deploy/httpd --replicas 1' | pods back up and running, still on crash loop due to port 80 -  due to docker image trying to bind to port 80 (root required for sub 1024) | Use Red Hat specific images|
| 14 | 'oc set image deploy/httpd httpd=registry.access.redhat.com/ubi9/httpd-24' | deployed Red Hat image | |
| 15 | 'oc rollout status deploy/httpd' | checking if the image was rolled out to pod correctly | |
| 16 | 'oc get all' | now shows pod with 0 restarts, deployments and services all ready and available | |
| 17 | navigating to the route URL | default Apache index page displayed, with https in force. | |

## 4. Logs
```
oc logs httpd-778cb57d4c-***** -c httpd
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.***.**.**. Set the 'ServerName' directive globally to suppress this message
(13)Permission denied: AH00072: make_sock: could not bind to address [::]:80
(13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
AH00015: Unable to open logs
```
## 5. Root Cause 
| Issue | Root cause |
|---|---|
| knative container with limited functionality and no oc control | using the web UI with quick set up rather than oc CLI tool |
| pod, service and route being set up correctly, but route URL displaying an error | using --image=httpd with no registry resolved to Docker Hub’s httpd image, which expects root and binds port 80. OpenShift runs containers as a random non-root UID, so the bind failed. All images to be audited moving forward, to ensure compatibility with OpenShift and its rootless nature |

## 6. Validation (success criteria)
- [x] application deployed
- [x] networking setting correctly configured
- [x] the application is accessible and TLS is enabled 

## 7. Lessons 
- [x] always use full image paths
- [x] controllers such as knative recreate what they manage, so delete the parent object (ksvc), not its children 
- [x] a service is internal, routes expose it externally with TLS

## 8. Resources Used 
 - https://console.redhat.com/openshift/downloads
 - https://docs.redhat.com/en/documentation/openshift_container_platform/4.22#Networking



