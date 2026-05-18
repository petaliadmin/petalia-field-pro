# Base image
FROM node:20-alpine AS development

WORKDIR /usr/src/app

RUN apk add --no-cache python3 make g++

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# Production image
FROM node:20-alpine AS production

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /usr/src/app

COPY package*.json ./
COPY --from=development /usr/src/app/node_modules ./node_modules

RUN npm prune --production

COPY --from=development /usr/src/app/dist ./dist

RUN mkdir -p uploads

EXPOSE 3000

CMD ["node", "dist/main"]
