# Docker Management Scripts

Estos Bash Scripts buildean un volumen, un registro y tagea y pushea una imagen hacia el registro.
Ademas borran el volumen, el registro y las imagenes dentro del mismo.

## Instalación 

Para clonar el repositorio entero en un entorno linux en el directorio que desees.

```bash
git clone https://github.com/admvateam/server_chino_kali_linux_docker_registry_redteam.git
```

## Uso (Local)

Para correr el script que buildea el volumen, el registro y pushea imagenes al registro simplemente ir mediante cd al path del directorio donde esta el archivo .sh de buildeo y correrlo asi:

```bash
./server-chino-kali-docker-registry-builder.sh
```

Para correr el script que destruye el volumen, el registro y las imagenes al registro simplemente ir mediante cd al path del directorio donde esta el archivo .sh de destruccion y correrlo asi:

```bash
./server-chino-kali-docker-registry-destroyer.sh
```
