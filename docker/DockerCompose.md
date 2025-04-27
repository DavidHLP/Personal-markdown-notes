## Docker Compose

**Docker Compose** 是一个用于定义和运行多容器 Docker 应用的工具。它允许你使用一个简单的 YAML 文件来描述应用的服务、网络和卷等，之后只需要一条命令就可以启动和管理应用的所有容器。

Docker Compose 特别适合开发、测试和生产环境中，涉及多个容器服务协作的应用程序，如微服务架构。通过 Compose，你可以定义容器服务的依赖关系、共享卷、端口映射、环境变量等。

### Docker Compose 的基本概念

1. **服务（Services）**：服务是 Docker 容器的抽象。一个服务代表一个容器的配置，比如它使用的镜像、环境变量、端口映射等。
2. **网络（Networks）**：Docker Compose 支持容器间的网络通信，默认情况下，所有在同一个 `docker-compose.yml` 文件中的容器都会共享一个自定义网络。
3. **卷（Volumes）**：卷用于持久化容器中的数据，确保容器删除或重新创建时数据不会丢失。

### Docker Compose 工作流程

1. **定义（Define）**：你可以通过一个 `docker-compose.yml` 文件来定义你的应用，包括服务、网络和卷的配置。
2. **启动（Start）**：通过一条命令启动应用，Compose 会自动构建并启动所有容器。
3. **停止和管理（Manage）**：你可以使用命令来停止、重新启动、查看日志等操作。

### Docker Compose 基本命令

1. **启动所有服务**
   ```bash
   docker-compose up
   ```

   这个命令会启动 `docker-compose.yml` 中定义的所有服务。

2. **在后台启动所有服务**
   ```bash
   docker-compose up -d
   ```

   使用 `-d` 参数让服务在后台运行。

3. **停止所有服务**
   ```bash
   docker-compose down
   ```

   这个命令会停止并删除所有服务容器，同时删除网络和卷（除非它们被标记为外部卷）。

4. **查看服务的状态**
   ```bash
   docker-compose ps
   ```

   列出当前项目中所有正在运行的容器。

5. **查看服务的日志**
   ```bash
   docker-compose logs
   ```

   查看所有服务的日志，或指定某个服务的日志。

6. **重启服务**
   ```bash
   docker-compose restart
   ```

   这个命令会重启所有的服务，或者你可以指定特定的服务。

7. **构建镜像**
   ```bash
   docker-compose build
   ```

   使用 Compose 文件中定义的配置，构建服务所需的 Docker 镜像。

8. **拉取镜像**
   ```bash
   docker-compose pull
   ```

   从远程仓库中拉取镜像。

### Docker Compose 文件结构

官方 Docker Compose 文件结构和语法的详细文档可以在以下链接中找到：[Compose File Reference](https://docs.docker.com/compose/compose-file/)

Docker Compose 使用 `docker-compose.yml` 文件来定义多容器应用。该文件使用 YAML 格式。

#### `docker-compose.yml` 的基本结构：

```yaml
version: '3'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - webnet

  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: example
    volumes:
      - dbdata:/var/lib/mysql
    networks:
      - webnet

volumes:
  dbdata:

networks:
  webnet:
```

### 解释：
1. **version**：指定 Compose 文件的版本。在 Docker Compose 3.x 中推荐使用 `version: '3'`。
2. **services**：定义应用中的各个服务。在上面的例子中，定义了 `web` 和 `db` 两个服务。
   - `web`：使用 `nginx:alpine` 镜像，端口映射为宿主机的 `8080` 端口对应容器的 `80` 端口。
   - `db`：使用 `mysql:5.7` 镜像，设置环境变量 `MYSQL_ROOT_PASSWORD`，并使用 `dbdata` 卷来存储 MySQL 数据。
3. **volumes**：定义数据卷，用于持久化数据。上面的例子中，`dbdata` 被挂载到 MySQL 容器的 `/var/lib/mysql` 目录。
4. **networks**：定义网络，用于不同服务之间的通信。`web` 和 `db` 服务共享同一个 `webnet` 网络。

### 示例：创建一个带有 Nginx 和 MySQL 的 Web 应用

#### 步骤 1：创建 `docker-compose.yml`

```yaml
version: '3'  # 指定 Docker Compose 文件的版本

services:  # 定义服务
  web:  # 定义名为 "web" 的服务
    image: nginx:alpine  # 使用 nginx:alpine 镜像
    ports:
      - "8080:80"  # 将宿主机的8080端口映射到容器的80端口
    volumes:
      - ./html:/usr/share/nginx/html  # 将当前目录的 html 文件夹挂载到容器内的指定路径
    environment:  # 设置环境变量
      - NGINX_HOST=localhost
      - NGINX_PORT=80
    networks:
      - webnet  # 该服务连接到自定义网络 "webnet"

  db:  # 定义名为 "db" 的数据库服务
    image: mysql:5.7  # 使用 mysql:5.7 镜像
    environment:
      MYSQL_ROOT_PASSWORD: example  # 设置 MySQL 的 root 密码
    volumes:
      - dbdata:/var/lib/mysql  # 将数据库数据持久化存储到数据卷 "dbdata"
    networks:
      - webnet  # 该服务连接到自定义网络 "webnet"

volumes:  # 定义卷
  dbdata:  # 持久化数据库的数据

networks:  # 定义网络
  webnet:  # 创建一个名为 "webnet" 的网络
```

#### 步骤 2：创建目录结构

在与 `docker-compose.yml` 同一个目录下，创建 `html` 目录，并放入一个 `index.html` 文件，作为 Nginx 的 Web 根目录。

```bash
mkdir html
echo "<h1>Hello, Docker Compose!</h1>" > html/index.html
```

#### 步骤 3：启动应用

使用以下命令启动服务：

```bash
docker-compose up -d
```

现在，Nginx 服务运行在 `localhost:8080`，MySQL 数据库也已经启动。

### Docker Compose 的常用参数

1. **`docker-compose up` 的常用参数**：
   - `-d`：在后台启动服务。
   - `--build`：强制重新构建服务所需的镜像。
   - `--force-recreate`：强制重新创建容器，即使配置未发生变化。

2. **`docker-compose down` 的常用参数**：
   - `-v`：删除与服务关联的卷。

3. **`docker-compose logs` 的常用参数**：
   - `-f`：实时输出日志。

4. **`docker-compose ps` 的常用参数**：
   - `-q`：只显示容器的 ID。
   - `--services`：只列出服务名称。