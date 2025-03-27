# Template Scripts

De la misma forma que su [version](https://github.com/admvateam/dependencycheck_redteam) de contenedor e imagen de docker local. 
Estos Bash Scripts corren un scan de DependencyCheck para proyectos de buildeados con gradle y maven. 
El dockerfile clona y buildea los proyectos ejemplo correspondientes dentro del contenedor generado y a su vez añade el script del scan.
Una vez terminado el scan los resultados son subidos a Fortify Software Security Center (SSC).

# Proyectos ejemplo cargados

## Petclinc 
A vulnerable Java application that is built with Maven --> https://github.com/varadharajanravi/Petclinic 

## Vulnerable-Java-Application
A vulnerable Java application that is built with Gradle --> https://github.com/DataDog/vulnerable-java-application

## Uso (Local)

* Buildear la imagen y su contenedor de Docker para DependencyCheck con el script de buildeo.
* Hacer cd al directorio "dependency-check-projects-to-scan" en el contenedor y elejir uno de los directorios donde estan los proyectos clonados de ejemplo.
* Correr el script .sh de escaneo de la siguiente forma:

```bash
./dependency-check-scan-template-script.sh
```
