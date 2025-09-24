FROM node:20-alpine AS build
WORKDIR /app

RUN npm config set registry https://registry.npmjs.org \
 && npm config set fetch-retries 5 \
 && npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000 \
 && npm config set fetch-timeout 300000

COPY package*.json ./
RUN (npm ci --legacy-peer-deps || npm install --legacy-peer-deps)

COPY . .

RUN npm ls typescript >/dev/null 2>&1 || npm i -D typescript@^5 --legacy-peer-deps \
 && npm ls vite >/dev/null 2>&1 || npm i -D vite@^5 --legacy-peer-deps

RUN npm run build || npx vite build

RUN find dist -type d -exec chmod 755 {} + \
 && find dist -type f -exec chmod 644 {} +

FROM nginx:alpine
WORKDIR /usr/share/nginx/html

COPY --from=build /app/dist ./

RUN chmod -R a+rX /usr/share/nginx/html

RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/app.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80
