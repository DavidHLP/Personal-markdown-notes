# Redis工具类实现

- `RedisCacheVo`

```java
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Builder;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class RedisCacheVo<T> implements Serializable {
    private T data;
    private LocalDateTime cacheExpireTime;
} private LocalDateTime cacheExpireTime;
}
```

- `RedisCache`

```java
package com.redis.api.redis.utils;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.springframework.data.redis.core.BoundSetOperations;
import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.stereotype.Component;

import cn.hutool.core.lang.TypeReference;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * spring redis 工具类
 *
 * @author ruoyi
 **/
@SuppressWarnings(value = { "unchecked", "rawtypes" })
@Slf4j
@Component
@RequiredArgsConstructor
public class RedisCache {
    public final RedisTemplate redisTemplate;

    private static final long CACHE_NULL_TTL = 2L; // 缓存空值的过期时间,单位：分钟
    private static final ExecutorService CACHE_REBUILD_EXECUTOR = Executors.newFixedThreadPool(10);

    /**
     * 缓存基本的对象,Integer、String、实体类等
     *
     * @param key   缓存的键值
     * @param value 缓存的值
     */
    public <T> void setCacheObject(final String key, final T value) {
        redisTemplate.opsForValue().set(key, value);
    }

    /**
     * 缓存基本的对象,Integer、String、实体类等
     *
     * @param key      缓存的键值
     * @param value    缓存的值
     * @param timeout  时间
     * @param timeUnit 时间颗粒度
     */
    public <T> void setCacheObject(final String key, final T value, final long timeout, final TimeUnit timeUnit) {
        redisTemplate.opsForValue().set(key, value, timeout, timeUnit);
    }

    /**
     * 设置有效时间
     *
     * @param key     Redis键
     * @param timeout 超时时间
     * @return true=设置成功；false=设置失败
     */
    public boolean expire(final String key, final long timeout) {
        return expire(key, timeout, TimeUnit.SECONDS);
    }

    /**
     * 设置有效时间
     *
     * @param key     Redis键
     * @param timeout 超时时间
     * @param unit    时间单位
     * @return true=设置成功；false=设置失败
     */
    public boolean expire(final String key, final long timeout, final TimeUnit unit) {
        return redisTemplate.expire(key, timeout, unit);
    }

    /**
     * 获取有效时间
     *
     * @param key Redis键
     * @return 有效时间
     */
    public long getExpire(final String key) {
        return redisTemplate.getExpire(key);
    }

    /**
     * 判断 key是否存在
     *
     * @param key 键
     * @return true 存在 false不存在
     */
    public Boolean hasKey(String key) {
        return redisTemplate.hasKey(key);
    }

    /**
     * 获得缓存的基本对象。
     *
     * @param key 缓存键值
     * @return 缓存键值对应的数据
     */
    public <T> T getCacheObject(final String key) {
        ValueOperations<String, T> operation = redisTemplate.opsForValue();
        return operation.get(key);
    }

    /**
     * 删除单个对象
     *
     * @param key
     */
    public boolean deleteObject(final String key) {
        return redisTemplate.delete(key);
    }

    /**
     * 删除集合对象
     *
     * @param collection 多个对象
     * @return
     */
    public boolean deleteObject(final Collection collection) {
        return redisTemplate.delete(collection) > 0;
    }

    /**
     * 缓存List数据
     *
     * @param key      缓存的键值
     * @param dataList 待缓存的List数据
     * @return 缓存的对象
     */
    public <T> long setCacheList(final String key, final List<T> dataList) {
        Long count = redisTemplate.opsForList().rightPushAll(key, dataList);
        return count == null ? 0 : count;
    }

    /**
     * 获得缓存的list对象
     *
     * @param key 缓存的键值
     * @return 缓存键值对应的数据
     */
    public <T> List<T> getCacheList(final String key) {
        return redisTemplate.opsForList().range(key, 0, -1);
    }

    /**
     * 缓存Set
     *
     * @param key     缓存键值
     * @param dataSet 缓存的数据
     * @return 缓存数据的对象
     */
    public <T> BoundSetOperations<String, T> setCacheSet(final String key, final Set<T> dataSet) {
        BoundSetOperations<String, T> setOperation = redisTemplate.boundSetOps(key);
        Iterator<T> it = dataSet.iterator();
        while (it.hasNext()) {
            setOperation.add(it.next());
        }
        return setOperation;
    }

    /**
     * 获得缓存的set
     *
     * @param key
     * @return
     */
    public <T> Set<T> getCacheSet(final String key) {
        return redisTemplate.opsForSet().members(key);
    }

    /**
     * 设置缓存Map
     */
    public void setCacheMap(String key, Map<String, Object> data, final long timeout, final TimeUnit unit) {
        redisTemplate.opsForHash().putAll(key, data);
        if (timeout > 0) {
            redisTemplate.expire(key, timeout, unit);
        }
    }

    /**
     * 获取缓存Map
     */
    public Map<String, Object> getCacheMap(String key) {
        return redisTemplate.opsForHash().entries(key);
    }

    /**
     * 往Hash中存入数据
     *
     * @param key   Redis键
     * @param hKey  Hash键
     * @param value 值
     */
    public <T> void setCacheMapValue(final String key, final String hKey, final T value) {
        redisTemplate.opsForHash().put(key, hKey, value);
    }

    /**
     * 获取Hash中的数据
     *
     * @param key  Redis键
     * @param hKey Hash键
     * @return Hash中的对象
     */
    public <T> T getCacheMapValue(final String key, final String hKey) {
        HashOperations<String, String, T> opsForHash = redisTemplate.opsForHash();
        return opsForHash.get(key, hKey);
    }

    /**
     * 获取多个Hash中的数据
     *
     * @param key   Redis键
     * @param hKeys Hash键集合
     * @return Hash对象集合
     */
    public <T> List<T> getMultiCacheMapValue(final String key, final Collection<Object> hKeys) {
        return redisTemplate.opsForHash().multiGet(key, hKeys);
    }

    /**
     * 删除Hash中的某条数据
     *
     * @param key  Redis键
     * @param hKey Hash键
     * @return 是否成功
     */
    public boolean deleteCacheMapValue(final String key, final String hKey) {
        return redisTemplate.opsForHash().delete(key, hKey) > 0;
    }

    /**
     * 获得缓存的基本对象列表
     *
     * @param pattern 字符串前缀
     * @return 对象列表
     */
    public Collection<String> keys(final String pattern) {
        return redisTemplate.keys(pattern);
    }

    /**
     * 设置带逻辑过期的缓存
     *
     * @param key   缓存键
     * @param value 缓存值
     * @param time  过期时间
     * @param unit  时间单位
     */
    public <T> void setWithLogicalExpire(String key, T value, Long time, TimeUnit unit) {
        // 设置逻辑过期
        RedisCacheVo<T> redisCacheVo = RedisCacheVo.<T>builder()
                .data(value)
                .cacheExpireTime(LocalDateTime.now().plusSeconds(unit.toSeconds(time)))
                .build();
        // 写入Redis
        redisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(redisCacheVo));
    }

    /**
     * 生成分布式锁的值
     *
     * @param lockTimeout 锁超时时间
     * @param timeUnit    时间单位
     * @return 锁的值
     */
    private String generateLockValue(long lockTimeout, TimeUnit timeUnit) {
        return String.valueOf(System.currentTimeMillis() + timeUnit.toMillis(lockTimeout) + 1);
    }

    /**
     * 尝试获取分布式锁
     *
     * @param lockKey     锁的key
     * @param lockValue   锁的值
     * @param lockTimeout 锁超时时间
     * @param timeUnit    时间单位
     * @return 是否获取成功
     */
    private boolean tryAcquireLock(String lockKey, String lockValue, long lockTimeout, TimeUnit timeUnit) {
        try {
            return Boolean.TRUE.equals(redisTemplate.opsForValue()
                    .setIfAbsent(lockKey, lockValue, lockTimeout, timeUnit));
        } catch (Exception e) {
            log.error("获取分布式锁异常,lockKey: " + lockKey, e);
            return false;
        }
    }

    /**
     * 安全释放分布式锁
     *
     * @param lockKey   锁的key
     * @param lockValue 锁的预期值
     */
    private void releaseLockSafely(String lockKey, String lockValue) {
        try {
            String currentValue = (String) redisTemplate.opsForValue().get(lockKey);
            if (lockValue.equals(currentValue)) {
                redisTemplate.delete(lockKey);
            }
        } catch (Exception e) {
            log.error("释放分布式锁异常,lockKey: " + lockKey, e);
        }
    }

    /**
     * 缓存加载函数式接口
     *
     * @param <T> 返回数据类型
     */
    @FunctionalInterface
    public interface CacheLoader<T> {
        /**
         * 加载数据
         *
         * @return 数据
         */
        T load();
    }

    /**
     * 使用互斥锁解决缓存击穿问题
     *
     * @param <T>          返回数据类型
     * @param key          缓存键
     * @param lockKey      锁的键
     * @param lockTimeout  锁的超时时间(秒)
     * @param cacheTimeout 缓存过期时间(秒)
     * @param loader       缓存加载函数
     * @return 缓存数据
     */
    public <T> T getWithMutex(final String key, final String lockKey, final long lockTimeout, final long cacheTimeout,
            final TimeUnit timeUnit, final CacheLoader<T> loader) {
        // 1. 先查缓存
        T value = getCacheObject(key);
        if (value != null) {
            return value;
        }

        // 2. 缓存未命中,获取分布式锁
        final String lockValue = generateLockValue(lockTimeout, timeUnit);
        try {
            // 尝试获取锁
            if (Boolean.TRUE.equals(tryAcquireLock(lockKey, lockValue, lockTimeout, timeUnit))) {
                try {
                    // 3. 获取锁成功,再次检查缓存(双重检查)
                    value = getCacheObject(key);
                    if (value != null) {
                        return value;
                    }

                    try {
                        // 4. 从数据源加载数据
                        value = loader.load();
                        // 5. 设置缓存,空数据也缓存,防止缓存穿透
                        setCacheObject(key, value != null ? value : "",
                                value != null ? cacheTimeout : CACHE_NULL_TTL,
                                timeUnit);
                        return value;
                    } catch (Exception e) {
                        log.error("从数据源加载数据时发生异常,key: " + key, e);
                        throw e;
                    }
                } finally {
                    // 释放锁
                    releaseLockSafely(lockKey, lockValue);
                }
            } else {
                // 6. 获取锁失败,短暂休眠后重试
                log.warn("获取分布式锁失败,准备重试,lockKey: {}", lockKey);
                try {
                    Thread.sleep(100);
                    return getWithMutex(key, lockKey, lockTimeout, cacheTimeout, timeUnit, loader);
                } catch (InterruptedException e) {
                    log.error("重试获取缓存时线程被中断,key: " + key, e);
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("获取缓存时线程被中断", e);
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("获取缓存失败", e);
        }
    }

    /**
     *
     * @param <T>          返回数据类型
     * @param key          缓存键
     * @param lockKey      锁的键
     * @param lockTimeout  锁的超时时间
     * @param cacheTimeout 缓存过期时间
     * @param timeUnit     时间单位
     * @param loader       缓存加载函数
     * @return 缓存数据,如果缓存不存在返回null
     */
    public <T> T getWithLogicalExpire(final String key, final String lockKey,
            final long lockTimeout, final long cacheTimeout,
            final TimeUnit timeUnit, final CacheLoader<T> loader) {

        // 1. 查询缓存
        String json = (String) redisTemplate.opsForValue().get(key);
        if (StrUtil.isBlank(json)) {
            return null;
        }

        // 2. 反序列化缓存数据
        RedisCacheVo<T> cacheVo = null;
        try {
            cacheVo = JSONUtil.toBean(json, new TypeReference<RedisCacheVo<T>>() {
            }, false);
            if (cacheVo == null || cacheVo.getData() == null) {
                log.warn("缓存数据为空,key: {}", key);
                return null;
            }

            // 3. 检查缓存是否过期
            if (cacheVo.getCacheExpireTime().isAfter(LocalDateTime.now())) {

                return cacheVo.getData();
            }

        } catch (Exception e) {
            log.error("反序列化缓存数据异常,key: " + key + ", json: " + json, e);
            return null;
        }

        // 4. 缓存已过期,尝试获取分布式锁进行重建
        final T expiredData = cacheVo.getData();
        final String lockValue = generateLockValue(lockTimeout, timeUnit);

        // 5. 尝试获取分布式锁
        if (!tryAcquireLock(lockKey, lockValue, lockTimeout, timeUnit)) {
            return expiredData;
        }

        // 6. 获取锁成功,异步重建缓存
        asyncRebuildCache(key, lockKey, lockValue, cacheTimeout, timeUnit, loader);

        // 7. 返回过期的数据
        return expiredData;
    }

    /**
     * 异步重建缓存
     */
    private <T> void asyncRebuildCache(String key, String lockKey, String lockValue,
            long cacheTimeout, TimeUnit timeUnit, CacheLoader<T> loader) {

        CACHE_REBUILD_EXECUTOR.execute(() -> {
            try {

                // 1. 加载新数据
                T newData = loader.load();

                // 2. 更新缓存
                if (newData != null) {

                    setWithLogicalExpire(key, newData, cacheTimeout, timeUnit);
                } else {
                    log.warn("加载的数据为空,设置空值防止缓存穿透,key: {}", key);
                    setCacheObject(key, "", CACHE_NULL_TTL, TimeUnit.MINUTES);
                }

            } catch (Exception e) {
                log.error("缓存重建异常,key: " + key, e);
            } finally {
                // 3. 释放锁
                releaseLockSafely(lockKey, lockValue);
            }
        });
    }
}
```
