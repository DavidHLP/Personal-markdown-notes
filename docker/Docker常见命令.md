## 常见命令

### 1. **拉取镜像**
   ```bash
   docker pull <镜像名>:<标签>
   ```
   **常用参数**：
   - `<镜像名>`：要拉取的镜像名称。
   - `<标签>`：镜像的版本标签（如`latest`、`8.0`等）。

   **示例**：
   ```bash
   docker pull nginx:latest
   ```

### 2. **推送镜像**
   ```bash
   docker push <镜像名>:<标签>
   ```
   **常用参数**：
   - `<镜像名>`：要推送的镜像名称，通常为`<Docker Hub用户名>/<镜像名>`。
   - `<标签>`：镜像的版本标签。

   **示例**：
   ```bash
   docker push myrepo/myimage:1.0
   ```

<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/d3b1d14970add8bc016633d95403c5ee.png" />
  <p style="margin-top: 2px;">docker push 和 docker pull</p>
</div>

### 3. **查看本地镜像**
   ```bash
   docker images
   ```
   **常用参数**：
   - `-q`：只显示镜像的ID。
   - `-a`：显示所有镜像，包括中间层镜像。

   **示例**：
   ```bash
   docker images -a
   ```

### 4. **删除镜像**
   ```bash
   docker rmi <镜像ID或名称>
   ```
   **常用参数**：
   - `-f`：强制删除正在使用的镜像。

   **示例**：
   ```bash
   docker rmi nginx:latest
   ```

<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/d0b706728f2422737a2997a6a7da3ac7.png" />
  <p style="margin-top: 2px;">docker rmi</p>
</div>

### 5. **构建镜像**
   ```bash
   docker build -t <镜像名>:<标签> <Dockerfile所在目录>
   ```
   **常用参数**：
   - `-t`：为构建的镜像命名并打标签。
   - `--no-cache`：不使用缓存，强制重新构建镜像。

   **示例**：
   ```bash
   docker build -t myapp:1.0 .
   ```

<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/633a1b61f75f43f2cfc3a7f12497e3ca.png" />
  <p style="margin-top: 2px;">docker build</p>
</div>

### 6. **打包镜像**
   ```bash
   docker save -o <文件名.tar> <镜像名>:<标签>
   ```
   **常用参数**：
   - `-o`：指定保存的文件名。

   **示例**：
   ```bash
   docker save -o myapp.tar myapp:1.0
   ```
      
<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/e0736fc43fe4b9977a6524c871c4196a.png" />
  <p style="margin-top: 2px;">docker save</p>
</div>

### 7. **挂载打包的镜像**
   ```bash
   docker load -i <文件名.tar>
   ```
   **示例**：
   ```bash
   docker load -i myapp.tar
   ```
   
<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/49f9bda921aa6a4b096632dee560c561.png" />
  <p style="margin-top: 2px;">docker load</p>
</div>

### 8. **运行镜像**
   ```bash
   docker run -d -p <主机端口>:<容器端口> --name <容器名> <镜像名>:<标签> -v<数据卷>:<容器内目录>
   ```
   **常用参数**：
   - `-d`：后台运行容器。
   - `-p`：端口映射。
   - `--name`：为容器命名。
   - `-v`：挂载数据卷

   **示例**：
   ```bash
   docker run -d -p 8080:80 --name mynginx nginx:latest -v /spark：/opt/spark
   ```

### 9. **停止容器**
   ```bash
   docker stop <容器ID或名称>
   ```

   **示例**：
   ```bash
   docker stop mynginx
   ```

### 10. **启动容器**
   ```bash
   docker start <容器ID或名称>
   ```

   **示例**：
   ```bash
   docker start mynginx
   ```

<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/9a812586d31f02dad1cb3bd0502e46eb.png" />
  <p style="margin-top: 2px;">docker run 、 docker stop 和 docker start</p>
</div>

### 11. **查看容器运行状态**
   ```bash
   docker ps
   ```
   **常用参数**：
   - `-a`：显示所有容器（包括未运行的）。
   - --format{}：格式化输出
    
   **示例**：
   ```bash
   docker ps -a
   ```

### 12. **删除容器**
   ```bash
   docker rm <容器ID或名称>
   ```
   **常用参数**：
   - `-f`：强制删除正在运行的容器。

   **示例**：
   ```bash
   docker rm mynginx
   ```
   
<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/5beb68a9a10ab4f9a3a07a8a57f6950e.png" />
  <p style="margin-top: 2px;">docker rm</p>
</div>

### 13. **查看运行容器日志**
   ```bash
   docker logs <容器ID或名称>
   ```
   **常用参数**：
   - `-f`：实时输出日志。
   - `--tail`：显示日志的最后N行。

   **示例**：
   ```bash
   docker logs -f mynginx
   ```

### 14. **进入容器内部**
   ```bash
   docker exec -it <容器ID或名称> /bin/bash
   ```
   **常用参数**：
   - `-it`：允许交互式终端进入容器。
   - `/bin/bash`：进入容器后使用的Shell。

   **示例**：
   ```bash
   docker exec -it mynginx /bin/bash
   ```