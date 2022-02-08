#!/bin/bash
set -eu

#which namespace should we deploy to
SPEKT8_NS=spekt8 #default: spekt8
#which namespace should be observed - todo: multiple namespaces.. :)
export OBSERVED_NAMESPACE=alfresco #please change this one from default to your version..

#should be rbac enabled?
RBAC_ENABLED=true

#whould you like to use a svc and ingress or only port-forwarding?
PORT_FORWARDING_ENABLED=true #recommended: either true here and SVC/INGRESS disabled or the other way around.. - default: true
SVC_ENABLED=true # should the deployment / app be available inside k8s as a service of type ClusterIP?
DEPLOY_INGRESS=true # should the service be exposed using an ingress-object (nginx only for now..)?

BASEDIR=$(dirname "$0")


#go into folder..
pushd ${BASEDIR}
 
#check if rbac should be deployed
if ${RBAC_ENABLED}; then
  echo -e "Deploy with rbac:"
  kubectl apply -f rbac/*.yml
fi

#create namespaces if needed
if kubectl get ns ${SPEKT8_NS}; then
  echo -e "Namespace ${SPEKT8_NS} already exists. No need to create!"
else
  echo -e "Create namespace ${SPEKT8_NS}"
  kubectl create namespace ${SPEKT8_NS}
fi
if kubectl get ns ${OBSERVED_NAMESPACE}; then
  echo -e "Namespace ${OBSERVED_NAMESPACE} already exists. No need to create!"
else
  echo -e "Create namespace ${OBSERVED_NAMESPACE}"
  kubectl create namespace ${OBSERVED_NAMESPACE}
fi

#deploy deployment
echo -e "Deploy SPEKT8 to cluster $(kubectl config current-context) in ns ${SPEKT8_NS} using oberservation namespace ${OBSERVED_NAMESPACE}!"
envsubst < deploy.yml > deploy-int.yml
kubectl apply -f deploy-int.yml -n ${SPEKT8_NS}

#port forwarding
set +eu
if ${PORT_FORWARDING_ENABLED}; then
  PORT_FORWARDING_ACTIVE=$(ps $(ps | grep kubectl | awk '{ print $1 }') | grep '8080:8080');
  if [[ ! -z ${PORT_FORWARDING_ACTIVE} ]]; then
    echo -e "port-forwarding was already active!"
  else
    echo -e "Start port-forwarding on port 8080. App should be available under http://localhost:8080"
    kubectl port-forward deployment/spekt8 --address localhost 8080:8080 > /dev/null 2>&1 &
    echo "" 
  fi
fi
set -eu

#service deployment
if ${SVC_ENABLED}; then
  echo -e "Deploy SPEKT8 svc:"
  kubectl apply -f svc.yml -n ${SPEKT8_NS}
fi

#ingress deployment
if ${SVC_ENABLED}; then
  echo -e "Deploy SPEKT8 ingress:"
  kubectl apply -f ingress.yml -n ${SPEKT8_NS}
fi

#cleanup
echo -e "Cleanup interpolated files.."
rm *-int.yml

popd