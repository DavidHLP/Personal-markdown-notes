## 数据卷

> 数据卷（Volume）是一个虚拟目录，是容器内目录与宿主机目录之间映射的桥梁，这种映射是双向的

数据卷（Volume）是 Docker 中一种持久化数据的机制，允许你将数据从容器内保存到宿主机的指定位置。通过数据卷，容器可以方便地共享、存储和管理数据。它主要解决了容器中的数据不会随着容器删除而丢失的问题。

### 数据卷的特点：
1. **持久化存储**：数据卷可以将容器内的数据存储到宿主机的文件系统中，确保容器删除后数据依然存在。
2. **数据共享**：多个容器可以共享同一个数据卷，实现跨容器的数据访问和同步。
3. **独立于容器生命周期**：数据卷的生命周期独立于容器，即使容器删除，数据卷上的数据仍然保留。
4. **性能优化**：数据卷可以避免数据复制带来的性能开销，直接与宿主机文件系统交互，速度更快。
5. **备份和迁移方便**：可以轻松将数据卷中的数据进行备份或迁移到其他主机。

<div align="center">
  <img src="https://davidhlp.asia/d/HLP/Blog/docker/accb058285f227f6608d1fe1e8239b63.png" />
</div>

> 数据卷只能在创建容器（`docker run`）的时候挂载，以及创建的容器无法再挂载数据卷

### 数据卷操作常见命令

#### 1. **创建数据卷**

```bash
docker volume create <卷名>
```

**示例**：
```bash
docker volume create my_volume
```

这个命令会创建一个名为 `my_volume` 的数据卷。如果不提供卷名，Docker 会自动生成一个随机名称。

- **常用参数**：
  - 没有额外的参数，使用默认设置创建卷。如果需要自定义驱动或其他选项，可以通过 `--driver` 和 `--opt` 指定，但这是高级选项，通常不需要。

```bash
docker volume create --driver local --opt type=tmpfs --opt device=tmpfs my_tmpfs_volume
```

- `--driver`：指定卷的驱动程序（如 `local`）。
- `--opt`：提供额外的选项配置卷的类型和设备。
  - 常见参数：
    - **`type`**：指定文件系统类型，常见值包括 `tmpfs`（将数据存储在内存中，不持久化）、`none`（无文件系统类型，用于绑定宿主机目录）。
    - **`device`**：指定宿主机上的设备或路径，或在 `tmpfs` 的情况下，指定 `tmpfs` 本身。
    - **`o`**：挂载选项，用于设置卷的额外参数。常见值有：
      - **`size`**：限制 `tmpfs` 卷的最大内存使用大小（例如 `size=100m` 表示 100 MB）。
      - **`bind`**：用于绑定宿主机目录到容器。
      - **`ro`**：只读挂载，防止容器对数据卷进行写入。

#### 2. **查看所有数据卷**

```bash
docker volume ls
```

**示例**：
```bash
docker volume ls
```

- **常用参数**：
  - `-q`：只显示卷的名称，而不是完整的列表信息。
  
  **示例**：
  ```bash
  docker volume ls -q
  ```

#### 3. **删除指定数据卷**

```bash
docker volume rm <卷名>
```

**示例**：
```bash
docker volume rm my_volume
```

- **常用参数**：
  - `-f`：强制删除卷，即使卷被某个容器使用时也能删除。

  **示例**：
  ```bash
  docker volume rm -f my_volume
  ```

#### 4. **查看某个数据卷的详情**

```bash
docker volume inspect <卷名>
```

**示例**：
```bash
docker volume inspect my_volume
```

这会返回指定数据卷的详细信息（JSON 格式），包括存储路径、驱动程序、挂载点等。

#### 5. **清除未使用的数据卷**

```bash
docker volume prune
```

**示例**：
```bash
docker volume prune
```

此命令会清理所有未被使用的“悬空”数据卷。它会要求你确认清理，输入 `y` 后执行。

- **常用参数**：
  - `-f`：跳过确认步骤，直接删除未使用的卷。

  **示例**：
  ```bash
  docker volume prune -f
  ```
#### 6. **查看容器元数据**

```bash
docker inspect <容器名或容器ID>
```

`docker inspect` 命令用于查看容器的详细元数据信息，包括其配置、状态、网络设置、挂载卷等信息，输出为 JSON 格式。

**示例**：
```bash
docker inspect my_container
```

这将返回容器 `my_container` 的所有元数据。

- **常用参数**：
  - `--format`：自定义输出格式，用于筛选所需的信息。
  
  **示例**：
  仅查看容器的 IP 地址：
  ```bash
  docker inspect --format='{{.NetworkSettings.IPAddress}}' my_container
  ```

  查看容器的状态信息：
  ```bash
  docker inspect --format='{{.State.Status}}' my_container
  ```

>- 在执行docker run命令时，使用 -V 数据卷：容器 内目录可以完成数据卷挂载
>- 当创建容器时，如果挂载了数据卷且数据卷不存在，会自动创建数据卷