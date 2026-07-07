# 1. CLIENT BUILDER STAGE
FROM node:22-slim AS client-builder
WORKDIR /client
COPY client/package*.json ./
RUN npm ci
COPY client/ .
RUN npm run build

# 2. TESTER STAGE (Deliberate Failure Gate)
FROM node:22-slim AS tester
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-setuptools make g++
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci
COPY backend/ .
RUN SQLITE_DB_LOCATION="./todo.db" npm test

# 3. FINAL PRODUCTION RELEASE
FROM node:22-slim AS final
WORKDIR /app
# If tests fail, Docker will crash right here trying to evaluate this link.
COPY --from=tester /app/node_modules ./node_modules
COPY backend/package*.json ./
COPY backend/ .
# Copy the built client assets into your backend static folder
COPY --from=client-builder /client/dist/ ./src/static/
EXPOSE 3000

CMD ["node", "src/index.js"]
