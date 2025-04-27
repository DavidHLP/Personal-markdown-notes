## 本地目录挂载

> 这种挂载存在一些匿名卷

本地目录挂载（Bind Mount）是 Docker 中的一种机制，它允许你将宿主机的文件或目录挂载到容器内的指定路径。这使得容器可以直接访问和修改宿主机上的文件或目录，通常用于数据共享、持久化存储或使用宿主机上的配置文件。

### 本地目录挂载的特点：
- **双向同步**：容器和宿主机之间的数据是双向同步的，容器内对挂载目录的修改会直接反映在宿主机上，反之亦然。
- **持久化**：与 Docker 卷类似，挂载的目录可以实现数据持久化，但与 Docker 卷不同，绑定挂载完全由宿主机的文件系统管理。
- **灵活性**：允许你选择宿主机上的任何路径进行挂载，适合需要直接操作宿主机文件的场景。

### 使用 `docker run` 挂载本地目录

> 挂载的时候使用的是绝对路径

可以在创建容器时使用 `--mount` 或 `-v`（`--volume`）选项将宿主机的目录或文件挂载到容器内。

#### 1. **使用 `--mount`**

这是推荐的现代方式，语法清晰，适合复杂的挂载场景。

```bash
docker run -d --mount type=bind,source=<宿主机路径>,target=<容器路径> <镜像名>
```

- `type=bind`：表示使用绑定挂载。
- `source=<宿主机路径>`：宿主机上的目录或文件路径。
- `target=<容器路径>`：容器内的挂载点路径。

**示例**：
将宿主机的 `/home/user/data` 目录挂载到容器的 `/app/data` 目录：
```bash
docker run -d --mount type=bind,source=/home/user/data,target=/app/data nginx
```

#### 2. **使用 `-v`**

这是早期的方式，仍然广泛使用，但在处理更复杂的挂载场景时可读性不如 `--mount` 高。

```bash
docker run -d -v <宿主机路径>:<容器路径> <镜像名>
```

**示例**：
将宿主机的 `/home/user/data` 目录挂载到容器的 `/app/data` 目录：
```bash
docker run -d -v /home/user/data:/app/data nginx
```

### 挂载本地目录的常见参数

1. **只读挂载**：你可以使用 `readonly` 参数将宿主机的目录以只读模式挂载到容器，防止容器对目录进行写操作。

   **示例**：
   ```bash
   docker run -d --mount type=bind,source=/home/user/config,target=/app/config,readonly nginx
   ```

2. **挂载文件而非目录**：你也可以挂载单个文件，而不仅仅是目录。

   **示例**：
   ```bash
   docker run -d --mount type=bind,source=/home/user/config/app.conf,target=/etc/app.conf nginx
   ```

3. **临时文件系统（`tmpfs`）挂载**：除了绑定宿主机目录，你还可以使用 `tmpfs` 将临时文件系统挂载到容器内，所有数据都会保存在内存中。

   **示例**：
   ```bash
   docker run -d --mount type=tmpfs,target=/app/tmp nginx
   ```

### 查看挂载的卷和目录

你可以使用 `docker inspect` 查看容器的详细信息，包括哪些目录被挂载：

```bash
docker inspect <容器ID或容器名>
```

这将返回 JSON 格式的输出，其中包含卷和挂载信息。

## 匿名卷

在 Docker 中，绑定挂载（Bind Mount）有时会涉及匿名卷的概念，尤其是当你使用 `docker run` 命令时，默认情况下 Docker 会为某些情况创建匿名卷，这些匿名卷可能会引起混淆。让我们来解释一下匿名卷的情况以及如何避免它们。

### 匿名卷的产生

匿名卷是在容器启动时，由 Docker 自动创建的未命名的卷。它们通常用于保存容器的持久化数据，但因为没有明确的名称，所以这些卷不易管理和跟踪。

#### 什么时候会创建匿名卷？
匿名卷通常在以下情况下自动创建：

1. **没有明确指定挂载目标**：当 Docker 容器的某个路径（例如 `/var/lib/mysql`）需要持久化存储时，如果没有为该路径明确指定挂载卷，Docker 会自动创建一个匿名卷。
   
   **示例**：
   ```bash
   docker run -d mysql:latest
   ```

   在这个例子中，MySQL 容器会在 `/var/lib/mysql` 保存数据库数据。因为没有明确为这个路径指定卷，Docker 会自动创建一个匿名卷并将其挂载到容器的 `/var/lib/mysql`。

2. **使用 `VOLUME` 指令的镜像**：如果镜像的 `Dockerfile` 中包含了 `VOLUME` 指令，并且你没有明确指定挂载路径，Docker 也会为这个路径创建匿名卷。

   **示例**：
   在使用 `VOLUME /data` 指令构建的镜像时，如果你不手动指定挂载卷，Docker 将为 `/data` 创建一个匿名卷。

### 如何避免匿名卷

为了避免 Docker 自动创建匿名卷，你可以明确指定数据卷或绑定挂载。这使你能更好地管理卷，避免不必要的匿名卷占用磁盘空间。

#### 1. **使用命名卷**
命名卷可以通过 Docker 命令明确指定，并且可以轻松管理和追踪。

**示例**：
```bash
docker run -d -v my_named_volume:/var/lib/mysql mysql:latest
```

在这个例子中，`my_named_volume` 是我们手动创建的卷，它将挂载到容器的 `/var/lib/mysql` 目录。这样可以避免 Docker 创建匿名卷。

#### 2. **使用绑定挂载（Bind Mount）**
通过绑定宿主机上的目录到容器中的路径，确保你完全控制数据的存储位置。

**示例**：
```bash
docker run -d --mount type=bind,source=/home/user/mysql-data,target=/var/lib/mysql mysql:latest
```

在这个例子中，宿主机上的 `/home/user/mysql-data` 目录被挂载到容器的 `/var/lib/mysql`，确保了数据直接存储在宿主机指定的目录中，而不会创建匿名卷。

### 如何管理匿名卷

如果系统中已经产生了匿名卷，你可以通过以下步骤来查看和清理它们：

#### 1. **查看匿名卷**
使用 `docker volume ls` 可以列出所有卷，包括匿名卷。匿名卷通常没有名称，Docker 会生成一个随机的 ID 作为名称。

```bash
docker volume ls
```

输出示例：
```
DRIVER    VOLUME NAME
local     my_named_volume
local     1d9ae6879ec2d4d39172a8bb8a0a2b16f291d6eae1a2fdce93613fd74c446f9f  # 匿名卷
```

#### 2. **删除匿名卷**
你可以通过 `docker volume prune` 删除所有未使用的卷，包括匿名卷：

```bash
docker volume prune
```

Docker 会提示你确认删除所有未使用的卷，输入 `y` 以继续。

如果你想手动删除某个特定的匿名卷，可以使用 `docker volume rm <卷ID>` 命令删除它：

```bash
docker volume rm 1d9ae6879ec2d4d39172a8bb8a0a2b16f291d6eae1a2fdce93613fd74c446f9f
```