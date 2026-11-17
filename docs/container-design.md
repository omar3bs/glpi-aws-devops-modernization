\# GLPI Container Design



\## Base Image

\- PHP: 8.5.12

\- Web server: Apache

\- Base OS: Debian Trixie

\- Image: php:8.5.12-apache-trixie

\- Digest: sha256:08af36df144462d84c7f16190557eec06cb9f656882685610b712a15eec54d46



\## Application

\- GLPI version: 12.0.2

\- Database: MariaDB 11.8 series

\- Custom Docker image built from the official GLPI release.



\## Persistent Storage

\- glpi\_config: /var/www/glpi/config

\- glpi\_files: /var/www/glpi/files

\- glpi\_plugins: /var/www/glpi/plugins

\- glpi\_marketplace: /var/www/glpi/marketplace

\- db\_data: /var/lib/mysql



\## Initialization Strategy

\- Support fresh installation into an empty database.

\- Support migration from existing GLPI installations.

\- Preserve existing encryption keys and application data.

\- Never automatically overwrite an existing database.



\## Security Requirements

\- Run the application as a non-root user.

\- Keep credentials and encryption keys outside the image.

\- Scan images for vulnerabilities before publishing.

\- Pin application and base image versions.



\## Deployment Targets

\- Local Docker Compose.

\- Public Docker Hub distribution.

\- Amazon ECR and ECS Fargate.



\## Status

Design proposed. Implementation and validation pending.

