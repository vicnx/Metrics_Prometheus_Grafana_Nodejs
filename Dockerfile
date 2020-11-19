FROM node:alpine3.10
RUN mkdir myapp
WORKDIR /myapp
COPY ./src .
RUN npm install
EXPOSE 3000
CMD ["node", "app.js"]