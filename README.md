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

### Локально без сервера (открытие файла напрямую)

При открытии `epic-estimator.html` напрямую в браузере (без nginx)
подстановка не выполняется, плейсхолдеры игнорируются и используются
значения по умолчанию из `CONFIG` в самом файле.
