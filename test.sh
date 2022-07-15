xd=$(yq -e ".predeployment.services | length"  values.yaml)

echo $xd