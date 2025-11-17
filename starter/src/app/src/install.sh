#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

. ./env.sh INSTALL

function download()
{
   echo "Downloading - $1"
   wget -nv $1
}

# Anonymize
sudo dnf install -y poppler-utils mesa-libGL

# Python 
sudo dnf install -y python3.12 python3.12-pip python3-devel wget
sudo update-alternatives --set python /usr/bin/python3.12
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv myenv
source myenv/bin/activate
uv pip install -r src/requirements.txt

# PDFKIT
download https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox-0.12.6-1.centos8.x86_64.rpm
sudo dnf localinstall -y wkhtmltox-0.12.6-1.centos8.x86_64.rpm
mv *.rpm /tmp

# LibreOffice (convert docx to PDF)
if [ "${INSTALL_LIBREOFFICE}" != "no" ]; then
    sudo dnf group install -y "Server with GUI"
    cd /tmp
    export STABLE_VERSIONS=`curl -s https://download.documentfoundation.org/libreoffice/stable/`
    export LIBREOFFICE_VERSION=`echo $STABLE_VERSIONS | sed 's/.*<td valign="top">//' | sed 's/\/<\/a>.*//' | sed 's/.*\/">//'`
    echo LIBREOFFICE_VERSION=$LIBREOFFICE_VERSION

    download https://download.documentfoundation.org/libreoffice/stable/${LIBREOFFICE_VERSION}/rpm/x86_64/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz
    tar -xzvf LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz
    cd LibreOffice*/RPMS
    sudo dnf install *.rpm -y
    export LIBRE_OFFICE_EXE=`find ${PATH//:/ } -maxdepth 1 -executable -name 'libreoffice*' | grep "libreoffice"`
    echo LIBRE_OFFICE_EXE=$LIBRE_OFFICE_EXE

    # Chrome + Selenium to get webpage
    cd /tmp
    download https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    sudo dnf localinstall -y google-chrome-stable_current_x86_64.rpm
fi 
cd $SCRIPT_DIR

# Java
sudo dnf install -y graalvm-25-jdk maven
sudo update-alternatives --set java /usr/lib64/graalvm/graalvm-java25/bin/java
echo "export JAVA_HOME=/usr/lib64/graalvm/graalvm-java25" >> $HOME/.bashrc

# Build Tika
export JAVA_HOME=/usr/lib64/graalvm/graalvm-java25
cd src/tika
mvn package
cd -

# Install SQLCL (Java program)
cd $HOME/db
wget -nv https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
rm -Rf sqlcl
unzip sqlcl-latest.zip
cd -

# Store the config in APEX
$HOME/db/sqlcl/bin/sql $DB_USER/$DB_PASSWORD@DB <<EOF
begin
  APEX_APP.AI_CONFIG_UPDATE( 'agent_endpoint_ocid', '$TF_VAR_agent_endpoint_ocid' );
  APEX_APP.AI_CONFIG_UPDATE( 'region',              '$TF_VAR_region' );
  APEX_APP.AI_CONFIG_UPDATE( 'compartment_ocid',    '$TF_VAR_compartment_ocid' );
  APEX_APP.AI_CONFIG_UPDATE( 'genai_embed_model',   '$TF_VAR_genai_embed_model' );
  APEX_APP.AI_CONFIG_UPDATE( 'genai_embed_region',  '$TF_VAR_genai_embed_region' );
  commit;
end;
/
exit;
EOF

# MCP Firewall (optional)
sudo firewall-cmd --zone=public --add-port=8081/tcp --permanent

