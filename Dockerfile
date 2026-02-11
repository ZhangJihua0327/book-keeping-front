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
FROM nginx:stable-alpine as production-stage

# copy build artifacts
COPY --from=build-stage /app/dist /usr/share/nginx/html

# copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# expose port 80
EXPOSE 80

# start nginx
CMD ["nginx", "-g", "daemon off;"]
