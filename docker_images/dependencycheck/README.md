# DependencyCheck Docker Container Management Scripts 

Estos Bash Scripts pullean una imagen de un registro y crean un contenedor para correr DependencyCheck.

## Instalación 

Para clonar el repositorio entero en un entorno linux en el directorio que desees.

```bash
git clone https://github.com/admvateam/server_chino_kali_linux_docker_registry_redteam.git
```

## Uso (Local)

Para correr el script que pullea la imagen al registro y crea el contenedor simplemente ir mediante cd al path del directorio donde esta el archivo .sh de buildeo y correrlo asi:

```bash
./dependency-check-docker-container-builder.sh
```

Para correr el script que destruye la imagen pulleada y el contenedor simplemente ir mediante cd al path del directorio donde esta el archivo .sh de destruccion y correrlo asi:

```bash
./dependency-check-docker-container-destroyer.sh
```
