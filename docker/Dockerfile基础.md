## Dockerfile语法

`Dockerfile` 是一个包含一系列命令的文本文件，用于定义如何构建 Docker 镜像。通过编写 `Dockerfile`，你可以自定义镜像，设置环境、安装软件、复制文件、配置入口点等。

### Dockerfile 基本语法

1. **FROM**：指定基础镜像，所有镜像都是从一个基础镜像开始的。
   ```dockerfile
   FROM <镜像名>:<标签>
   ```
   **示例**：
   ```dockerfile
   FROM ubuntu:20.04
   ```

2. **RUN**：执行命令来安装软件包或执行其他操作。每一个 `RUN` 命令都会创建一个新的镜像层。
   ```dockerfile
   RUN <命令>
   ```
   **示例**：
   ```dockerfile
   RUN apt-get update && apt-get install -y nginx
   ```

3. **COPY**：将文件或目录从宿主机复制到镜像中。
   ```dockerfile
   COPY <源路径> <目标路径>
   ```
   **示例**：
   ```dockerfile
   COPY ./index.html /var/www/html/index.html
   ```

4. **ADD**：功能与 `COPY` 类似，但支持解压归档文件和从 URL 下载文件。
   ```dockerfile
   ADD <源路径/URL> <目标路径>
   ```

5. **WORKDIR**：设置接下来的工作目录，如果目录不存在，Docker 会为你创建它。
   ```dockerfile
   WORKDIR <路径>
   ```

6. **CMD**：设置容器启动时执行的默认命令，但可以被 `docker run` 提供的命令覆盖。
   ```dockerfile
   CMD ["<可执行文件>", "<参数1>", "<参数2>"]
   ```
   **示例**：
   ```dockerfile
   CMD ["nginx", "-g", "daemon off;"]
   ```

7. **ENTRYPOINT**：和 `CMD` 类似，用于指定容器启动时运行的主进程。与 `CMD` 不同的是，它不会被覆盖。
   ```dockerfile
   ENTRYPOINT ["<可执行文件>", "<参数1>", "<参数2>"]
   ```

8. **ENV**：设置环境变量，容器在运行时可以使用这些变量。
   ```dockerfile
   ENV <环境变量名>=<值>
   ```
   **示例**：
   ```dockerfile
   ENV LANG C.UTF-8
   ```

9. **EXPOSE**：声明容器要暴露的端口号，但不会自动打开端口。需要使用 `-p` 或 `-P` 来映射端口。
   ```dockerfile
   EXPOSE <端口号>
   ```

10. **VOLUME**：声明容器中的挂载点，用于持久化数据。
   ```dockerfile
   VOLUME ["/data"]
   ```

11. **USER**：切换用户，之后的命令将以指定用户的身份运行。
   ```dockerfile
   USER <用户名/UID>
   ```

### 自定义镜像

通过 `Dockerfile`，你可以构建完全自定义的镜像，包含你需要的软件、配置和依赖。以下是构建自定义镜像的基本步骤：

1. **编写 Dockerfile**：
   创建一个包含必要指令的 `Dockerfile`，例如安装软件、配置环境等。

2. **构建镜像**：
   使用 `docker build` 命令基于 `Dockerfile` 构建镜像。

   ```bash
   docker build -t <镜像名>:<标签> <Dockerfile所在路径>
   ```

   **示例**：
   ```bash
   docker build -t my_custom_image:1.0 .
   ```

3. **运行镜像**：
   使用 `docker run` 来启动基于自定义镜像的容器。

   ```bash
   docker run -d --name my_container my_custom_image:1.0
   ```

### 示例：创建一个包含 Nginx 和自定义网页的镜像

```dockerfile
# 使用官方的 Nginx 基础镜像
FROM nginx:alpine

# 设置环境变量
ENV NGINX_VERSION=alpine

# 设置工作目录
WORKDIR /usr/share/nginx/html

# 复制自定义的网页到 Nginx 的默认目录
COPY ./index.html /usr/share/nginx/html/index.html

# 添加一个额外文件（支持解压归档文件）
ADD ./static.zip /usr/share/nginx/html/

# 暴露 Nginx 端口 80
EXPOSE 80

# 声明一个卷用于数据持久化
VOLUME ["/usr/share/nginx/html"]

# 使用一个非 root 用户来运行应用
USER nginx

# 设置默认的入口命令，保持 Nginx 在前台运行
CMD ["nginx", "-g", "daemon off;"]

# 设置可执行文件和参数（ENTRYPOINT 通常与 CMD 搭配使用）
ENTRYPOINT ["nginx"]
```