FROM node:20-slim AS base
RUN apt-get update && apt-get install -y openssl libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./

FROM base as build
RUN export NODE_ENV=production
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM base as prod-build
RUN npm ci --only=production
COPY prisma prisma
RUN npx prisma generate

FROM base as prod
COPY --from=prod-build /app/node_modules /app/node_modules
COPY --from=build /app/.next /app/.next
COPY --from=build /app/public /app/public
COPY --from=build /app/prisma /app/prisma
EXPOSE 3000
CMD ["npm", "start"]