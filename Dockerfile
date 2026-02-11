# base image
FROM node:lts-alpine as build-stage

# set working directory
WORKDIR /app

# config npm to use aliyun mirror
RUN npm config set registry https://registry.npmmirror.com

# copy package.json and package-lock.json
COPY package*.json ./

# install dependencies
RUN npm install

# copy project files
COPY . .

# build app
RUN npm run build

# production stage
FROM nginx:stable-alpine3.23-perl   as production-stage

# Install Certbot and OpenSSL
RUN apk add --no-cache certbot openssl

# copy build artifacts
COPY --from=build-stage /app/dist /usr/share/nginx/html

# copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# expose ports
EXPOSE 80 443

# start using entrypoint
ENTRYPOINT ["/entrypoint.sh"]
