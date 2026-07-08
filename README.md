# eestimator

## Конфигурация через переменные окружения

Приложение — статическая страница (`epic-estimator.html`), отдаваемая nginx. Часть
настроек (`API_KEY`, `MODEL`, `MAX_TOKENS`) задаётся переменными окружения пода:
при старте контейнера скрипт `config/docker-entrypoint.d/render-config.sh`
подставляет их значения в HTML вместо плейсхолдеров `__API_KEY__`, `__MODEL__`,
`__MAX_TOKENS__` (см. `epic-estimator.html`, блок `CONFIG`).

| Переменная    | Обязательна | Назначение                                   |
|---------------|-------------|-----------------------------------------------|
| `API_KEY`     | да          | Bearer-токен для запросов к `API_URL`         |
| `MODEL`       | нет         | Имя модели (по умолчанию `Instruct`)          |
| `MAX_TOKENS`  | нет         | Лимит токенов ответа (по умолчанию `10000`)   |

Важно: имя переменной — ровно `API_KEY` (без подчёркиваний-обёрток `__…__`,
это только синтаксис плейсхолдера внутри HTML-шаблона).

### На сервере (Kubernetes / Helm)

Переменные пробрасываются в под через `envFrom.secretRef` на Secret, имя
которого задано в `helm/eestimator/values.yaml` (`application.apiTokenSecret`,
по умолчанию `eestimator-api-token`). Сам Secret в чарте не создаётся —
его нужно создать в кластере заранее, с ключами, совпадающими по имени с
переменными окружения:

```bash
kubectl create secret generic eestimator-api-token \
  --from-literal=API_KEY='<реальный токен>' \
  --from-literal=MODEL='Instruct' \
  --from-literal=MAX_TOKENS='10000' \
  --namespace <namespace>
```

После создания/обновления секрета нужно перезапустить под (`kubectl rollout
restart deployment/<release-name>`), так как значения подставляются в HTML
только при старте контейнера, а не читаются на лету.

### Локальный запуск (Docker)

```bash
docker run -p 8080:8080 \
  -e API_KEY='<реальный токен>' \
  -e MODEL='Instruct' \
  -e MAX_TOKENS='10000' \
  <image>
```

### Проверка в режиме, приближённом к продакшену (read-only rootfs)

В k8s под запускается с `readOnlyRootFilesystem: true` и непривилегированным
пользователем, а `emptyDir`-тома получают права на запись через `fsGroup:
101`, заданный в `spec.template.spec.securityContext` (не в
`containers[].securityContext` — там такого поля нет, Kubernetes его
проигнорирует). Обычный `docker run` эту логику не воспроизводит: `fsGroup`
— концепция Kubernetes, Docker про неё не знает, поэтому анонимные
`--tmpfs`-тома по умолчанию непригодны для записи от имени непривилегированного
пользователя. Чтобы протестировать локально то же самое, права нужно
проставить явно опциями tmpfs-mount'а:

```bash
docker run -d --name eestimator-test \
  -p 8080:8080 \
  -e API_KEY='test-secret-123' \
  -e MODEL='Instruct' \
  -e MAX_TOKENS='5000' \
  --user 101:101 \
  --read-only \
  --tmpfs /tmp:uid=101,gid=101,mode=0770 \
  --tmpfs /var/cache/nginx:uid=101,gid=101,mode=0770 \
  --tmpfs /usr/share/nginx/html:uid=101,gid=101,mode=0770 \
  <image>
```

Если хотя бы один из томов смонтирован без `uid=101,gid=101,mode=...`,
запись в него от имени непривилегированного пользователя завершится
`Permission denied` — именно так проявляется отсутствие/неверное
расположение `fsGroup` в чарте.

### Локально без сервера (открытие файла напрямую)

При открытии `epic-estimator.html` напрямую в браузере (без nginx)
подстановка не выполняется, плейсхолдеры игнорируются и используются
значения по умолчанию из `CONFIG` в самом файле.
