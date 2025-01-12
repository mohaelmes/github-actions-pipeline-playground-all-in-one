# GitHub Actions Pipeline Playground

Este repositorio contiene una implementación de referencia de un pipeline de CI/CD utilizando GitHub Actions, Terraform y AWS. El pipeline despliega una aplicación web estática en AWS S3 y gestiona los artefactos de build.

## Requisitos Previos

- Cuenta de AWS
- AWS CLI configurado localmente
- Terraform instalado localmente
- Node.js y npm instalados
- Git

## Configuración Inicial

1. **Fork del Repositorio**
   ```bash
   # Crear un fork de este repositorio en tu cuenta de GitHub
   # Clonar tu fork localmente
   git clone https://github.com/TU-USUARIO/github-actions-pipeline-playground-all-in-one.git
   cd github-actions-pipeline-playground-all-in-one
   ```

2. **Crear Usuario IAM para GitHub Actions**
   
   Crear un nuevo usuario IAM en AWS con los siguientes permisos:

   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
         {
            "Effect": "Allow",
            "Action": [
               "s3:CreateBucket",
               "s3:DeleteBucket",
               "s3:ListBucket",
               "s3:Get*",
               "s3:*Object",
               "s3:PutBucketPolicy",
               "s3:PutBucketPublicAccessBlock",
               "s3:PutBucketVersioning",
               "s3:PutBucketWebsite",
               "s3:GetBucketCORS",
               "s3:PutBucketCORS"
            ],
            "Resource": [
               "arn:aws:s3:::github-actions-pipeline-web-*",
               "arn:aws:s3:::github-actions-pipeline-web-*/*",
               "arn:aws:s3:::github-actions-pipeline-artifacts-*",
               "arn:aws:s3:::github-actions-pipeline-artifacts-*/*",
               "arn:aws:s3:::terraform-state-*",
               "arn:aws:s3:::terraform-state-*/*"
            ]
         },
         {
            "Effect": "Allow",
            "Action": [
               "dynamodb:CreateTable",
               "dynamodb:DeleteTable",
               "dynamodb:PutItem",
               "dynamodb:GetItem",
               "dynamodb:DeleteItem",
               "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/terraform-lock"
         }
      ]
   }
   ```

![image](https://github.com/user-attachments/assets/fb4ad0fa-5419-4258-b2b1-8dab4186726e)
![image](https://github.com/user-attachments/assets/49d84776-55d3-46f2-8c71-8ac8ebd727ce)


3. **Preparar Backend de Terraform**
   ```bash
   
   # Activa unas credenciales de AWS:
   
   ## opción 1 (con aws configure ...)
   export AWS_DEFAULT_PROFILE=nombre_profile
   
   ## opción 2 (con variables de entorno)
   export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
   export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   export AWS_DEFAULT_REGION=eu-west-1
   
   # Ejecutar script de setup que creará el bucket S3 y tabla DynamoDB para el backend   
   ./scripts/setup.sh
   
   # Tomar nota del nombre del bucket creado para el estado de Terraform
   ```
![image](https://github.com/user-attachments/assets/cdc489c3-fc04-4160-aba5-a236429f20bb)

Fixing errors:
![image](https://github.com/user-attachments/assets/63f53c5c-3f83-4256-b249-3e55aa992b82)

Nos daba error el LocationConstraint:
![image](https://github.com/user-attachments/assets/c6427a1c-8ddf-453b-a480-c6c09331cd11)


4. **Primer Despliegue Manual**
   ```bash
   # Configurar el backend de Terraform e inicializar el backend remoto
   cd iac
   terraform init
   terraform plan
   terraform apply
   ```
Fixing main.tf:
![image](https://github.com/user-attachments/assets/94dac8b3-e3d7-47b1-a535-980a5a8e1ddf)
![image](https://github.com/user-attachments/assets/696506ad-6e0c-45ea-864f-dd30a0c61591)

![image](https://github.com/user-attachments/assets/2dfcfb57-d2f7-4a0d-b6a6-3efb9d6f3ae8)
![image](https://github.com/user-attachments/assets/d6d5c6aa-b88b-4a4b-9edb-2952b87574b5)
![image](https://github.com/user-attachments/assets/a89bc6a1-9f10-4004-8f60-d11b9fb69111)
![image](https://github.com/user-attachments/assets/3a171019-5e6f-40b9-ac56-d49422c00e9a)
![image](https://github.com/user-attachments/assets/f3e42b0c-6d6e-4049-b22b-144274de7139)



5. **Configurar Secretos en GitHub**

   En tu repositorio de GitHub, navega a Settings > Secrets and variables > Actions y añade estos tres secretos de repositorio:
   - `AWS_ACCESS_KEY_ID`: Tu Access Key del usuario IAM creado
   - `AWS_SECRET_ACCESS_KEY`: Tu Secret Access Key del usuario IAM creado
   - `AWS_REGION`: La región de AWS donde desplegarás (ej: eu-west-1)
![image](https://github.com/user-attachments/assets/6d173b06-4dc9-4b80-8585-3e06378b0a71)

## Uso del Pipeline

El pipeline se activará automáticamente con cada push a la rama main. También puedes:

1. Realizar cambios en el código fuente (src/):
   ```bash
   # Editar src/index.html
   git add src/index.html
   git commit -m "Update website content"
   git push origin main
   ```

2. Verificar la ejecución del pipeline en la pestaña "Actions" de tu repositorio.

3. Visitar la URL del bucket S3 (disponible en los outputs de Terraform) para ver tu sitio desplegado.

## Estructura del Proyecto

- `.github/workflows/`: Configuración del pipeline de GitHub Actions
- `src/`: Código fuente de la aplicación web
- `iac/`: Código de Terraform para infraestructura
- `scripts/`: Scripts de utilidad

## Limpieza

Para evitar costos innecesarios, recuerda eliminar los recursos cuando ya no los necesites:

```bash
cd iac
terraform destroy
```
![image](https://github.com/user-attachments/assets/41e1e1b3-9c96-43a1-92a2-d912a026ecd9)

También deberás eliminar manualmente:
- El bucket de estado de Terraform
- La tabla DynamoDB de bloqueo

## FAQ

Puede existir un bloqueo de a nivel de cuenta para que los bucket de S3 no estén públicos, en este caso se desactiva temporalmente y se vuelve a activar una vez finalizada.
