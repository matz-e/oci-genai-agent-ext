#!/usr/bin/env bash
export SRC_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ROOT_DIR=${SRC_DIR%/*}
cd $ROOT_DIR

. ./starter.sh env
# try(oci_apigateway_gateway.starter_apigw.ip_addresses[0].ip_address,"")
export NLB_IP=`jq -r '.resources[] | select(.name=="starter_nlb") | .instances[0].attributes.ip_addresses[] | select(.is_public==true) | .ip_address' $STATE_FILE`
echo "NLB_IP=$NLB_IP"

# Upload Sample Files
sleep 5
# echo "https://${APIGW_HOSTNAME}/${TF_VAR_prefix}/index.html" > ../sample_files/website.crawler
# oci os object bulk-upload -ns $TF_VAR_namespace -bn ${TF_VAR_prefix}-public-bucket --src-dir ../sample_files --overwrite --content-type auto

title "INSTALLATION DONE"
echo
# echo "(experimental) Cohere with Tools and GenAI Agent:"
# echo "http://${BASTION_IP}:8081/"
# echo "-----------------------------------------------------------------------"

echo "URLs" > $FILE_DONE
append_done "-----------------------------------------------------------------------"
append_done "Streamlit:"
append_done "http://${NLB_IP}:8080/"
append_done
append_done "-----------------------------------------------------------------------"
append_done "APEX login:"
append_done
append_done "APEX Workspace"
append_done "https://${APIGW_HOSTNAME}/ords/_/landing"
append_done "  Workspace: APEX_APP"
append_done "  User: APEX_APP"
append_done "  Password: $TF_VAR_db_password"
append_done
append_done "APEX APP"
append_done "https://${APIGW_HOSTNAME}/ords/r/apex_app/apex_app/"
append_done "  User: APEX_APP / $TF_VAR_db_password"
append_done 
append_done "-----------------------------------------------------------------------"
append_done "Oracle Digital Assistant (Web Channel)"
append_done "https://${APIGW_HOSTNAME}/${TF_VAR_prefix}/oda.html"
append_done 
