.PHONY: init destroy-all clean

# Variables
AWS_PROFILE ?= default
ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
REGION := $(shell aws configure get region)
TF_STATE_BUCKET := terraform-state-$(ACCOUNT_ID)
TF_LOCK_TABLE := terraform-lock
WEBSITE_BUCKET := github-actions-pipeline-web-$(ACCOUNT_ID)
ARTIFACTS_BUCKET := github-actions-pipeline-artifacts-$(ACCOUNT_ID)

# Inicialización y primer despliegue
init:
	@echo "🚀 Iniciando setup inicial..."
	@echo "Usando cuenta AWS: $(ACCOUNT_ID)"
	@echo "Región: $(REGION)"

	@echo "\n1️⃣ Creando infraestructura para backend..."
	chmod +x scripts/setup.sh
	./scripts/setup.sh

	@echo "\n2️⃣ Inicializando Terraform..."
	cd iac && terraform init \
		-backend-config="bucket=$(TF_STATE_BUCKET)" \
		-backend-config="region=$(REGION)" \
		-backend-config="key=terraform.tfstate" \
		-backend-config="dynamodb_table=$(TF_LOCK_TABLE)"

	@echo "\n3️⃣ Realizando primer despliegue..."
	cd iac && terraform apply -auto-approve

	@echo "\n✅ Setup completado"
	@echo "Buckets creados:"
	@echo "- Website: $(WEBSITE_BUCKET)"
	@echo "- Artifacts: $(ARTIFACTS_BUCKET)"
	@echo "- Terraform State: $(TF_STATE_BUCKET)"

# Limpieza de archivos locales
clean:
	@echo "🧹 Limpiando archivos locales..."
	rm -rf dist/
	rm -rf node_modules/
	rm -f artifact.zip website-dist.zip
	rm -rf iac/.terraform/
	rm -f iac/.terraform.lock.hcl
	rm -f iac/terraform.tfstate*
	@echo "✅ Limpieza local completada"

# Destruir infraestructura con Terraform
destroy:
	@echo "💥 Destruyendo infraestructura con Terraform..."
	cd iac && terraform destroy -auto-approve
	@echo "✅ Infraestructura destruida"

# Destruir TODA la infraestructura (incluyendo bucket de estado y tabla de locks)
destroy-all: destroy
	@echo "⚠️ ¿Estás seguro de que quieres eliminar TODA la infraestructura, incluyendo el backend? (s/N)"
	@read -r response; \
	if [ "$$response" = "s" ]; then \
        echo "\n🗑️ Eliminando bucket de artefactos..."; \
        aws s3api list-object-versions --bucket $(ARTIFACTS_BUCKET) --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' | jq -c '.[]' | while read i; do \
            key=`echo $$i | jq -r .Key`; \
            version=`echo $$i | jq -r .VersionId`; \
            aws s3api delete-object --bucket $(ARTIFACTS_BUCKET) --key $$key --version-id $$version; \
        done; \
        aws s3api list-object-versions --bucket $(ARTIFACTS_BUCKET) --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' | jq -c '.[]' | while read i; do \
            key=`echo $$i | jq -r .Key`; \
            version=`echo $$i | jq -r .VersionId`; \
            aws s3api delete-object --bucket $(ARTIFACTS_BUCKET) --key $$key --version-id $$version; \
        done; \
        aws s3api delete-bucket --bucket $(ARTIFACTS_BUCKET); \
        echo "\n🗑️ Eliminando bucket de website..."; \
        aws s3 rm s3://$(WEBSITE_BUCKET) --recursive; \
        aws s3api delete-bucket --bucket $(WEBSITE_BUCKET); \
        echo "\n🗑️ Eliminando bucket de estado de Terraform..."; \
        aws s3 rm s3://$(TF_STATE_BUCKET) --recursive; \
        aws s3api delete-bucket --bucket $(TF_STATE_BUCKET); \
        echo "\n🗑️ Eliminando tabla DynamoDB..."; \
        aws dynamodb delete-table --table-name $(TF_LOCK_TABLE); \
        echo "\n✅ Eliminación completa finalizada"; \
	else \
		echo "\n❌ Operación cancelada"; \
	fi

# Ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  make init          - Realiza el setup inicial completo"
	@echo "  make clean         - Limpia archivos locales temporales"
	@echo "  make destroy-all   - Destruye TODA la infraestructura (incluyendo backend)"
	@echo "  make help          - Muestra esta ayuda"