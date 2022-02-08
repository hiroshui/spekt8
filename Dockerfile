# version 8 of node
FROM docker.io/node:12 as build

# create a directory for client
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# install app dependencies
COPY package*.json ./
COPY src ./src
COPY dist ./dist

RUN npm install 

FROM docker.io/node:12.22.10-alpine3.14
RUN mkdir -p /app
WORKDIR /app

# bundle app source
COPY --from=build /usr/src/app .

# bind to port 8080
EXPOSE 8080

CMD ["npm", "run", "server"]
##CMD ["npx","http-server", "/app"]