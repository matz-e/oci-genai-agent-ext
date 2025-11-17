## Set env variables needed for env.sh
get_attribute_from_tfstate "STREAM_OCID" "starter_stream" "id"
get_attribute_from_tfstate "TENANCY_NAME" "tenant_details" "name"
get_attribute_from_tfstate "STREAM_MESSAGE_ENDPOINT" "starter_stream" "messages_endpoint"

get_id_from_tfstate "TF_VAR_agent_datasource_ocid" "starter_agent_ds" 
get_id_from_tfstate "TF_VAR_agent_endpoint_ocid" "starter_agent_endpoint" 

get_id_from_tfstate "APP_SUBNET_OCID" "starter_app_subnet" 
get_id_from_tfstate "DB_SUBNET_OCID" "starter_db_subnet" 

echo "-- STREAMING CONNECTION -----------------------------"
echo "STREAM_MESSAGE_ENDPOINT=$STREAM_MESSAGE_ENDPOINT"
echo "STREAM_OCID=$STREAM_OCID"
echo "STREAM_USERNAME=$TENANCY_NAME/$TF_VAR_username/$STREAM_OCID"
echo
echo "-- AGENT (OPTIONAL) ---------------------------------"
echo "TF_VAR_agent_datasource_ocid=$TF_VAR_agent_datasource_ocid"
echo "TF_VAR_agent_endpoint_ocid=$TF_VAR_agent_endpoint_ocid"
echo
echo "-- GENERATIVE AI MODEL ------------------------------"
oci generative-ai model-collection list-models --compartment-id $TF_VAR_compartment_ocid --all > $TARGET_DIR/genai_models.json 
export TF_VAR_genai_meta_model=$(jq -r '.data.items[]|select(.vendor=="meta" and (.capabilities|index("CHAT")))|.["display-name"]' $TARGET_DIR/genai_models.json | head -n 1)
echo $TF_VAR_genai_meta_model

export TF_VAR_genai_cohere_model=$(jq -r '.data.items[]|select(.vendor=="cohere" and (.capabilities|index("CHAT")))|.["display-name"]' $TARGET_DIR/genai_models.json | head -n 1)
echo $TF_VAR_genai_cohere_model

export TF_VAR_genai_embed_model="cohere.embed-v4.0"
# export TF_VAR_genai_embed_model=$(jq -r '.data.items[]|select(.vendor=="cohere" and (.capabilities|index("TEXT_EMBEDDINGS")) and ."time-on-demand-retired"==null)|.["display-name"]' $TARGET_DIR/genai_models.json | head -n 1)
echo $TF_VAR_genai_embed_model

export TF_VAR_genai_embed_region="me-riyadh-1"
echo $TF_VAR_genai_embed_region
