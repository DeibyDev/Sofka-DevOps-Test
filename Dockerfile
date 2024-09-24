# Usar la imagen base de Node.js versión 14 en Alpine
FROM node:14-alpine AS dependencies

# Establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias necesarias
RUN apk add --no-cache \
    make \
    g++ \
    python3

# Establecer la variable de entorno para Python
ENV PYTHON=python3

# Copiar el archivo package.json e instalar dependencias
COPY package.json .
RUN npm install

# Crear la imagen final usando Node.js 14
FROM node:14-alpine

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.docker.cmd="docker run -d -p 3000:3000 --name alpine_timeoff"

# Instalar otras herramientas necesarias (opcional)
RUN apk add --no-cache vim make g++ python3

# Crear usuario 'app' y establecer directorio de trabajo
RUN adduser --system app --home /app
USER app
WORKDIR /app

# Cambiar de nuevo a root para copiar y establecer permisos
USER root


# Cambiar permisos del archivo de base de datos
RUN chmod 664 /app/.*

# Copiar los archivos del proyecto y las dependencias instaladas
COPY . /app
COPY --from=dependencies /app/node_modules ./node_modules

# Exponer el puerto 3000
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["npm", "start"]
