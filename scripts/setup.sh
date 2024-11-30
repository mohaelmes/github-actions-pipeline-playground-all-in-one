#!/bin/bash

# Verificar que AWS CLI está instalado y configurado
if ! command -v aws &> /dev/null; then
    echo "AWS CLI no está instalado. Por favor, instálalo primero."
    exit 1
fi

# Obtener el ID de la cuenta de AWS
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo "Error al obtener el ID de la cuenta de AWS. Verifica tus credenciales."
    exit 1
fi

# Obtener la región configurada en AWS CLI
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    echo "No se pudo obtener la región de AWS. Verifica tu configuración."
    exit 1
fi

# Nombres de recursos
BUCKET_NAME="terraform-state-$ACCOUNT_ID"
TABLE_NAME="terraform-lock"

# Crear bucket S3 para el estado de Terraform
echo "Creando bucket S3 para el estado de Terraform..."
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

# Habilitar versionado en el bucket
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Crear tabla DynamoDB para el bloqueo de estado
echo "Creando tabla DynamoDB para el bloqueo de estado..."
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION

echo "Configuración completada."
echo "Bucket de estado: $BUCKET_NAME"
echo "Tabla de bloqueo: $TABLE_NAME"
echo ""
echo "Por favor, actualiza el backend en iac/main.tf con estos valores:"
echo "backend \"s3\" {"
echo "    bucket         = \"$BUCKET_NAME\""
echo "    key            = \"terraform.tfstate\""
echo "    region         = \"$REGION\""
echo "    dynamodb_table = \"$TABLE_NAME\""
echo "    encrypt        = true"
echo "}"
