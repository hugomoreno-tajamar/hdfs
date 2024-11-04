
## Requisitos previos

Para poder utilizar esta configuración es necesario contar con:

- [Docker](https://www.docker.com/) instalado en tu máquina.
- Una terminal de wsl para windows o una máquina linux

## Creación del clúster

Creamos un docker-compose para especificar los contenedores de namenode, datanode, resourcemanager y nodemanager

De esta manera, instalamos en nuestro clúster hdfs, yarn y map-reduce

```bash
  
services:
  namenode:
    image: bde2020/hadoop-namenode:2.0.0-hadoop2.7.4-java8
    container_name: namenode
    environment:
      - CLUSTER_NAME=test
      - CORE_CONF_fs_defaultFS=hdfs://namenode:8020
    ports:
      - "9870:9870"  # Puerto para la interfaz web del NameNode
    volumes:
      - namenode_data:/hadoop/dfs/name

  datanode:
    image: bde2020/hadoop-datanode:2.0.0-hadoop2.7.4-java8
    container_name: datanode
    environment:
      - CORE_CONF_fs_defaultFS=hdfs://namenode:8020
      - YARN_CONF_yarn_resourcemanager_hostname=resourcemanager
    volumes:
      - datanode_data:/hadoop/dfs/data
    depends_on:
      - namenode

  resourcemanager:
    image: bde2020/hadoop-resourcemanager:2.0.0-hadoop2.7.4-java8
    container_name: resourcemanager
    environment:
      - CORE_CONF_fs_defaultFS=hdfs://namenode:8020

  nodemanager:
    image: bde2020/hadoop-nodemanager:2.0.0-hadoop2.7.4-java8
    container_name: nodemanager
    environment:
      - CORE_CONF_fs_defaultFS=hdfs://namenode:8020
    depends_on:
      - resourcemanager

volumes:
  namenode_data:
  datanode_data:

```
Creamos también scripts de iniciación para los servicios que estamos instalando  

init-datanode.sh:
```bash
#!/bin/bash
rm -rf /opt/hadoop/data/dataNode/*
chown -R hadoop:hadoop /opt/hadoop/data/dataNode
chmod 755 /opt/hadoop/data/dataNode
hdfs datanode

```

start-hdfs:
```bash
#!/bin/bash
if [ ! -d "/opt/hadoop/data/nameNode/current" ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format
fi
hdfs namenode
```

start-nodemanager.sh:
```bash
#!/bin/bash
/opt/hadoop/bin/yarn --daemon start nodemanager
tail -f /dev/null
```

start-yarn.sh:
```bash
#!/bin/bash
/opt/hadoop/sbin/start-yarn.sh
tail -f /dev/null
```

# Levantar los contenedores 

Una vez hemos establecido todos los archivos de configuración, tenemos que montar todos los contenedores con el siguiente comando:

```bash
docker-compose up -d
```

Ahora, para poder entrar a la interfaz de nuestros contenedores y poder ejecutar hdfs debemos de hacer:

```bash
docker exec -it namenode bash
```

Y para probar nuestro sistema hdfs podemos hacer por ejemplo

```bash
hdfs dfs -ls /
```

# Ejecución de map-reduce y wordcount

Ahora, vamos a subir un archivo de texto a hdfs para poder contar sus palabras.

Primero creamos un archivo txt simple:

```bash
echo "Hola HDFS" > test.txt
```

Luego, creamos una carpeta y subimos el archivo a esa carpeta en hdfsprimeo creamos una carpeta:

```bash
hdfs dfs -mkdir -p /user/root
hdfs dfs -put test.txt /user/root
```

Una vez tenemos el archivo, buscamos el archivo de map-reduce-example, que es el que contiene el wordcount, en mi caso era el siguiente 

```bash
cd /opt/hadoop-2.7.4/share/hadoop/mapreduce/
```

Una vez estamos en el directorio, ejecutamos el jar para hacer el wordcount y llevar el resultado a la carpeta output

```bash
yarn jar hadoop-mapreduce-examples-2.7.4.jar wordcount /user/root/test.txt /user/root/output
```

# Comprobación

Ahora, comprobamos el archivo que estará /user/root/output en el sistema de archivos hdfs

```bash
hdfs dfs -cat /user/root/output/part-r-00000
```


